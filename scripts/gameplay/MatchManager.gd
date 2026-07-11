extends Node
class_name MatchManager

signal territory_changed(territory_id: String, territory: Dictionary)
signal selection_changed(territory_id: String)
signal wave_data_changed(waves: Array)
signal battle_data_changed(battles: Dictionary)
signal match_status_changed(status_key: String)
signal gang_count_changed(count: int)
signal match_ended(result_key: String)
signal feedback_event(event_name: String, payload: Dictionary)

const RulesScript := preload("res://scripts/core/Rules.gd")
const SAVE_VERSION := 1

var balance: Dictionary = {}
var map_data: Dictionary = {}
var gang_data: Dictionary = {}
var territories: Dictionary = {}
var active_waves: Array = []
var active_battles: Dictionary = {}
var selected_id := ""
var player_gang_id := 1
var elapsed_time := 0.0
var is_paused := false
var match_over := false
var growth_emit_timer := 0.0

func setup(balance_config: Dictionary, loaded_map_data: Dictionary, loaded_gang_data: Dictionary) -> void:
	balance = balance_config
	map_data = loaded_map_data
	gang_data = loaded_gang_data
	player_gang_id = int(balance.get("player_gang_id", 1))

func start_new_match() -> void:
	_reset_runtime()
	_build_initial_territories()
	_emit_full_state()
	emit_signal("match_status_changed", "GAME_RUNNING")
	emit_signal("gang_count_changed", get_active_gang_count())

func load_from_save(save_data: Dictionary) -> bool:
	if int(save_data.get("version", 0)) != SAVE_VERSION:
		return false
	if String(save_data.get("map_id", "")) != String(map_data.get("map_id", "")):
		return false

	_reset_runtime()
	_build_initial_territories()
	elapsed_time = float(save_data.get("elapsed_time", 0.0))
	player_gang_id = int(save_data.get("player_gang_id", player_gang_id))

	for saved_territory in save_data.get("territories", []):
		var territory_id := String(saved_territory.get("territory_id", ""))
		if not territories.has(territory_id):
			continue
		var territory: Dictionary = territories[territory_id]
		territory["owner_id"] = int(saved_territory.get("owner_id", territory.get("owner_id", 0)))
		territory["population"] = float(saved_territory.get("population", territory.get("population", 0.0)))
		territory["current_state"] = String(saved_territory.get("current_state", territory.get("current_state", "controlled")))
		territories[territory_id] = territory

	_emit_full_state()
	emit_signal("match_status_changed", "GAME_RUNNING")
	emit_signal("gang_count_changed", get_active_gang_count())
	return true

func _process(delta: float) -> void:
	if is_paused or match_over:
		return

	elapsed_time += delta
	_update_growth(delta)
	_update_waves(delta)
	_update_battles(delta)

func set_match_paused(paused: bool) -> void:
	if match_over:
		return
	is_paused = paused
	emit_signal("match_status_changed", "GAME_PAUSED" if paused else "GAME_RUNNING")

func handle_player_territory_pressed(territory_id: String) -> void:
	if is_paused or match_over or not territories.has(territory_id):
		return

	var territory: Dictionary = territories[territory_id]
	var owner_id := int(territory.get("owner_id", 0))

	if selected_id.is_empty():
		if owner_id == player_gang_id and not active_battles.has(territory_id):
			_select_territory(territory_id)
		else:
			emit_signal("match_status_changed", "GAME_SELECT_OWN")
		return

	if territory_id == selected_id:
		_select_territory("")
		return

	if owner_id == player_gang_id and not RulesScript.can_send_to_neighbor(territories[selected_id], territory_id):
		_select_territory(territory_id)
		return

	if request_send(selected_id, territory_id, player_gang_id):
		_select_territory("")

