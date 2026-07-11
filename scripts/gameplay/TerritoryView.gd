extends Area2D
class_name TerritoryView

signal territory_pressed(territory_id: String)

var territory_id := ""
var center := Vector2.ZERO
var display_name := ""
var owner_id := 0
var owner_emblem := "--"
var owner_motif := "neutral"
var local_polygon := PackedVector2Array()
var closed_polygon := PackedVector2Array()
var polygon_node: Polygon2D
var battle_fill_node: Polygon2D
var border_node: Line2D
var name_label: Label
var population_label: Label
var battle_label: Label
var emblem_label: Label
var base_color := Color.WHITE
var selected := false
var valid_target := false
var dimmed := false
var battle_active := false
var battle_attacker_color := Color.WHITE
var battle_defender_color := Color.WHITE
var battle_dominance := 0.5
var attacker_display := 0
var defender_display := 0
var current_population := 0
var current_state := "neutral"
var pulse_time := 0.0
var capture_flash := 0.0
var color_tween: Tween
var scale_tween: Tween

func setup(data: Dictionary, owner_info: Dictionary, localized_name: String) -> void:
	territory_id = String(data.get("territory_id", ""))
	center = _vector_from_array(data.get("center_position", [0, 0]))
	display_name = localized_name
	position = center
	input_pickable = true

	local_polygon = _local_points_from_array(data.get("polygon", []), center)
	closed_polygon = _closed_points(local_polygon)

	polygon_node = Polygon2D.new()
	polygon_node.polygon = local_polygon
	add_child(polygon_node)

	battle_fill_node = Polygon2D.new()
	battle_fill_node.polygon = local_polygon
	battle_fill_node.visible = false
	add_child(battle_fill_node)

	var collision := CollisionPolygon2D.new()
	collision.polygon = local_polygon
	add_child(collision)

	border_node = Line2D.new()
	border_node.points = closed_polygon
	border_node.width = 1.6
	add_child(border_node)

	name_label = _make_label(Vector2(-58, -31), Vector2(116, 15), 8)
	name_label.text = display_name.to_upper()
	name_label.add_theme_color_override("font_color", Color(0.83, 0.88, 0.94))
	add_child(name_label)

	population_label = _make_label(Vector2(-50, -15), Vector2(100, 33), 20)
	population_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(population_label)

	battle_label = _make_label(Vector2(-48, 16), Vector2(96, 14), 8)
	battle_label.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	battle_label.visible = false
	add_child(battle_label)

	emblem_label = _make_label(Vector2(25, -42), Vector2(28, 18), 8)
	emblem_label.add_theme_color_override("font_color", Color(0.06, 0.08, 0.11))
	add_child(emblem_label)

	set_owner_info(int(data.get("owner_id", 0)), owner_info)
	set_population(float(data.get("population", 0)))
	set_process(true)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		emit_signal("territory_pressed", territory_id)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("territory_pressed", territory_id)

func set_owner_info(new_owner_id: int, owner_info: Dictionary) -> void:
	owner_id = new_owner_id
	base_color = Color(owner_info.get("color", Color.GRAY))
	owner_emblem = String(owner_info.get("emblem", "--"))
	owner_motif = String(owner_info.get("motif", "neutral"))
	emblem_label.text = owner_emblem

	if battle_active:
		return

	if color_tween != null:
		color_tween.kill()

	var target_color := _fill_color_for_owner()
	if is_inside_tree():
		color_tween = create_tween()
		color_tween.tween_property(polygon_node, "color", target_color, 0.18)
	else:
		polygon_node.color = target_color

	_refresh_border()
	queue_redraw()

func set_population(population: float) -> void:
	current_population = int(round(population))
	if not battle_active:
		population_label.text = str(current_population)

func set_interaction_state(is_selected: bool, is_valid_target: bool, is_dimmed: bool) -> void:
	selected = is_selected
	valid_target = is_valid_target
	dimmed = is_dimmed
	modulate = Color(1, 1, 1, 0.42) if dimmed else Color.WHITE
	_refresh_border()
	queue_redraw()

func set_selected(is_selected: bool) -> void:
	set_interaction_state(is_selected, false, false)

func set_state(state: String) -> void:
	current_state = state
	if state == "captured":
		capture_flash = 1.0
		_play_capture_pulse()
	_refresh_border()
	queue_redraw()

func set_battle(
	attacker_color: Color,
	defender_color: Color,
	dominance: float,
	attacker_value: int,
	defender_value: int
) -> void:
	battle_active = true
	battle_attacker_color = attacker_color
	battle_defender_color = defender_color
	battle_dominance = clampf(dominance, 0.0, 1.0)
	attacker_display = attacker_value
	defender_display = defender_value

	polygon_node.color = defender_color.lerp(Color(0.05, 0.06, 0.08), 0.10)
	battle_fill_node.visible = true
	battle_fill_node.scale = Vector2(maxf(0.08, battle_dominance), maxf(0.08, battle_dominance))
	battle_fill_node.color = Color(attacker_color.r, attacker_color.g, attacker_color.b, 0.76)
	population_label.text = str(defender_display)
	battle_label.text = "%d  |  %d" % [defender_display, attacker_display]
	battle_label.visible = true
	_refresh_border()
	queue_redraw()

