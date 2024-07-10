-- "load" OBS bindings
obs           = obslua
stream_counter_source_name   = ""
hotkey_id	    = obs.OBS_INVALID_HOTKEY_ID 
hotkey_id_1     = obs.OBS_INVALID_HOTKEY_ID -- add stream
hotkey_id_2     = obs.OBS_INVALID_HOTKEY_ID -- dec stream
hotkey_id_3     = obs.OBS_INVALID_HOTKEY_ID -- reset stream
force_apply     = false

-- fix settings
require("obs_source_set_settings_fix")

-- total seconds elapsed since the script has started
total_seconds = 0
-- seconds elapsed in this cycle
cur_seconds   = 0
-- names of the sources that are being synced up
master_source_name = ""
padding_filter_name = "pad to frame"
slave_source_name = ""
-- actual sources
master_combobox = nil
slave_combobox = nil
master_filers_combobox = nil
global_props = nil

-- seconds between sync attempts
sync_delay = 5
activated     = false

-- common path to all your frames
base_fmames_path = ""

sizes_3_by_2 = {{width = 1440, height = 960}}
sizes_3_by_4 = {{width = 1280, height = 960}}
sizes_16_by_9 = {{width = 1920, height = 1080}}

-- a hotkey to force synchronisation of a given pair
hotkey_id     = obs.OBS_INVALID_HOTKEY_ID

css_values = [[
#titleicon {display:none; position:relative; top:-4px!important;}
body {
	background-color: rgba(0, 0, 0, 0); 
	b_ackground-image: var(--clear_bg);
}

.homealert {display: none}
#c_hannel_title_text {top:-12px!important}
#c_hannel_title_shadow {top:-12px!important}
.o_ga_h1:after {content: " & 4aiboy #13"}
.o_ga_h1:after {content: " - Тихой сапой #18 "}
.og_a_h1:after {content: " - Джекбокс по-русски: 1, 3, 4, 5 (jackbox.fun)"}
.oga_jackbox {display: none}

.oga_h1_ { margin-left:70px; font-size:54px;}
#title_opacity {opacity:1}
#donation-goal  {display:none;}

.oga__h {display:none;}
.oga__h1 {display:none;}
.oga_h2 {display:none;}
.oga_jackbox {display:none;}
.widget-stat-runner__item{color:red!important}
#jo_y {display:none}
#ya-train {display:none}

#root, .span {
	text-shadow: #424200 -1px -1px 0px, #424200 1px 1px 0px, #424200 -1px 1px 0px, #424200 1px -1px 0px, #424200 -1px 0px 0px, #424200 1px 0px 0px, #424200 0px -1px 0px, #424200 0px 1px 0px!important ;
}
]]


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


local last_sizing_mode = nil