func request_send(source_id: String, target_id: String, owner_id: int) -> bool:
	if is_paused or match_over:
		return false
	if not territories.has(source_id) or not territories.has(target_id):
		return false
	if active_battles.has(source_id) or active_battles.has(target_id):
		emit_signal("match_status_changed", "GAME_TARGET_BUSY")
		return false

	var source: Dictionary = territories[source_id]
	if int(source.get("owner_id", 0)) != owner_id:
		return false
	if not RulesScript.can_send_to_neighbor(source, target_id):
		emit_signal("match_status_changed", "GAME_INVALID_NEIGHBOR")
		return false

	var amount := RulesScript.calculate_send_amount(
		float(source.get("population", 0.0)),
		float(balance.get("send_fraction", 0.5))
	)
	if amount <= 0:
		emit_signal("match_status_changed", "GAME_NOT_ENOUGH_UNITS")
		return false

	source["population"] = maxf(0.0, float(source.get("population", 0.0)) - float(amount))
	source["current_state"] = "sending_units"
	territories[source_id] = source
	emit_signal("territory_changed", source_id, source)

	var source_center := _center_for(source_id)
	var target_center := _center_for(target_id)
	var distance := source_center.distance_to(target_center)
	var speed := maxf(80.0, float(balance.get("unit_movement_speed", 260.0)))
	var duration := clampf(distance / speed, 0.22, 1.2)

	active_waves.append({
		"source_id": source_id,
		"target_id": target_id,
		"owner_id": owner_id,
		"amount": amount,
		"elapsed": 0.0,
		"duration": duration,
		"progress": 0.0
	})

	emit_signal("wave_data_changed", active_waves)
	emit_signal("match_status_changed", "GAME_UNITS_SENT")
	emit_signal("feedback_event", "units_sent", {
		"source_id": source_id,
		"target_id": target_id,
		"owner_id": owner_id,
		"player_gang_id": player_gang_id
	})
	return true

func to_save_dict(ai_state: Dictionary = {}, settings_snapshot: Dictionary = {}) -> Dictionary:
	var saved_territories := []
	for territory_id in territories.keys():
		var territory: Dictionary = territories[territory_id]
		saved_territories.append({
			"territory_id": territory_id,
			"owner_id": int(territory.get("owner_id", 0)),
			"population": float(territory.get("population", 0.0)),
			"current_state": String(territory.get("current_state", "controlled"))
		})

	return {
		"version": SAVE_VERSION,
		"map_id": String(map_data.get("map_id", "")),
		"player_gang_id": player_gang_id,
		"elapsed_time": elapsed_time,
		"territories": saved_territories,
		"ai": ai_state,
		"settings_snapshot": settings_snapshot
	}

func get_owned_territories(owner_id: int) -> Array:
	var owned := []
	for territory_id in territories.keys():
		var territory: Dictionary = territories[territory_id]
		if int(territory.get("owner_id", 0)) == owner_id:
			owned.append(territory)
	owned.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("territory_id", "")) < String(b.get("territory_id", ""))
	)
	return owned

func get_territory(territory_id: String) -> Dictionary:
	return territories.get(territory_id, {})

func is_territory_in_battle(territory_id: String) -> bool:
	return active_battles.has(territory_id)

func get_active_gang_count() -> int:
	var active := {}
	for territory in territories.values():
		var owner_id := int(territory.get("owner_id", 0))
		if owner_id > 0:
			active[owner_id] = true
	return active.size()

func get_player_gang_id() -> int:
	return player_gang_id

func get_debug_summary() -> Dictionary:
	var state := "paused" if is_paused else "running"
	if match_over:
		state = "ended"
	return {
		"territories": territories.size(),
		"waves": active_waves.size(),
		"battles": active_battles.size(),
		"state": state
	}

func _reset_runtime() -> void:
	territories.clear()
	active_waves.clear()
	active_battles.clear()
	selected_id = ""
	elapsed_time = 0.0
	is_paused = false
	match_over = false
	growth_emit_timer = 0.0
	emit_signal("selection_changed", "")
	emit_signal("wave_data_changed", active_waves)
	emit_signal("battle_data_changed", active_battles)

func _build_initial_territories() -> void:
	for source_territory in map_data.get("territories", []):
		var territory: Dictionary = source_territory.duplicate(true)
		var owner_id := int(territory.get("owner_id", 0))
		territory["owner_id"] = owner_id
		territory["population"] = float(territory.get("population", 0.0))
		territory["maximum_population"] = float(territory.get("maximum_population", 50.0))
		territory["growth_rate"] = float(territory.get("growth_rate", 1.0))
		territory["defense_modifier"] = float(territory.get("defense_modifier", 1.0))
		territory["current_state"] = "controlled" if owner_id > 0 else "neutral"
		territories[String(territory.get("territory_id", ""))] = territory

func _emit_full_state() -> void:
	for territory_id in territories.keys():
		emit_signal("territory_changed", territory_id, territories[territory_id])
	emit_signal("selection_changed", selected_id)
	emit_signal("wave_data_changed", active_waves)
	emit_signal("battle_data_changed", active_battles)

