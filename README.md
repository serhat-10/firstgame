# District Zero

A lightweight Godot 4 portrait mobile strategy vertical slice. The current build presents a 12-district stylized city map with faction control, passive influence growth, neighbor-only unit sending, timed battles, capture feedback, simple AI, pause/restart, local save scaffolding, and English/Turkish localization.

## Run

1. Open this folder in Godot 4.x.
2. Open `project.godot`.
3. Press Play. The main scene is `res://scenes/main/Main.tscn`.

The core game uses only local files and `user://` saves. It has no backend, accounts, analytics, ads, or required network dependency.

## Opening The Scene In Godot

If Godot opens to an empty 3D grid, the project is open but the 2D game scene is not selected yet.

To open the playable scene:

1. In the top editor tabs, choose `2D`.
2. In the FileSystem panel, open `res://scenes/main/Main.tscn`.
3. Press Play, or press `F5`.

If the FileSystem panel is hidden, use `Scene > Open Scene` and select:

```text
scenes/main/Main.tscn
```

You can also run the game directly because `project.godot` already points to `res://scenes/main/Main.tscn` as the main scene.

## Smoke Test

If Godot is available on your command line:

```bash
godot --headless --path . -s res://tests/smoke_test.gd
```

## Current Milestone

This is a visually redesigned vertical slice, not the full 16-territory MVP map. The implemented test map has 12 districts and four faction identities so the intended map, HUD, interaction, and battle direction can be validated.
