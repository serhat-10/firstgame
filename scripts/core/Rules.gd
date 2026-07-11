extends RefCounted
class_name Rules

static func calculate_send_amount(population: float, send_fraction: float) -> int:
	var whole_population := int(floor(maxf(0.0, population)))
	if whole_population <= 0:
		return 0

	var safe_fraction := clampf(send_fraction, 0.0, 1.0)
	var requested := int(floor(float(whole_population) * safe_fraction))
	if requested <= 0:
		requested = 1

	return mini(requested, whole_population)

static func resolve_battle(
	attacker_units: int,
	defender_population: float,
	defense_multiplier: float,
	territory_defense_modifier: float
) -> Dictionary:
	var safe_attack := maxf(0.0, float(attacker_units))
	var safe_defense_multiplier := maxf(0.01, defense_multiplier)
	var safe_territory_modifier := maxf(0.01, territory_defense_modifier)
	var combined_defense := safe_defense_multiplier * safe_territory_modifier
	var defense_power := maxf(0.0, defender_population) * combined_defense

	if safe_attack > defense_power:
		return {
			"attacker_wins": true,
			"remaining_population": maxi(1, int(round(safe_attack - defense_power))),
			"defense_power": defense_power
		}

	var remaining_defense_power := defense_power - safe_attack
	return {
		"attacker_wins": false,
		"remaining_population": maxi(1, int(round(remaining_defense_power / combined_defense))),
		"defense_power": defense_power
	}

static func can_send_to_neighbor(source: Dictionary, target_id: String) -> bool:
	var neighbors: Array = source.get("neighbor_ids", [])
	return neighbors.has(target_id)

