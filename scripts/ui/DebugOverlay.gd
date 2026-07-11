extends Control
class_name DebugOverlay

var label: Label

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	offset_left = 8
	offset_top = 82
	offset_right = 190
	offset_bottom = 174

	label = Label.new()
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0))
	add_child(label)

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		visible = not visible

func update_state(match_manager: MatchManager) -> void:
	if not visible or label == null or match_manager == null:
		return

	var summary := match_manager.get_debug_summary()
	label.text = "FPS %d\nT %d W %d B %d\n%s" % [
		Engine.get_frames_per_second(),
		int(summary.get("territories", 0)),
		int(summary.get("waves", 0)),
		int(summary.get("battles", 0)),
		String(summary.get("state", ""))
	]
