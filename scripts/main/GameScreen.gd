extends Control
class_name GameScreen

signal exit_to_menu_requested(message_key: String)

const DataLoaderScript := preload("res://scripts/core/DataLoader.gd")
const MatchManagerScript := preload("res://scripts/gameplay/MatchManager.gd")
const MapViewScript := preload("res://scripts/gameplay/MapView.gd")
const AIManagerScript := preload("res://scripts/ai/AIManager.gd")
const HUDScript := preload("res://scripts/ui/HUD.gd")
const AudioManagerScript := preload("res://scripts/audio/AudioManager.gd")
const TutorialManagerScript := preload("res://scripts/gameplay/TutorialManager.gd")
const DebugOverlayScript := preload("res://scripts/ui/DebugOverlay.gd")

var settings: SettingsManager
var localization: LocalizationManager
var save_manager: SaveManager
var balance: Dictionary = {}
var map_data: Dictionary = {}
var gang_data: Dictionary = {}
var map_view: MapView
var match_manager: MatchManager
var ai_manager: AIManager
var hud: HUD
var audio_manager: AudioManager
var tutorial_manager: TutorialManager
var debug_overlay: DebugOverlay
var autosave_timer := 0.0
var current_selected_id := ""

func setup(
	settings_manager: SettingsManager,
	localization_manager: LocalizationManager,
	match_save_manager: SaveManager
) -> void:
	settings = settings_manager
	localization = localization_manager
	save_manager = match_save_manager

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load_data()
	_build_scene()
	_connect_signals()

func start_new_match() -> void:
	match_manager.start_new_match()
	ai_manager.setup(match_manager, balance, gang_data)
	tutorial_manager.start()
	_save_now()

func start_from_save(save_data: Dictionary) -> bool:
	if save_data.has("settings_snapshot") and save_data["settings_snapshot"] is Dictionary:
		settings.apply_snapshot(save_data["settings_snapshot"])
		localization.load_language(settings.language)

	var loaded := match_manager.load_from_save(save_data)
	if not loaded:
		return false

	ai_manager.setup(match_manager, balance, gang_data)
	if save_data.has("ai") and save_data["ai"] is Dictionary:
		ai_manager.load_state(save_data["ai"])
	tutorial_manager.start()
	return true

func pause_for_lifecycle() -> void:
	if match_manager == null:
		return
	match_manager.set_match_paused(true)
	hud.show_pause_menu(true)
	_save_now()

func _process(delta: float) -> void:
	if match_manager == null:
		return

	debug_overlay.update_state(match_manager)

	if match_manager.match_over:
		return

	autosave_timer += delta
	if autosave_timer >= float(balance.get("autosave_interval", 5.0)):
		autosave_timer = 0.0
		_save_now()

func _load_data() -> void:
	balance = DataLoaderScript.load_json_file("res://data/balance/balance.json")
	map_data = DataLoaderScript.load_json_file("res://data/maps/first_playable.json")
	gang_data = DataLoaderScript.load_json_file("res://data/gangs/gangs.json")

func _build_scene() -> void:
	var background := ColorRect.new()
	background.color = Color(0.05, 0.06, 0.08)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	map_view = MapViewScript.new()
	add_child(map_view)
	map_view.setup(map_data, gang_data, localization)

	match_manager = MatchManagerScript.new()
	add_child(match_manager)
	match_manager.setup(balance, map_data, gang_data)

	ai_manager = AIManagerScript.new()
	add_child(ai_manager)

	audio_manager = AudioManagerScript.new()
	audio_manager.setup(settings)
	add_child(audio_manager)

	hud = HUDScript.new()
	add_child(hud)
	hud.setup(localization)
	_configure_player_identity()

	tutorial_manager = TutorialManagerScript.new()
	tutorial_manager.setup(settings)
	add_child(tutorial_manager)

	debug_overlay = DebugOverlayScript.new()
	add_child(debug_overlay)

