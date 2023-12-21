obs           = obslua
source_name   = ""
death         = 0
hotkey_id     = obs.OBS_INVALID_HOTKEY_ID

-- Function to set the time text
function set_text()    
		local source = obs.obs_get_source_by_name(source_name)
		if source ~= nil then
			local settings = obs.obs_data_create()			 
			 death = death + 0.5			 
			obs.obs_data_set_string(settings, "text", "☠ "..  math.floor(death))
			obs.obs_source_update(source, settings)
			obs.obs_data_release(settings)
			obs.obs_source_release(source)
		end

end

function reset_counter()
   death = -0.5
   set_text()
end

function script_update(settings)
	source_name = obs.obs_data_get_string(settings, "source")
end

function script_properties()
     -- create props 
	local props = obs.obs_properties_create() 
	 -- add combobox to the settings panel
	local p = obs.obs_properties_add_list(props, "source", "Text Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	 -- get all sources
	local sources = obs.obs_enum_sources()
	-- add text sources to the combobox
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(sources)
	obs.obs_properties_add_button(props, "reset_button", "Reset Death Counter", reset_counter)

	return props
end


function script_description()
	return "Sets a text source to act as a Death Counter.\nSet a hotkey, press it, and enjoy it counting up!\n\nMade by 4aiman"
end


function script_save(settings)
	local hotkey_add_death = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, "add_death_hotkey", hotkey_add_death)
	obs.obs_data_array_release(hotkey_add_death)
end


function script_load(settings)
	hotkey_id = obs.obs_hotkey_register_frontend("add_death_thingy", "Add Death", set_text)
	local hotkey_add_death = obs.obs_data_get_array(settings, "add_death_hotkey")	
	obs.obs_hotkey_load(hotkey_id, hotkey_add_death)
	obs.obs_data_array_release(hotkey_add_death)
end
