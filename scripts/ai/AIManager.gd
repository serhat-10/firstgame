extends Node
class_name AIManager

const RulesScript := preload("res://scripts/core/Rules.gd")

var match_manager: MatchManager
var balance: Dictionary = {}
var gangs: Array = []
var timers: Dictionary = {}

func setup(manager: MatchManager, balance_config: Dictionary, gang_data: Dictionary) -> void:
	match_manager = manager
	balance = balance_config
	gangs = []
	timers.clear()

	for gang in gang_data.get("gangs", []):
		if bool(gang.get("is_ai", false)):
			var copy: Dictionary = gang.duplicate(true)
			gangs.append(copy)
			var gang_id := int(copy.get("id", 0))
			timers[gang_id] = _interval_for_profile(String(copy.get("profile", "aggressive")))

func load_state(ai_state: Dictionary) -> void:
	for key in ai_state.get("timers", {}).keys():
		timers[int(key)] = float(ai_state["timers"][key])

func to_save_dict() -> Dictionary:
	var saved_timers := {}
	for key in timers.keys():
		saved_timers[str(key)] = float(timers[key])
	return {
		"timers": saved_timers
	}

func _process(delta: float) -> void:
	if match_manager == null or match_manager.is_paused or match_manager.match_over:
		return

	for gang in gangs:
		var gang_id := int(gang.get("id", 0))
		if match_manager.get_owned_territories(gang_id).is_empty():
			continue

		timers[gang_id] = float(timers.get(gang_id, 0.0)) - delta
		if float(timers[gang_id]) <= 0.0:
			_try_take_action(gang)
			timers[gang_id] = _interval_for_profile(String(gang.get("profile", "aggressive")))

func _try_take_action(gang: Dictionary) -> void:
	var gang_id := int(gang.get("id", 0))
	var profile := String(gang.get("profile", "aggressive"))
	var best_action := _choose_action(gang_id, profile)
	if best_action.is_empty():
		return

	match_manager.request_send(
		String(best_action.get("source_id", "")),
		String(best_action.get("target_id", "")),
		gang_id,
		float(balance.get("send_fraction", 0.5))
	)

func _choose_action(gang_id: int, profile: String) -> Dictionary:
	var best_action := {}
	var best_score := -INF
	var owned := match_manager.get_owned_territories(gang_id)
	var min_population := float(balance.get("ai_min_send_population", 12))

	for source in owned:
		var source_id := String(source.get("territory_id", ""))
		var source_population := float(source.get("population", 0.0))
		if source_population < min_population or match_manager.is_territory_in_battle(source_id):
			continue

		var send_amount := RulesScript.calculate_send_amount(source_population, float(balance.get("send_fraction", 0.5)))
		if send_amount <= 0:
			continue

		for raw_neighbor_id in source.get("neighbor_ids", []):
			var target_id := String(raw_neighbor_id)
			if match_manager.is_territory_in_battle(target_id):
				continue

			var target := match_manager.get_territory(target_id)
			if target.is_empty() or int(target.get("owner_id", 0)) == gang_id:
				continue
			if int(target.get("owner_id", 0)) == match_manager.get_player_gang_id() \
				and match_manager.elapsed_time < float(balance.get("ai_player_grace_seconds", 12.0)):
				continue

			var score := _score_target(source, target, send_amount, profile)
			if score > best_score:
				best_score = score
				best_action = {
					"source_id": source_id,
					"target_id": target_id,
					"score": score
				}

	return best_action

func _score_target(source: Dictionary, target: Dictionary, send_amount: int, profile: String) -> float:
	var target_population := maxf(1.0, float(target.get("population", 0.0)))
	var target_defense := target_population \
		* float(balance.get("defense_multiplier", 1.0)) \
		* float(target.get("defense_modifier", 1.0))
	var advantage := float(send_amount) / maxf(1.0, target_defense)
	var min_advantage := _min_advantage_for_profile(profile)
	if advantage < min_advantage:
		return -INF

	var strategic_value := float(target.get("strategic_value", 1.0))
	var neutral_bonus := 2.0 if int(target.get("owner_id", 0)) == 0 else 0.0
	var pressure := float(_count_adjacent_enemies(source, int(source.get("owner_id", 0))))
	var risk_after_send := maxf(0.0, 1.0 - ((float(source.get("population", 0.0)) - float(send_amount)) / maxf(1.0, float(source.get("maximum_population", 50.0)))))
	var profile_bias := _profile_bias(profile, target, advantage)

	return advantage * 10.0 + strategic_value * 2.0 + neutral_bonus + profile_bias - pressure * 0.75 - risk_after_send * 2.0

func _count_adjacent_enemies(source: Dictionary, owner_id: int) -> int:
	var count := 0
	for raw_neighbor_id in source.get("neighbor_ids", []):
		var neighbor := match_manager.get_territory(String(raw_neighbor_id))
		if neighbor.is_empty():
			continue
		var neighbor_owner := int(neighbor.get("owner_id", 0))
		if neighbor_owner != 0 and neighbor_owner != owner_id:
			count += 1
	return count

func _interval_for_profile(profile: String) -> float:
	var base := float(balance.get("ai_action_interval", 2.2))
	match profile:
		"aggressive":
			return base * 0.75
		"defensive":
			return base * 1.45
		"opportunistic":
			return base * 1.05
		_:
			return base

func _min_advantage_for_profile(profile: String) -> float:
	match profile:
		"aggressive":
			return 0.85
		"defensive":
			return 1.35
		"opportunistic":
			return 1.05
		_:
			return 1.0

func _profile_bias(profile: String, target: Dictionary, advantage: float) -> float:
	match profile:
		"aggressive":
			return (1.0 - minf(1.0, float(target.get("population", 0.0)) / 50.0)) * 3.0
		"defensive":
			return advantage * 0.6
		"opportunistic":
			return float(target.get("strategic_value", 1.0)) * 1.5
		_:
			return 0.0
