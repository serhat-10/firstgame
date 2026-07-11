extends Node
class_name TutorialManager

signal prompt_changed(key: String, skippable: bool)

var settings: SettingsManager
var step := 0
var active := false

func setup(settings_manager: SettingsManager) -> void:
	settings = settings_manager

func start() -> void:
	if settings == null or settings.tutorial_completed:
		active = false
		emit_signal("prompt_changed", "", false)
		return

	active = true
	step = 0
	emit_signal("prompt_changed", "TUTORIAL_SELECT_TERRITORY", true)

func observe_event(event_name: String, payload: Dictionary) -> void:
	if not active:
		return

	if event_name == "territory_selected" and step == 0:
		step = 1
		emit_signal("prompt_changed", "TUTORIAL_SELECT_TARGET", true)
	elif event_name == "units_sent" and step <= 1 and int(payload.get("owner_id", 0)) == int(payload.get("player_gang_id", 1)):
		step = 2
		emit_signal("prompt_changed", "TUTORIAL_UNITS_MOVING", true)
	elif event_name == "battle_started" and step <= 2:
		step = 3
		emit_signal("prompt_changed", "TUTORIAL_BATTLE", true)
	elif (event_name == "territory_captured" or event_name == "battle_finished") \
		and step <= 3 \
		and int(payload.get("owner_id", 0)) == int(payload.get("player_gang_id", 1)):
		step = 4
		emit_signal("prompt_changed", "TUTORIAL_GROWTH", true)
		var timer := get_tree().create_timer(2.0)
		timer.timeout.connect(complete)

func skip() -> void:
	complete()

func complete() -> void:
	if settings != null:
		settings.tutorial_completed = true
		settings.save_settings()
	active = false
	emit_signal("prompt_changed", "", false)
