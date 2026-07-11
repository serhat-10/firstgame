extends Area2D
class_name TerritoryView

signal territory_pressed(territory_id: String)

var territory_id := ""
var center := Vector2.ZERO
var polygon_node: Polygon2D
var border_node: Line2D
var population_label: Label
var base_color := Color.WHITE
var selected := false
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

func setup(data: Dictionary, owner_color: Color, display_name: String) -> void:
	territory_id = String(data.get("territory_id", ""))
	center = _vector_from_array(data.get("center_position", [0, 0]))
	base_color = owner_color

	polygon_node = Polygon2D.new()
	polygon_node.polygon = _points_from_array(data.get("polygon", []))
	polygon_node.color = owner_color
	add_child(polygon_node)

	var collision := CollisionPolygon2D.new()
	collision.polygon = polygon_node.polygon
	add_child(collision)

	border_node = Line2D.new()
	border_node.points = _closed_points(polygon_node.polygon)
	border_node.width = 2.5
	border_node.default_color = owner_color.lerp(Color.BLACK, 0.35)
	add_child(border_node)

	population_label = Label.new()
	population_label.tooltip_text = display_name
	population_label.position = center - Vector2(40, 18)
	population_label.size = Vector2(80, 36)
	population_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	population_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	population_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	population_label.add_theme_font_size_override("font_size", 16)
	population_label.add_theme_color_override("font_color", Color.WHITE)
	population_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	population_label.add_theme_constant_override("shadow_offset_x", 1)
	population_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(population_label)

	set_population(float(data.get("population", 0)))
	set_process(true)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		emit_signal("territory_pressed", territory_id)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("territory_pressed", territory_id)

func set_owner_color(color: Color) -> void:
	base_color = color
	if battle_active:
		return

	if color_tween != null:
		color_tween.kill()

	if is_inside_tree():
		color_tween = create_tween()
		color_tween.tween_property(polygon_node, "color", color, 0.18)
	else:
		polygon_node.color = color

	_refresh_border()

func set_population(population: float) -> void:
	current_population = int(round(population))
	if not battle_active:
		population_label.text = str(current_population)

func set_selected(is_selected: bool) -> void:
	selected = is_selected
	_refresh_border()

func set_state(state: String) -> void:
	current_state = state
	if state == "captured":
		capture_flash = 1.0
	_refresh_border()

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
	polygon_node.color = defender_color.lerp(attacker_color, battle_dominance * 0.55)
	population_label.text = "%d/%d" % [defender_display, attacker_display]
	_refresh_border()
	queue_redraw()

func clear_battle() -> void:
	if not battle_active:
		return
	battle_active = false
	polygon_node.color = base_color
	population_label.text = str(current_population)
	_refresh_border()
	queue_redraw()

func _process(delta: float) -> void:
	pulse_time += delta
	if capture_flash > 0.0:
		capture_flash = maxf(0.0, capture_flash - delta * 2.5)
		queue_redraw()

	if battle_active:
		var pulse := (sin(pulse_time * 10.0) + 1.0) * 0.5
		border_node.width = 3.0 + pulse * 2.2
		border_node.default_color = battle_defender_color.lerp(battle_attacker_color, pulse)

func _draw() -> void:
	if battle_active:
		var bar_width := 72.0
		var bar_height := 8.0
		var top_left := center + Vector2(-bar_width * 0.5, 22)
		draw_rect(Rect2(top_left, Vector2(bar_width, bar_height)), Color(0, 0, 0, 0.55), true)
		draw_rect(Rect2(top_left, Vector2(bar_width * battle_dominance, bar_height)), battle_attacker_color, true)
		draw_rect(
			Rect2(top_left + Vector2(bar_width * battle_dominance, 0), Vector2(bar_width * (1.0 - battle_dominance), bar_height)),
			battle_defender_color,
			true
		)

	if capture_flash > 0.0:
		draw_circle(center, 38.0 + (1.0 - capture_flash) * 28.0, Color(1, 1, 1, capture_flash * 0.18))

func _refresh_border() -> void:
	if border_node == null:
		return

	if selected:
		border_node.width = 5.0
		border_node.default_color = Color.WHITE
	elif battle_active:
		border_node.width = 4.0
	else:
		border_node.width = 2.5
		border_node.default_color = base_color.lerp(Color.BLACK, 0.35)

func _vector_from_array(raw: Variant) -> Vector2:
	if raw is Array and raw.size() >= 2:
		return Vector2(float(raw[0]), float(raw[1]))
	return Vector2.ZERO

func _points_from_array(raw_points: Variant) -> PackedVector2Array:
	var points := PackedVector2Array()
	if raw_points is Array:
		for point in raw_points:
			if point is Array and point.size() >= 2:
				points.append(Vector2(float(point[0]), float(point[1])))
	return points

func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := PackedVector2Array()
	for point in points:
		closed.append(point)
	if points.size() > 0:
		closed.append(points[0])
	return closed