func _connect_signals() -> void:
	map_view.territory_pressed.connect(match_manager.handle_player_territory_pressed)

	match_manager.territory_changed.connect(_on_territory_changed)
	match_manager.selection_changed.connect(_on_selection_changed)
	match_manager.selection_changed.connect(map_view.set_selected)
	match_manager.targeting_changed.connect(map_view.set_targeting)
	match_manager.wave_data_changed.connect(map_view.set_waves)
	match_manager.battle_data_changed.connect(map_view.set_battles)
	match_manager.match_status_changed.connect(hud.set_status_key)
	match_manager.gang_count_changed.connect(hud.set_gang_count)
	match_manager.player_influence_changed.connect(hud.set_player_influence)
	match_manager.send_fraction_changed.connect(hud.set_send_fraction)
	match_manager.match_ended.connect(_on_match_ended)
	match_manager.feedback_event.connect(_on_feedback_event)

	hud.pause_pressed.connect(_on_pause_pressed)
	hud.resume_pressed.connect(_on_resume_pressed)
	hud.restart_pressed.connect(_on_restart_pressed)
	hud.menu_pressed.connect(_on_menu_pressed)
	hud.skip_tutorial_pressed.connect(tutorial_manager.skip)
	hud.send_fraction_selected.connect(match_manager.set_send_fraction)

	tutorial_manager.prompt_changed.connect(hud.set_tutorial_key)

func _on_territory_changed(territory_id: String, territory: Dictionary) -> void:
	map_view.update_territory(territory_id, territory)
	if territory_id == current_selected_id:
		_update_selected_info(territory)

func _on_selection_changed(territory_id: String) -> void:
	current_selected_id = territory_id
	if current_selected_id.is_empty():
		hud.set_selection_info("", 0, false)
		return

	var territory := match_manager.get_territory(current_selected_id)
	_update_selected_info(territory)

func _update_selected_info(territory: Dictionary) -> void:
	if territory.is_empty():
		hud.set_selection_info("", 0, false)
		return

	var name_key := String(territory.get("display_name_key", ""))
	hud.set_selection_info(
		localization.translate(name_key),
		int(round(float(territory.get("population", 0.0)))),
		true
	)

func _on_pause_pressed() -> void:
	audio_manager.play_event("button_tap")
	match_manager.set_match_paused(true)
	hud.show_pause_menu(true)
	_save_now()

func _on_resume_pressed() -> void:
	audio_manager.play_event("button_tap")
	match_manager.set_match_paused(false)
	hud.show_pause_menu(false)

func _on_restart_pressed() -> void:
	audio_manager.play_event("button_tap")
	match_manager.start_new_match()
	ai_manager.setup(match_manager, balance, gang_data)
	hud.show_pause_menu(false)
	tutorial_manager.start()
	_save_now()

func _on_menu_pressed() -> void:
	audio_manager.play_event("button_tap")
	_save_now()
	emit_signal("exit_to_menu_requested", "")

func _on_match_ended(result_key: String) -> void:
	hud.show_result(result_key)
	_save_now()

func _on_feedback_event(event_name: String, payload: Dictionary) -> void:
	tutorial_manager.observe_event(event_name, payload)

	var owner_id := int(payload.get("owner_id", match_manager.get_player_gang_id()))
	var is_player_event := owner_id == match_manager.get_player_gang_id()
	if is_player_event or event_name == "victory" or event_name == "defeat" or event_name == "territory_lost":
		audio_manager.play_event(event_name)
		_play_haptic(event_name)

	if event_name == "territory_captured" or event_name == "territory_lost" or event_name == "victory" or event_name == "defeat":
		_save_now()

func _save_now() -> void:
	if match_manager == null or save_manager == null:
		return
	save_manager.save_match(match_manager.to_save_dict(ai_manager.to_save_dict(), settings.to_dict()))

func _play_haptic(event_name: String) -> void:
	if settings == null or not settings.haptics_enabled:
		return

	match event_name:
		"units_sent":
			Input.vibrate_handheld(35)
		"territory_captured":
			Input.vibrate_handheld(70)
		"territory_lost":
			Input.vibrate_handheld(90)
		"victory":
			Input.vibrate_handheld(120)
		_:
			pass

func _configure_player_identity() -> void:
	var player_id := int(balance.get("player_gang_id", 1))
	for gang in gang_data.get("gangs", []):
		if int(gang.get("id", 0)) == player_id:
			hud.set_player_identity(
				String(gang.get("emblem", "AZ")),
				Color.html(String(gang.get("color", "#29D7FF")))
			)
			return
