Autoload Scripts
================
These scripts mostly consist of advanced functions (CmdletBindings) that are intended to be loaded into an environment rather than run directly from the script file. Summaries are as follows with rough creation years to indicate age (and my lack of experience at time of creation):

Get-KHInsiderAlbum.ps1 (2017)
-------------------------
https://downloads.khinsider.com/ hosts mp3 soundtracks for a wide selection of modern and (more importantly) retro video games. Unfortunately, you must register an account to download a full album at a time, and most browsers limit the number of concurrent downloads you can have running. I didn't want to have to register an account and being limited to downloading 5 songs at a time was annoying, so I wrote this script. With this you specify the album link and come back when it's done. Should still work as long as khinsider hasn't changed their site layout and hasn't been sued into oblivion for copyright violations.

Set-UE4DefaultEnabledPlugins (2021)
-----------------------------------
Unreal Engine 4 comes with hundreds of plugins pre-installed and has hundreds more available for download either via the marketplace or online. A huge number of these plugins are enabled whenever you create a new project (most annoyingly the VR plugins which start up other applications in the background). However, the vast majority of the plugins are for features you will probably never use and having them enabled serves no purpose other than to slow down the engine's startup time and clutter the menus in the editor. As of UE 4.26.1, the only option to combat this is to, for each project, open the plugins menu and disable 100+ plugins one at a time.

This script changes the default state of the plugins so that new projects will have the plugins disabled by default. Point it at your engine installation and optionally specify any plugins that you would like to be enabled by default, and the script will go through and set all the other plugins to disabled. Any new projects created using that engine version will have these defaults applied. Existing projects are not modified, and this script will need to be re-run with each new engine version installed.

Requires PowerShell 6+ since some of the *.uplugin files are invalid JSON (trailing commas in arrays are illegal according to spec) and the older versions of PowerShell are more strict about this. Also requires UE 4.3.1 or newer since *.uplugin files didn't exist before that. But 4.3.1 came out in 2014, so if you're still on it you should seriously consider updating.

Also includes the `Initialize-UE4RecommendedPlugins` function which streamlines this script with the small handful of plugins I prefer enabled on all my projects.