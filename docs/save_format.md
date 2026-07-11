# Local Save Format

Save file path: `user://match_save.json`

Current version: `1`

Saved fields:

- `version`
- `map_id`
- `player_gang_id`
- `elapsed_time`
- `territories`: territory ID, owner ID, population, state
- `ai`: per-gang AI timers
- `settings_snapshot`: language, sound, haptics, tutorial completion

Settings path: `user://settings.cfg`

Loading is defensive. Missing, corrupt, or unsupported save files return an empty dictionary so the menu can offer a new game instead of crashing.

