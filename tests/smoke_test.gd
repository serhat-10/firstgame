extends SceneTree

const RulesScript := preload("res://scripts/core/Rules.gd")

func _init() -> void:
	var failures := 0
	failures += _assert(RulesScript.calculate_send_amount(34.0, 0.5) == 17, "50 percent send failed")
	failures += _assert(RulesScript.calculate_send_amount(1.0, 0.5) == 1, "minimum non-zero send failed")
	failures += _assert(RulesScript.calculate_send_amount(0.0, 0.5) == 0, "zero population send failed")

	var win := RulesScript.resolve_battle(100, 70.0, 1.0, 1.0)
	failures += _assert(bool(win.get("attacker_wins", false)), "attacker should win 100 vs 70")
	failures += _assert(int(win.get("remaining_population", 0)) == 30, "attacker remaining population mismatch")

	var loss := RulesScript.resolve_battle(30, 70.0, 1.0, 1.0)
	failures += _assert(not bool(loss.get("attacker_wins", true)), "defender should win 30 vs 70")
	failures += _assert(int(loss.get("remaining_population", 0)) == 40, "defender remaining population mismatch")

	var map_exists := FileAccess.file_exists("res://data/maps/first_playable.json")
	var balance_exists := FileAccess.file_exists("res://data/balance/balance.json")
	failures += _assert(map_exists, "map data missing")
	failures += _assert(balance_exists, "balance data missing")

	if failures == 0:
		print("Smoke test passed.")
	else:
		printerr("Smoke test failed: %d failure(s)." % failures)
	quit(failures)

func _assert(condition: bool, message: String) -> int:
	if condition:
		return 0
	printerr(message)
	return 1

