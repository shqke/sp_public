About
------
Manage fixed cameras (`point_viewcontrol` entities) used by HLTV Director on the fly.

Admin Commands
------
- `sm_addhltvcamera [name|*] [origin]` - Adds a new camera with unique name
  - `name` - optional camera base name; if camera with same `name` exists - will append `_XX`
  - `origin` - optional position of camera, if not set will take the position of player eyes
- `sm_sethltvcamera [name] [origin]` - Moves existing camera to a new position
  - `name` - camera name
  - `origin` - optional position of camera, if not set will take the position of player eyes
- `sm_delhltvcamera [name]` - Deletes camera from the game and config
  - `name` - camera name
- `sm_clearhltvcameras` - Clear (empty) config file
- `sm_reloadhltvcameras` - Reload cameras from config file
- `sm_listhltvcameras` - Display current camera cache

Supported Games
------
- [Left 4 Dead](https://store.steampowered.com/app/500/Left_4_Dead/)
- [Left 4 Dead 2](https://store.steampowered.com/app/550/Left_4_Dead_2/)
- other games require gamedata
