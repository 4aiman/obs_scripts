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

-- padding filter name
padding_filter_name = "pad to frame"
-- common path to all your frames
basic_fmames_path = "add yours"

sizes_3_by_2 = {{width = 1440, height = 960}}
sizes_3_by_4 = {{width = 1280, height = 960}}

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
        local sizing_mode = false                    

		if master_source~= nil and slave_source~= nil then
            local master_filters = obs.obs_source_enum_filters(master_source)
            -- obs_source_get_filter_by_name
            for idx, filter in pairs(master_filters) do 
                local filter_name = obs.obs_source_get_name(filter)
                if filter_name == padding_filter_name then 
                    local filter_props = obs.obs_source_get_settings(filter)
                    local master_height = obs.obs_source_get_height(master_source)
                    local master_width = obs.obs_source_get_width(master_source)
                    local padding_left = obs.obs_data_get_int(filter_props, 'left')
                    local padding_top = obs.obs_data_get_int(filter_props, 'top')
                    local actual_height = master_height + padding_top
                    local actual_width = master_width + padding_left

                    if sizing_mode ~= true then
                        for id, size in ipairs (sizes_3_by_2) do
                            if actual_width == size.width and actual_height == size.height then
                                --print("it's 3:2 ratio!")
                                sizing_mode = 'frame_3x2'
                                break
                            end
                        end
                    end

                    if sizing_mode ~= true then
                        for id, size in ipairs (sizes_3_by_4) do
                            if actual_width == size.width and actual_height == size.height then
                                --print("it's 4:3 ratio!")
                                sizing_mode = 'frame_4x3'
                                break
                            end
                        end
                    end
                end
            end
        
            if sizing_mode ~= false then
                local slave_props = obs.obs_source_get_settings(slave_source)
                --print(obs.obs_data_get_json(slave_props))
                local image = obs.obs_data_get_string(slave_props, 'file')            
                local month = tonumber(os.date('%m'))
                local season = 'summer'
                if month >2 and month < 6  then season = 'spring' end
                if month >5 and month < 9  then season = 'summer' end
                if month >8 and month < 12 then season = 'autumn' end
                if month >11 or month < 3  then season = 'winter' end

                local frame_path = basic_fmames_path .. sizing_mode .. '_' .. season .. ".png"
                
                if image ~= frame_path then
                    obs.obs_data_set_string(slave_props, 'file', frame_path)
                    obs.obs_source_update(slave_source, slave_props)
                end
            end
		
			obs.obs_source_release(master_source)
			obs.obs_source_release(slave_source)
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
	local master = obs.obs_properties_add_list(props, "master_source", "Game source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	-- add the source that will sync up with the main one
	local slave = obs.obs_properties_add_list(props, "slave_source", "Frame source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	-- get all the sources
	local sources = obs.obs_enum_sources()	
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)			
            --print(source_id)
			-- if the source is not a group, then ad it to both master and slave lists
			if source_id ~= "group"
			then
				local name = obs.obs_source_get_name(source)
				if source_id == "game_capture" then
				   obs.obs_property_list_add_string(master, name, name)
				end
				if source_id == "image_source" then
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
	return "This script allows one to automatically change 'frames' depending on a game capture source's size.\n\nThe idea is to have several overlays for different aspect ratios of the game capture source and auto-select them dependinf on that.\nJust pick some overlays below for every aspect you'd like to have, and enjoy automation.\n\nMade by 4aiman"
end

-- A function named script_update will be called when settings are changed
function script_update(settings)	
	total_seconds = obs.obs_data_get_int(settings, "sync_delay")	
	master_source_name = obs.obs_data_get_string(settings, "master_source")
	slave_source_name = obs.obs_data_get_string(settings, "slave_source")
	print("Frame Synchronizer script upadted. Delay has been set to " .. total_seconds .. '; Master source is now "' .. master_source_name .. '"; Slave source is now "' .. slave_source_name ..'".')

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
	print("Frame Synchronizer script loaded")
	activate(true)
end


