-- "load" OBS bindings
obs           = obslua

-- total seconds elapsed since the script has started
total_seconds = 0
-- seconds elapsed in this cycle
cur_seconds   = 0
-- names of the sources that are being synced up
master_source_name = ""
slave_source_name = ""
-- seconds between sync attempts
sync_delay = 5
activated     = false

-- a hotkey to force synchronisation of a given pair
hotkey_id     = obs.OBS_INVALID_HOTKEY_ID


function string.split(inputstr, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
	end
	return t
end

function timer_callback()
	cur_seconds = cur_seconds - 1
	
	if cur_seconds < 0 then		
		--print("Source Synchronizer script cycle ended. Delay is " .. total_seconds .. '; Master source is "' .. master_source_name .. '"; Slave source is "' .. slave_source_name ..'".')

		-- get both master and slave sources by names set up in the script dialog settings
		local master_source = obs.obs_get_source_by_name(master_source_name)
		local slave_source = obs.obs_get_source_by_name(slave_source_name)

		-- if both were found, we can proceed
		if master_source~= nil and slave_source~= nil then
			-- obs.obs_get_source_properties always returns nill 
			-- and obs.obs_source_get_settings is unusable since property_next expects a fucking pointer, not the object itself.
			-- Solution? According to the github, using FFI for an already embedded shit. Why, oh, why, mofos?!!
			-- Oh, I know why! Because OBS devs don't give a fuck since 2020 :/

			-- get settings of a master source
			local master_props = obs.obs_source_get_settings(master_source)

			-- get the "window" property which will tell what window the master source is captturing
			local master_window = obs.obs_data_get_string(master_props, 'window')
			-- yes, it uses windows in "game" capture mode (fuck clarity, I guess?)

			-- get settings of a slave source
			local slave_props = obs.obs_source_get_settings(slave_source)

			-- now that we have both, create a NEW temporary data object (again, no other way from lua, except ffi since 2020)
			local new_slave_props = obs.obs_data_create()
			-- copy/paste the window property from the master to the slave
			obs.obs_data_set_string(slave_props, 'window', master_window)
			-- set the new temporary data object as properties for the slave source
			obs.obs_data_set_obj(new_slave_props, "sourceSettings", slave_props)

			-- the copied source won't update unless...
			obs.obs_source_update(slave_source, slave_props)
			--obs.obs_frontend_open_source_properties(slave_source_name)

			-- release master and slave objects
			obs.obs_source_release(master_source)
			obs.obs_source_release(slave_source)

			-- release the new temporary data object
			obs.obs_data_release(new_slave_props)
		end

		-- reset loop timer to the default value, so the cycle can continue
	 	cur_seconds = sync_delay
	end

	--set_time_text()
end

function activate(activating)
	if activated == activating then
	   return
	end

	activated = activating

	if activating then
	   cur_seconds = total_seconds
	 	obs.timer_add(timer_callback, 1000)
	else
	 	obs.timer_remove(timer_callback)
	end
end


----------------------------------------------------------

-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
	-- create properties dialogue
	local props = obs.obs_properties_create()
	-- add sync delay settings
	obs.obs_properties_add_int(props, "sync_delay", "Sync cycle (seconds)", 1, 3600, 1)
	-- add main source combobox
	local master = obs.obs_properties_add_list(props, "master_source", "Master source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	-- add the source that will sync up with the main one
	local slave = obs.obs_properties_add_list(props, "slave_source", "Slave source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	-- get all the sources
	local sources = obs.obs_enum_sources()	
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)			
			-- if the source is not a group, then ad it to both master and slave lists
			if source_id ~= "group"
			then
				local name = obs.obs_source_get_name(source)
				if source_id == "game_capture" then
				   obs.obs_property_list_add_string(master, name, name)
				end
				if source_id == "wasapi_process_output_capture" then
				   obs.obs_property_list_add_string(slave, name, name)
				end
			end
		end
	end
	-- they say it's important to release sources
	obs.source_list_release(sources)
	
	return props
end

-- A function named script_description returns the description shown to
-- the user
function script_description()
	return "This script allows one to sync 2 sources'... well, sources.\n\nThe idea is to be able to change *one* source and have the rest of them sync up with that.\n\nThe easiest example to follow: one has a game capture source and an application audio output capture source. With this it's possible to change only the game source and the audio one will reflect the changes automatically after a set time interval.\n\nThere's no explicit limit on what types of sources to use, though. If only because I'm to lazy to check all the types of sources available on different platforms.\n\nMade by 4aiman"
end

-- A function named script_update will be called when settings are changed
function script_update(settings)	
	total_seconds = obs.obs_data_get_int(settings, "sync_delay")	
	master_source_name = obs.obs_data_get_string(settings, "master_source")
	slave_source_name = obs.obs_data_get_string(settings, "slave_source")
	print("Source Synchronizer script upadted. Delay has been set to " .. total_seconds .. '; Master source is now "' .. master_source_name .. '"; Slave source is now "' .. slave_source_name ..'".')

end

-- A function named script_defaults will be called to set the default settings
function script_defaults(settings)
	obs.obs_data_set_default_int(settings, "sync_delay", sync_delay)
end

-- A function named script_save will be called when the script is saved
--
-- NOTE: This function is usually used for saving extra data (such as in this
-- case, a hotkey's save data).  Settings set via the properties are saved
-- automatically.
function script_save(settings)
	local force_sources_sync_hotkey = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, "force_sources_sync_hotkey", force_sources_sync_hotkey)
	obs.obs_data_array_release(force_sources_sync_hotkey)
end

-- a function named script_load will be called on startup
function script_load(settings)
	print("Source Synchronizer script loaded")
	activate(true)
end


