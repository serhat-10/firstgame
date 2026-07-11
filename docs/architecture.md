# Architecture

## Runtime Flow

`Main.gd` owns screen flow and lifecycle handling. It creates the menu or game screen, forwards background/focus events, and saves active matches before leaving gameplay.

`GameScreen.gd` composes the playable scene. It loads data, wires UI, map rendering, match logic, AI, audio, tutorial, debug overlay, and save calls.

`MatchManager.gd` owns deterministic match state. It updates population growth, validates neighbor-only actions, moves waves, resolves timed battles, emits capture events, and checks victory or defeat.

`MapView.gd` and `TerritoryView.gd` render the map and receive touches. They do not decide rules.

`AIManager.gd` evaluates the current map state and calls the same `request_send` API as the player.

`Rules.gd` contains small deterministic calculations that can be smoke-tested without rendering.

## Data

Balance values live in `data/balance/balance.json`.

Gang colors and AI profiles live in `data/gangs/gangs.json`.

The test map lives in `data/maps/first_playable.json`.

Localization dictionaries live in `data/localization/en.json` and `data/localization/tr.json`.