func clear_battle() -> void:
	if not battle_active:
		return
	battle_active = false
	battle_fill_node.visible = false
	polygon_node.color = _fill_color_for_owner()
	population_label.text = str(current_population)
	battle_label.visible = false
	_refresh_border()
	queue_redraw()

func _process(delta: float) -> void:
	pulse_time += delta
	if capture_flash > 0.0:
		capture_flash = maxf(0.0, capture_flash - delta * 2.8)
		queue_redraw()

	if battle_active:
		var pulse := (sin(pulse_time * 11.0) + 1.0) * 0.5
		border_node.width = 2.0 + pulse * 2.4
		border_node.default_color = battle_defender_color.lerp(battle_attacker_color, pulse)

func _draw() -> void:
	if selected:
		_draw_polygon_glow(Color(0.72, 0.95, 1.0, 0.36), 8.0)
	elif valid_target:
		_draw_polygon_glow(Color(0.52, 0.88, 1.0, 0.26), 6.0)

	_draw_owner_motif()

	if battle_active:
		var bar_width := 62.0
		var bar_height := 5.0
		var top_left := Vector2(-bar_width * 0.5, 34)
		draw_rect(Rect2(top_left, Vector2(bar_width, bar_height)), Color(0, 0, 0, 0.50), true)
		draw_rect(Rect2(top_left, Vector2(bar_width * battle_dominance, bar_height)), battle_attacker_color, true)
		draw_rect(
			Rect2(top_left + Vector2(bar_width * battle_dominance, 0), Vector2(bar_width * (1.0 - battle_dominance), bar_height)),
			battle_defender_color,
			true
		)

	if capture_flash > 0.0:
		var glow_color := Color(base_color.r, base_color.g, base_color.b, capture_flash * 0.22)
		draw_circle(Vector2.ZERO, 42.0 + (1.0 - capture_flash) * 34.0, glow_color)
		_draw_polygon_glow(Color(1, 1, 1, capture_flash * 0.26), 10.0)

func _draw_polygon_glow(color: Color, width: float) -> void:
	if closed_polygon.size() < 2:
		return
	draw_polyline(closed_polygon, color, width, true)

func _draw_owner_motif() -> void:
	var motif_color := Color(base_color.r, base_color.g, base_color.b, 0.34)
	match owner_motif:
		"slash":
			draw_line(Vector2(-39, -36), Vector2(-25, -22), motif_color, 2.0, true)
			draw_line(Vector2(-30, -38), Vector2(-16, -24), motif_color, 2.0, true)
		"bar":
			draw_line(Vector2(-38, -37), Vector2(-38, -22), motif_color, 2.0, true)
			draw_line(Vector2(-31, -37), Vector2(-31, -22), motif_color, 2.0, true)
		"dot":
			draw_circle(Vector2(-34, -30), 3.0, motif_color)
			draw_circle(Vector2(-24, -25), 2.0, motif_color)
		"ring":
			draw_arc(Vector2(-31, -30), 7.0, 0.0, TAU, 20, motif_color, 2.0, true)
		_:
			draw_line(Vector2(-39, -29), Vector2(-21, -29), Color(0.8, 0.86, 0.92, 0.18), 1.4, true)

func _refresh_border() -> void:
	if border_node == null:
		return

	if selected:
		border_node.width = 2.8
		border_node.default_color = Color(0.80, 0.96, 1.0)
	elif valid_target:
		border_node.width = 2.2
		border_node.default_color = Color(0.62, 0.90, 1.0)
	elif battle_active:
		border_node.width = 3.0
	else:
		border_node.width = 1.35
		border_node.default_color = Color(base_color.r, base_color.g, base_color.b, 0.82)

func _play_capture_pulse() -> void:
	if scale_tween != null:
		scale_tween.kill()
	scale = Vector2.ONE
	scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", Vector2(1.055, 1.055), 0.12)
	scale_tween.tween_property(self, "scale", Vector2.ONE, 0.24)

func _fill_color_for_owner() -> Color:
	if owner_id == 0:
		return Color(0.42, 0.47, 0.53, 0.88)
	return base_color.lerp(Color(0.04, 0.05, 0.07), 0.18)

func _make_label(offset: Vector2, label_size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = offset
	label.size = label_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _vector_from_array(raw: Variant) -> Vector2:
	if raw is Array and raw.size() >= 2:
		return Vector2(float(raw[0]), float(raw[1]))
	return Vector2.ZERO

func _local_points_from_array(raw_points: Variant, origin: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	if raw_points is Array:
		for point in raw_points:
			if point is Array and point.size() >= 2:
				points.append(Vector2(float(point[0]), float(point[1])) - origin)
	return points

func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := PackedVector2Array()
	for point in points:
		closed.append(point)
	if points.size() > 0:
		closed.append(points[0])
	return closed

