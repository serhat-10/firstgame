extends Node2D
class_name MapOverlay

var center_by_id: Dictionary = {}
var active_waves: Array = []
var selected_source_id := ""
var valid_target_ids: Array = []
var gang_colors: Dictionary = {}

func setup(centers: Dictionary, colors: Dictionary) -> void:
	center_by_id = centers
	gang_colors = colors
	queue_redraw()

func set_targeting(source_id: String, target_ids: Array) -> void:
	selected_source_id = source_id
	valid_target_ids = target_ids.duplicate()
	queue_redraw()

func set_waves(waves: Array) -> void:
	active_waves = waves.duplicate(true)
	queue_redraw()

func _draw() -> void:
	_draw_target_paths()
	_draw_waves()

func _draw_target_paths() -> void:
	if selected_source_id.is_empty() or not center_by_id.has(selected_source_id):
		return

	var start: Vector2 = center_by_id[selected_source_id]
	for raw_target_id in valid_target_ids:
		var target_id := String(raw_target_id)
		if not center_by_id.has(target_id):
			continue

		var end: Vector2 = center_by_id[target_id]
		var color := Color(0.64, 0.92, 1.0, 0.46)
		draw_line(start, end, Color(color.r, color.g, color.b, 0.12), 9.0, true)
		draw_line(start, end, color, 2.0, true)
		draw_circle(end, 6.0, Color(color.r, color.g, color.b, 0.22))

func _draw_waves() -> void:
	for wave in active_waves:
		var source_id := String(wave.get("source_id", ""))
		var target_id := String(wave.get("target_id", ""))
		if not center_by_id.has(source_id) or not center_by_id.has(target_id):
			continue

		var start: Vector2 = center_by_id[source_id]
		var end: Vector2 = center_by_id[target_id]
		var progress := clampf(float(wave.get("progress", 0.0)), 0.0, 1.0)
		var owner_id := int(wave.get("owner_id", 0))
		var color := _owner_color(owner_id)
		var amount := maxf(1.0, float(wave.get("amount", 1)))
		var dot_count := clampi(int(amount / 8.0) + 5, 8, 15)
		var head := start.lerp(end, progress)

		draw_line(start, head, Color(color.r, color.g, color.b, 0.10), 12.0, true)
		draw_line(start, head, Color(color.r, color.g, color.b, 0.62), 2.5, true)

		for index in range(dot_count):
			var offset := float(index) * 0.032
			var dot_progress := clampf(progress - offset, 0.0, 1.0)
			if dot_progress <= 0.0 or dot_progress >= 1.0:
				continue
			var position := start.lerp(end, dot_progress)
			var radius := 3.2 + sin((dot_progress + float(index)) * TAU) * 0.6
			draw_circle(position, radius + 4.0, Color(color.r, color.g, color.b, 0.12))
			draw_circle(position, radius, color)

func _owner_color(owner_id: int) -> Color:
	return Color(gang_colors.get(owner_id, Color(0.7, 0.75, 0.8)))

