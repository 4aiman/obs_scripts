# A collection (?) of OBS scripts...
...designed to make my life easier (and maybe yours?), no thanks to the OBS devs

## [source_synchronizer.lua](https://github.com/4aiman/obs_scripts/blob/main/source_synchronizer.lua)
Syncs your game audio capture source with your game window capture source.<br><br>
If you want a finer degree of control what's getting in your VOD stream 2 - this is the script for you.<br>
You know how you can stop capturing the entire desktop monitor and grab only what you need?<br>
Well, except now you have to remember to update **two** sources instead of one every time you change a game/app you'd like to capture... 
This script brings it down to one again by synchronizing target window of an audio capture source with the target window of an image grabbing source.<br>
Enjoy!

## [frame_updater.lua](https://github.com/4aiman/obs_scripts/blob/main/frame_updater.lua)
Checks the size of a game capture source and updates filepath of an image source to match that.<br>
Right now only 2 resolutions are supported ad nothing is in the GUI apart from upadte interval and 2 sources: the game capture one and the frame/overlay one.<br>
Be sure to select the folder with your frames.<br>
If you want to change your crop filter name, then load the script and *refresh it*. That's the only way to update the list in OBS properties after it's been created, since one can't update a list on properties update. (In reality refreshing recreates the properties object)<br>
Tinker with it to suit your needs.

## [frame_updater_custom.lua](https://github.com/4aiman/obs_scripts/blob/main/frame_updater_custom.lua)
A more elaborate version of the previous script. <br>
It adds stream number tracking via a text source and a browser source.<br>
You probably don't need it "as is", but there are things to learn inside:
 - fixing hotkeys firing twice and/or not firing when clicking buttons in the UI
 - settings custom css to a browser source (sadly requeires source refresh)
 - setting up hotkeys and buttons callbacks
 - reading and writing text source text

## [death_counter.lua](https://github.com/4aiman/obs_scripts/blob/main/death_counter.lua)
Uses one of the text sources as a death counter.<br>
Set up a hotkey and press it for the counter to go up.<br>
Reset the counter in the script setting window.

## [obs_source_set_settings_fix.lua](https://github.com/4aiman/obs_scripts/blob/main/obs_source_set_settings_fix.lua)
A helper file that can help one iterate OBS source's properties (also works for filters, as those are treated as sources internally).<br>
Find details inside the file.

## [DEPS](https://github.com/4aiman/obs_scripts/blob/main/deps)
This folder contains all the Lua scripts that will help circumvent crappy desing of Lua bindings in OBS.<br>

