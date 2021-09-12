About
------
Executes related configs at level change (`.cfg` files must be located inside folder `<GAME>/cfg/presets/`):

- `mode_<gamemode>.cfg`
- `mode_<gamemode>_<difficulty>.cfg`
- `basemode_<base gamemode>.cfg`
- `mission_<mission>.cfg`
- `modemission_<gamemode>_<mission>.cfg`
- `basemodemission_<base gamemode>_<mission>.cfg`
- `mode_has_difficulty.cfg` - mode has difficulty setting (coop, realism)
- `mode_has_pz.cfg` - mode allows player zombies (versus, scavenge)
- `mode_single_chapter.cfg` - mode is of a single chapter type (survival, scavenge)

Game modes, mission names and difficulties are lowercased before execution for consistency.

Requirements
------
- [imatchext](https://github.com/shqke/imatchext)

Supported Games
------
- [Left 4 Dead 2](https://store.steampowered.com/app/550/Left_4_Dead_2/)