func _select_territory(territory_id: String) -> void:
	selected_id = territory_id
	emit_signal("selection_changed", selected_id)
	if selected_id.is_empty():
		emit_signal("match_status_changed", "GAME_SELECT_OWN")
	else:
		emit_signal("match_status_changed", "GAME_SELECT_TARGET")
		emit_signal("feedback_event", "territory_selected", {
			"territory_id": selected_id,
			"owner_id": player_gang_id,
			"player_gang_id": player_gang_id
		})

func _update_growth(delta: float) -> void:
	growth_emit_timer += delta
	var should_emit := growth_emit_timer >= float(balance.get("growth_emit_interval", 0.15))
	if should_emit:
		growth_emit_timer = 0.0

	for territory_id in territories.keys():
		if active_battles.has(territory_id):
			continue

		var territory: Dictionary = territories[territory_id]
		if int(territory.get("owner_id", 0)) <= 0:
			continue

		var population := float(territory.get("population", 0.0))
		var maximum := float(territory.get("maximum_population", 50.0))
		var growth := float(territory.get("growth_rate", 0.0))
		var next_population := minf(maximum, population + growth * delta)
		if is_equal_approx(next_population, population):
			continue

		territory["population"] = next_population
		if String(territory.get("current_state", "")) == "sending_units":
			territory["current_state"] = "controlled"
		territories[territory_id] = territory

		if should_emit:
			emit_signal("territory_changed", territory_id, territory)

func _update_waves(delta: float) -> void:
	if active_waves.is_empty():
		return

	var remaining := []
	var arrived := []
	for wave in active_waves:
		var updated: Dictionary = wave
		updated["elapsed"] = float(updated.get("elapsed", 0.0)) + delta
		var duration := maxf(0.01, float(updated.get("duration", 0.01)))
		updated["progress"] = clampf(float(updated.get("elapsed", 0.0)) / duration, 0.0, 1.0)
		if float(updated.get("progress", 0.0)) >= 1.0:
			arrived.append(updated)
		else:
			remaining.append(updated)

	active_waves = remaining
	emit_signal("wave_data_changed", active_waves)

	for wave in arrived:
		_finish_wave(wave)

func _finish_wave(wave: Dictionary) -> void:
	var target_id := String(wave.get("target_id", ""))
	if not territories.has(target_id):
		return

	var owner_id := int(wave.get("owner_id", 0))
	var amount := int(wave.get("amount", 0))
	var target: Dictionary = territories[target_id]
	var target_owner := int(target.get("owner_id", 0))

	if target_owner == owner_id:
		target["population"] = minf(
			float(target.get("maximum_population", 50.0)),
			float(target.get("population", 0.0)) + float(amount)
		)
		target["current_state"] = "controlled"
		territories[target_id] = target
		emit_signal("territory_changed", target_id, target)
		return

	_start_battle(target_id, owner_id, amount)

func _start_battle(target_id: String, attacker_owner_id: int, attacker_units: int) -> void:
	if active_battles.has(target_id):
		return

	var target: Dictionary = territories[target_id]
	var defender_owner_id := int(target.get("owner_id", 0))
	var defender_population := float(target.get("population", 0.0))
	var result := RulesScript.resolve_battle(
		attacker_units,
		defender_population,
		float(balance.get("defense_multiplier", 1.0)),
		float(target.get("defense_modifier", 1.0))
	)

	var total_units := float(attacker_units) + defender_population
	var duration := clampf(
		float(balance.get("battle_min_duration", 0.6)) + total_units * float(balance.get("battle_duration_per_unit", 0.009)),
		float(balance.get("battle_min_duration", 0.6)),
		float(balance.get("battle_max_duration", 1.8))
	)

	var battle := {
		"target_id": target_id,
		"attacker_owner_id": attacker_owner_id,
		"defender_owner_id": defender_owner_id,
		"attacker_units": attacker_units,
		"defender_population": defender_population,
		"attacker_display": attacker_units,
		"defender_display": int(round(defender_population)),
		"dominance": float(attacker_units) / maxf(1.0, float(attacker_units) + defender_population),
		"elapsed": 0.0,
		"duration": duration,
		"result": result
	}

	target["current_state"] = "under_attack"
	territories[target_id] = target
	active_battles[target_id] = battle

	emit_signal("territory_changed", target_id, target)
	emit_signal("battle_data_changed", active_battles)
	emit_signal("feedback_event", "battle_started", {
		"target_id": target_id,
		"owner_id": attacker_owner_id,
		"player_gang_id": player_gang_id
	})