function timer_callback()
	cur_seconds = cur_seconds - 1
	
	if cur_seconds < 0 then		
		--print("Source Synchronizer script cycle ended. Delay is " .. total_seconds .. '; Master source is "' .. master_source_name .. '"; Slave source is "' .. slave_source_name ..'".')

		-- get both master and slave sources by names set up in the script dialog settings
		local master_source = obs.obs_get_source_by_name(master_source_name)
		local slave_source = obs.obs_get_source_by_name(slave_source_name)
		local browser_source = obs.obs_get_source_by_name("Браузер 2")	
        local sizing_mode = false                    


		if master_source~= nil and slave_source~= nil then
            local master_filters = obs.obs_source_enum_filters(master_source)

			local master_height = obs.obs_source_get_height(master_source)
			local master_width = obs.obs_source_get_width(master_source)
			local padding_left = 0
			local padding_top = 0
			local actual_height = master_height
			local actual_width = master_width

			-- obs_source_get_filter_by_name
            for idx, filter in pairs(master_filters) do 
                local filter_name = obs.obs_source_get_name(filter)
				if filter_name == padding_filter_name then 					
					-- check if the padding filter is enabled at all
					if obs.obs_source_enabled(filter) == true then
						-- if it is - modify actual size with regard to set padding
						local filter_props = obs.obs_source_get_settings(filter)
						padding_left = obs.obs_data_get_int(filter_props, 'left')
						padding_top = obs.obs_data_get_int(filter_props, 'top')
						actual_height = master_height + padding_top
						actual_width = master_width + padding_left
					else
						break
					end
				end
			end
			
			--print(master_width .. "x"..master_height ..'; '.. (padding_left or 0) .. ':' .. (padding_top or 0) .. '; ' .. actual_width .. 'x' .. actual_height)

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

			if last_sizing_mode ~= sizing_mode or force_apply then
				force_apply = false
				local counter_source = obs.obs_get_source_by_name(stream_counter_source_name)
				local __STREAM_NUMBER__ = ""
				if counter_source ~= nil then
					local counter_props = obs.obs_source_get_settings(counter_source)
                	__STREAM_NUMBER__ = tonumber(obs.obs_data_get_string(counter_props, 'text'))					
					obs.obs_source_release(counter_source)
				end
				
				local css = ""
				if sizing_mode == 'frame_4x3' then				
					print('updating chat size to 4x3/16x9')
					local _ = { 
						css_values,
						'\n',
						'#chat {margin-left:-50px; width: 500px; word-break: break-word;} /* for 4:3 and 16:9 agames*/',
						'\n',
						'.oga_h1:after {content: " #',
						__STREAM_NUMBER__,
						'"}'
					}					
					css = table.concat(_)
				else
					print('updating chat size to 3x2')
					local _ = { 
						css_values,
						'\n',
						'#chat {margin-left:50px; width: 400px;word-break: break-word;} /* for 3:2 GBA games*/',
						'\n',
						'.oga_h1:after {content: " #',
						__STREAM_NUMBER__,
						'"}'
					}					
					css = table.concat(_)
				end			

                local props = obs.obs_source_get_settings(browser_source)
                obs.obs_data_set_string(props, 'css', css)
                obs.obs_source_update(browser_source, props)				
				last_sizing_mode = sizing_mode
			end
				
	

			if sizing_mode ~= true then
				for id, size in ipairs (sizes_16_by_9) do
					if actual_width == size.width and actual_height == size.height then
						--print("it's 16:9 ratio!")
						-- obs.obs_source_enabled doesn't want the second param, despite what's said in the docs
						-- obs.obs_source_active is readonly as per documentation, but only returns false
						-- obs.obs_source_set_hidden does nothing
						-- obs.obs_source_dec_showing does nothing
						-- obs.obs_source_dec_active does nothing
						-- obs.obs_scene_from_source doesn't produce anything, making it impossible to work with any scene items despite being used is some people's code
						obs.obs_source_set_enabled(slave_source, false)
						break
					end
				end
			end

        
            if sizing_mode ~= false then
                local slave_props = obs.obs_source_get_settings(slave_source)
                --print(obs.obs_data_get_json(slave_props))
                local image = obs.obs_data_get_string(slave_props, 'file')            
                local month = tonumber(os.date('%m'))
                local date = tonumber(os.date('%d'))
                local season = 'summer'
                if month >2 and month < 6  then season = 'spring' end
                if month >5 and month < 9  then season = 'summer' end
                if month >8 and month < 12 then season = 'autumn' end
                if month >11 or month < 3  then season = 'winter' end
				if month == 1 and date < 9 then season = 'winter_snow' end

                local frame_path = base_fmames_path .. sizing_mode .. '_' .. season .. ".png"
                
                if image ~= frame_path then
                    obs.obs_data_set_string(slave_props, 'file', frame_path)
                    obs.obs_source_update(slave_source, slave_props)
                end
				obs.obs_source_set_enabled(slave_source, true)
            end
		
			obs.obs_source_release(master_source)
			obs.obs_source_release(slave_source)
		end
		if browser_source~= nil then
			obs.obs_source_release(browser_source)
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
	global_props = obs.obs_properties_create()
	-- add sync delay settings
	obs.obs_properties_add_int(global_props, "sync_delay", "Sync cycle (seconds)", 1, 3600, 1)
	-- add main source global_props
	master_combobox = obs.obs_properties_add_list(global_props, "master_source", "Game source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	-- add master filters list; a more convenient way to select the padding filter
	master_filers_combobox = obs.obs_properties_add_list(global_props, "filter_source", "Pading filter", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING )	
	-- add the source that will sync up with the main one
	slave_combobox = obs.obs_properties_add_list(global_props, "slave_source", "Frame source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	frame_path_edit = obs.obs_properties_add_path(global_props, "frame_path_edit", "Frame Folder", obs.OBS_PATH_DIRECTORY, nil ,nil)

	-- stream counter
	local p = obs.obs_properties_add_list(global_props, "source", "Stream Counter Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	--


	-- get all the sources
	local sources = obs.obs_enum_sources()	
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)			
			-- if the source is not a group, then ad it to both master and slave lists
			if source_id ~= "group" then
				local name = obs.obs_source_get_name(source)
				if source_id == "game_capture" then
				   obs.obs_property_list_add_string(master_combobox, name, name)
				end
				if source_id == "image_source" then
				   obs.obs_property_list_add_string(slave_combobox, name, name)
				end
			end
			-- stream counter
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
			--
		end
	end


	if master_source_name ~= '' then
		local master_source = obs.obs_get_source_by_name(master_source_name)	
		if master_source~= nil and master_filers_combobox ~= nil then
			local master_filters = obs.obs_source_enum_filters(master_source)		
			for idx, filter in pairs(master_filters) do 
				local filter_name = obs.obs_source_get_name(filter)
				obs.obs_property_list_add_string(master_filers_combobox, filter_name, filter_name)
			end
			obs.obs_source_release(master_source)
		end		
	end

	-- stream counter
	obs.obs_properties_add_button(global_props, "reset_stream_counter_button", "Reset Stream Counter", reset_counter)
	obs.obs_properties_add_button(global_props, "add_stream_counter_button", "Increase Stream Counter", set_text1)
	obs.obs_properties_add_button(global_props, "dec_stream_counter_button", "Decrease Stream Counter", set_text2)
	--

	-- they say it's important to release sources
	obs.source_list_release(sources)
	
	return global_props
end

-- A function named script_description returns the description shown to
-- the user
function script_description()
	return "This script allows one to automatically change 'frames' depending on a game capture source's size.\n\nThe idea is to have several overlays for different aspect ratios of the game capture source and auto-select them dependinf on that.\nJust pick some overlays below for every aspect you'd like to have, and enjoy automation.\n\nOnce the Game source is set *refresh* the script in order to be able to select the crop filter.\n\nIt also manages stream number in browser's css\n\nMade by 4aiman"
end

-- A function named script_update will be called when settings are changed
function script_update(settings)		
	-- script counter
	stream_counter_source_name = obs.obs_data_get_string(settings, "source")
	--
	total_seconds = obs.obs_data_get_int(settings, "sync_delay")	
	master_source_name = obs.obs_data_get_string(settings, "master_source")
	padding_filter_name = obs.obs_data_get_string(settings, "filter_source")
	slave_source_name = obs.obs_data_get_string(settings, "slave_source")
	base_fmames_path = obs.obs_data_get_string(settings, "frame_path_edit") .. '/'
	
	print("Frame Synchronizer script upadted. Delay has been set to " .. total_seconds .. '; Master source is now "' .. master_source_name .. '; Filter source is now "' .. padding_filter_name .. '"; Slave source is now "' .. slave_source_name ..'".')

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

	-- script counter
	local hotkey_add_stream = obs.obs_hotkey_save(hotkey_id_1)
	local hotkey_dec_stream = obs.obs_hotkey_save(hotkey_id_2)
	obs.obs_data_set_array(settings, "add_stream_hotkey", hotkey_add_stream)
	obs.obs_data_set_array(settings, "dec_stream_hotkey", hotkey_dec_stream)	
	obs.obs_data_array_release(hotkey_add_stream)
	obs.obs_data_array_release(hotkey_dec_stream)
	--
end

-- a function named script_load will be called on startup
function script_load(settings)
	print("Frame Synchronizer script loaded")
	-- script counter
	hotkey_id_1 = obs.obs_hotkey_register_frontend("add_stream_thingy", "Increase Stream Counter", set_text1)
	hotkey_id_2 = obs.obs_hotkey_register_frontend("dec_stream_thingy", "Decrease Stream Counter", set_text2)
	hotkey_id_3 = obs.obs_hotkey_register_frontend("reset_stream_thingy", "Reset Stream Counter", reset_counter)
	local hotkey_add_stream = obs.obs_data_get_array(settings, "add_stream_hotkey")	
	local hotkey_dec_stream = obs.obs_data_get_array(settings, "dec_stream_hotkey")	
	local hotkey_reset_stream = obs.obs_data_get_array(settings, "dec_stream_hotkey")	
	obs.obs_hotkey_load(hotkey_id_1, hotkey_add_stream)
	obs.obs_hotkey_load(hotkey_id_2, hotkey_dec_stream)
	obs.obs_hotkey_load(hotkey_id_3, hotkey_reset_stream)
	obs.obs_data_array_release(hotkey_add_stream)	
	obs.obs_data_array_release(hotkey_dec_stream)
	obs.obs_data_array_release(hotkey_reset_stream)
	--
	activate(true)
end

--
-- text field stuff
--
-- Function to set the time text
function set_text1(pressed)	
	
	if not pressed or type(pressed) == 'userdata' then 
		set_text(true) 
	end
end

function set_text2(pressed)
	
	if not pressed or type(pressed) == 'userdata' then 
		set_text() 
	end
end


function set_text(increase, value)
	local counter_source = obs.obs_get_source_by_name(stream_counter_source_name)
	if counter_source ~= nil then
		local counter_props = obs.obs_source_get_settings(counter_source)
		local counter = math.floor(obs.obs_data_get_string(counter_props, 'text'))		
		if increase then
			print("increasing stream counter")
			counter = counter + 1
		else 
			if value then
				print("setting value")
				counter = value
			else
				print("decreasing stream counter")
				counter = counter - 1
			end
		end
		print(counter)
		obs.obs_data_set_string(counter_props, "text", math.floor(counter))
		obs.obs_source_update(counter_source, counter_props)
		obs.obs_data_release(counter_props)
		obs.obs_source_release(counter_source)
	end
	force_apply = true
	return true
end

function reset_counter()	
	set_text(nil, 0)
 end
 