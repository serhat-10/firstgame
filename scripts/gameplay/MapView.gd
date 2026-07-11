extends Node2D
class_name MapView

signal territory_pressed(territory_id: String)

const TerritoryViewScript := preload("res://scripts/gameplay/TerritoryView.gd")
const MapOverlayScript := preload("res://scripts/gameplay/MapOverlay.gd")

var map_data: Dictionary = {}
var gang_info: Dictionary = {}
var gang_colors: Dictionary = {}
var center_by_id: Dictionary = {}
var territory_views: Dictionary = {}
var overlay: MapOverlay
var active_battles: Dictionary = {}
var selected_source_id := ""
var valid_target_ids: Array = []

func setup(data: Dictionary, gang_data: Dictionary, localization: LocalizationManager) -> void:
	map_data = data
	_build_gang_info(gang_data)
	_clear_territories()
	center_by_id.clear()

	for territory in map_data.get("territories", []):
		var territory_id := String(territory.get("territory_id", ""))
		center_by_id[territory_id] = _vector_from_array(territory.get("center_position", [0, 0]))

		var owner_id := int(territory.get("owner_id", 0))
		var view := TerritoryViewScript.new()
		add_child(view)
		view.setup(
			territory,
			_owner_info(owner_id),
			localization.translate(String(territory.get("display_name_key", territory_id)))
		)
		view.territory_pressed.connect(func(id: String) -> void:
			emit_signal("territory_pressed", id)
		)
		territory_views[territory_id] = view

	overlay = MapOverlayScript.new()
	add_child(overlay)
	overlay.setup(center_by_id, gang_colors)

	queue_redraw()

func update_territory(territory_id: String, territory: Dictionary) -> void:
	if not territory_views.has(territory_id):
		return
	var view: TerritoryView = territory_views[territory_id]
	var owner_id := int(territory.get("owner_id", 0))
	view.set_owner_info(owner_id, _owner_info(owner_id))
	view.set_population(float(territory.get("population", 0.0)))
	view.set_state(String(territory.get("current_state", "neutral")))

func set_selected(territory_id: String) -> void:
	selected_source_id = territory_id
	_apply_interaction_states()

func set_targeting(source_id: String, target_ids: Array) -> void:
	selected_source_id = source_id
	valid_target_ids = target_ids.duplicate()
	_apply_interaction_states()
	if overlay != null:
		overlay.set_targeting(selected_source_id, valid_target_ids)

func set_waves(waves: Array) -> void:
	if overlay != null:
		overlay.set_waves(waves)

func set_battles(battles: Dictionary) -> void:
	active_battles = battles.duplicate(true)
	for id in territory_views.keys():
		var view: TerritoryView = territory_views[id]
		view.clear_battle()

	for territory_id in active_battles.keys():
		if not territory_views.has(territory_id):
			continue
		var battle: Dictionary = active_battles[territory_id]
		var view: TerritoryView = territory_views[territory_id]
		view.set_battle(
			_owner_color(int(battle.get("attacker_owner_id", 0))),
			_owner_color(int(battle.get("defender_owner_id", 0))),
			float(battle.get("dominance", 0.5)),
			int(battle.get("attacker_display", 0)),
			int(battle.get("defender_display", 0))
		)

func _draw() -> void:
	_draw_city_background()

func _draw_city_background() -> void:
	draw_rect(Rect2(0, 0, 390, 844), Color(0.035, 0.045, 0.065), true)

	var city_shadow := PackedVector2Array([
		Vector2(32, 118), Vector2(336, 124), Vector2(372, 224), Vector2(374, 690),
		Vector2(324, 760), Vector2(44, 742), Vector2(12, 636), Vector2(20, 184)
	])
	draw_colored_polygon(city_shadow, Color(0.07, 0.085, 0.11, 0.72))

	var river := PackedVector2Array([
		Vector2(154, 116), Vector2(176, 190), Vector2(164, 292), Vector2(196, 384),
		Vector2(174, 488), Vector2(214, 598), Vector2(198, 742)
	])
	draw_polyline(river, Color(0.10, 0.20, 0.28, 0.50), 18.0, true)
	draw_polyline(river, Color(0.26, 0.58, 0.72, 0.16), 3.0, true)

	var avenue_color := Color(0.36, 0.40, 0.48, 0.16)
	draw_line(Vector2(38, 388), Vector2(356, 438), avenue_color, 6.0, true)
	draw_line(Vector2(66, 112), Vector2(300, 742), avenue_color, 4.0, true)
	draw_line(Vector2(24, 602), Vector2(358, 604), avenue_color, 5.0, true)
	draw_line(Vector2(280, 130), Vector2(306, 742), avenue_color, 4.0, true)

	for index in range(18):
		var x := 28.0 + float((index * 47) % 320)
		var y := 124.0 + float((index * 83) % 570)
		var w := 16.0 + float(index % 3) * 7.0
		var h := 8.0 + float(index % 4) * 5.0
		draw_rect(Rect2(Vector2(x, y), Vector2(w, h)), Color(0.75, 0.80, 0.88, 0.035), false, 1.0)

	draw_circle(Vector2(78, 646), 44.0, Color(0.12, 0.28, 0.22, 0.22))
	draw_circle(Vector2(78, 646), 27.0, Color(0.14, 0.34, 0.24, 0.16))

func _apply_interaction_states() -> void:
	var has_selection := not selected_source_id.is_empty()
	for id in territory_views.keys():
		var territory_id := String(id)
		var is_selected := territory_id == selected_source_id
		var is_valid := valid_target_ids.has(territory_id)
		var is_dimmed := has_selection and not is_selected and not is_valid
		var view: TerritoryView = territory_views[territory_id]
		view.set_interaction_state(is_selected, is_valid, is_dimmed)

func _build_gang_info(gang_data: Dictionary) -> void:
	gang_info.clear()
	gang_colors.clear()
	for gang in gang_data.get("gangs", []):
		var id := int(gang.get("id", 0))
		var color := Color.html(String(gang.get("color", "#9BA3AE")))
		gang_info[id] = {
			"color": color,
			"emblem": String(gang.get("emblem", "--")),
			"motif": String(gang.get("motif", "neutral")),
			"name_key": String(gang.get("name_key", ""))
		}
		gang_colors[id] = color

func _owner_info(owner_id: int) -> Dictionary:
	return gang_info.get(owner_id, {
		"color": Color.GRAY,
		"emblem": "--",
		"motif": "neutral",
		"name_key": ""
	})

func _owner_color(owner_id: int) -> Color:
	return Color(_owner_info(owner_id).get("color", Color.GRAY))

func _clear_territories() -> void:
	for child in get_children():
		child.queue_free()
	territory_views.clear()
	overlay = null

func _vector_from_array(raw: Variant) -> Vector2:
	if raw is Array and raw.size() >= 2:
		return Vector2(float(raw[0]), float(raw[1]))
	return Vector2.ZERO