func _update_battles(delta: float) -> void:
	if active_battles.is_empty():
		return

	var finished := []
	for target_id in active_battles.keys():
		var battle: Dictionary = active_battles[target_id]
		battle["elapsed"] = float(battle.get("elapsed", 0.0)) + delta
		var duration := maxf(0.01, float(battle.get("duration", 0.01)))
		var progress := clampf(float(battle.get("elapsed", 0.0)) / duration, 0.0, 1.0)
		var result: Dictionary = battle.get("result", {})

		var attacker_start := float(battle.get("attacker_units", 0))
		var defender_start := float(battle.get("defender_population", 0.0))
		var attacker_current := 0.0
		var defender_current := 0.0

		if bool(result.get("attacker_wins", false)):
			attacker_current = lerpf(attacker_start, float(result.get("remaining_population", 1)), progress)
			defender_current = lerpf(defender_start, 0.0, progress)
		else:
			attacker_current = lerpf(attacker_start, 0.0, progress)
			defender_current = lerpf(defender_start, float(result.get("remaining_population", 1)), progress)

		battle["attacker_display"] = maxi(0, int(round(attacker_current)))
		battle["defender_display"] = maxi(0, int(round(defender_current)))
		battle["dominance"] = attacker_current / maxf(1.0, attacker_current + defender_current)
		active_battles[target_id] = battle

		var territory: Dictionary = territories[target_id]
		territory["population"] = maxf(0.0, defender_current)
		territories[target_id] = territory
		emit_signal("territory_changed", target_id, territory)

		if progress >= 1.0:
			finished.append(target_id)

	emit_signal("battle_data_changed", active_battles)

	for target_id in finished:
		_finish_battle(target_id)

func _finish_battle(target_id: String) -> void:
	if not active_battles.has(target_id) or not territories.has(target_id):
		return

	var battle: Dictionary = active_battles[target_id]
	var result: Dictionary = battle.get("result", {})
	var target: Dictionary = territories[target_id]
	var old_owner := int(target.get("owner_id", 0))
	var attacker_owner := int(battle.get("attacker_owner_id", 0))

	if bool(result.get("attacker_wins", false)):
		target["owner_id"] = attacker_owner
		target["population"] = float(result.get("remaining_population", 1))
		target["current_state"] = "captured"
		territories[target_id] = target
		emit_signal("territory_changed", target_id, target)
		emit_signal("feedback_event", "territory_captured", {
			"target_id": target_id,
			"owner_id": attacker_owner,
			"player_gang_id": player_gang_id
		})

		if attacker_owner == player_gang_id:
			emit_signal("match_status_changed", "GAME_CAPTURED")
		elif old_owner == player_gang_id:
			emit_signal("match_status_changed", "GAME_LOST_TERRITORY")
			emit_signal("feedback_event", "territory_lost", {
				"target_id": target_id,
				"owner_id": attacker_owner,
				"player_gang_id": player_gang_id
			})
	else:
		target["population"] = float(result.get("remaining_population", 1))
		target["current_state"] = "controlled" if int(target.get("owner_id", 0)) > 0 else "neutral"
		territories[target_id] = target
		emit_signal("territory_changed", target_id, target)

	active_battles.erase(target_id)
	emit_signal("battle_data_changed", active_battles)
	emit_signal("feedback_event", "battle_finished", {
		"target_id": target_id,
		"owner_id": int(target.get("owner_id", 0)),
		"player_gang_id": player_gang_id
	})
	emit_signal("gang_count_changed", get_active_gang_count())
	_check_end_conditions()

func _check_end_conditions() -> void:
	if match_over:
		return

	var player_count := 0
	var non_player_count := 0
	for territory in territories.values():
		var owner_id := int(territory.get("owner_id", 0))
		if owner_id == player_gang_id:
			player_count += 1
		else:
			non_player_count += 1

	if player_count <= 0:
		_end_match("GAME_DEFEAT", "defeat")
	elif non_player_count <= 0:
		_end_match("GAME_VICTORY", "victory")

func _end_match(result_key: String, feedback_name: String) -> void:
	match_over = true
	is_paused = true
	emit_signal("match_ended", result_key)
	emit_signal("feedback_event", feedback_name, {
		"player_gang_id": player_gang_id
	})

func _center_for(territory_id: String) -> Vector2:
	if not territories.has(territory_id):
		return Vector2.ZERO
	var raw: Variant = territories[territory_id].get("center_position", [0, 0])
	if raw is Array and raw.size() >= 2:
		return Vector2(float(raw[0]), float(raw[1]))
	return Vector2.ZERO
