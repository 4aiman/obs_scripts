--[[

    Issue: 
        One can't iterate over a source properties in Lua

    Why it happens:
		-- obs.obs_get_source_properties always returns nill 
		-- obs.obs_source_get_settings can't be iterated over
        -- obs_properties_first can be used, but obs_properties_next expects a pointer while Lua bindings operate with objects
        -- OBS devs ignored issues aimed to fix this for several years
        
    Solution accepted by the OBS devs: 
        Use FFI to create a second wrapper for something that an already embedded LUa bindings should give access to.

    My solution:
        Use json-lua by tiye (https://github.com/tiye/json-lua/tree/main) to make JSON dataiteratable
    
    How to use:
        - add these lines to any of your scripts to be able to iterate over source properties through lua
        - work with native Lua tables using 2 new methods


]]

-- load JSON
json = require("deps.JSON")

-- helper to get the settings of a source
obs.obs_source_get_settings_json = function (source)	
	local properties = obs.obs_source_get_settings(source)
	local json_encoded = obs.obs_data_get_json(properties)
	local data = json:decode(json_encoded)
	return data
end

-- helper to set the settings of a source
obs.obs_source_set_settings_json = function (source, json_properties)	
	local properties =  obs.obs_source_get_settings(source)
	for key, value in pairs(json_properties) do
		obs.obs_data_set_string(properties, key, value)
	end
	obs.obs_source_update(slave_source, slave_props)
end


