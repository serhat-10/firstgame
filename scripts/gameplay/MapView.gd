extends Node2D
class_name MapView

signal territory_pressed(territory_id: String)

const TerritoryViewScript := preload("res://scripts/gameplay/TerritoryView.gd")

var map_data: Dictionary = {}
var gang_colors: Dictionary = {}
var center_by_id: Dictionary = {}
var territory_views: Dictionary = {}
var active_waves: Array = []
var active_battles: Dictionary = {}

func setup(data: Dictionary, gang_data: Dictionary, localization: LocalizationManager) -> void:
	map_data = data
	_build_gang_colors(gang_data)
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
			Color(gang_colors.get(owner_id, Color.GRAY)),
			localization.translate(String(territory.get("display_name_key", territory_id)))
		)
		view.territory_pressed.connect(func(id: String) -> void:
			emit_signal("territory_pressed", id)
		)
		territory_views[territory_id] = view

	queue_redraw()

func update_territory(territory_id: String, territory: Dictionary) -> void:
	if not territory_views.has(territory_id):
		return
	var view: TerritoryView = territory_views[territory_id]
	view.set_owner_color(_owner_color(int(territory.get("owner_id", 0))))
	view.set_population(float(territory.get("population", 0.0)))
	view.set_state(String(territory.get("current_state", "neutral")))

func set_selected(territory_id: String) -> void:
	for id in territory_views.keys():
		var view: TerritoryView = territory_views[id]
		view.set_selected(String(id) == territory_id)

func set_waves(waves: Array) -> void:
	active_waves = waves.duplicate(true)
	queue_redraw()

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
	_draw_connections()
	_draw_waves()

func _draw_connections() -> void:
	var drawn := {}
	for territory in map_data.get("territories", []):
		var territory_id := String(territory.get("territory_id", ""))
		var start: Vector2 = center_by_id.get(territory_id, Vector2.ZERO)
		for neighbor_id in territory.get("neighbor_ids", []):
			var neighbor := String(neighbor_id)
			var pair := [territory_id, neighbor]
			pair.sort()
			var key := "%s:%s" % [pair[0], pair[1]]
			if drawn.has(key):
				continue
			drawn[key] = true
			var end: Vector2 = center_by_id.get(neighbor, Vector2.ZERO)
			draw_line(start, end, Color(0.22, 0.25, 0.30), 3.0, true)
			draw_circle(start.lerp(end, 0.5), 3.0, Color(0.42, 0.48, 0.58))

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
		var dot_count := clampi(int(float(wave.get("amount", 1)) / 7.0) + 2, 2, 7)

		for index in range(dot_count):
			var offset := float(index) * 0.045
			var dot_progress := clampf(progress - offset, 0.0, 1.0)
			if dot_progress <= 0.0 or dot_progress >= 1.0:
				continue
			var position := start.lerp(end, dot_progress)
			draw_circle(position, 4.0, color)
			draw_circle(position, 6.0, Color(color.r, color.g, color.b, 0.18))

func _build_gang_colors(gang_data: Dictionary) -> void:
	gang_colors.clear()
	for gang in gang_data.get("gangs", []):
		var id := int(gang.get("id", 0))
		gang_colors[id] = Color.html(String(gang.get("color", "#9BA3AE")))

func _owner_color(owner_id: int) -> Color:
	return Color(gang_colors.get(owner_id, Color.GRAY))

func _clear_territories() -> void:
	for child in get_children():
		child.queue_free()
	territory_views.clear()

func _vector_from_array(raw: Variant) -> Vector2:
	if raw is Array and raw.size() >= 2:
		return Vector2(float(raw[0]), float(raw[1]))
	return Vector2.ZERO

