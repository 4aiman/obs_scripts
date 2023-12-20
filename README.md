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
Tinker with it to suit your needs.
