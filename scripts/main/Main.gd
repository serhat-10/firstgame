extends Control

const SettingsManagerScript := preload("res://scripts/core/SettingsManager.gd")
const LocalizationManagerScript := preload("res://scripts/core/LocalizationManager.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const MainMenuScript := preload("res://scripts/ui/MainMenu.gd")
const GameScreenScript := preload("res://scripts/main/GameScreen.gd")

var settings_manager: SettingsManager
var localization_manager: LocalizationManager
var save_manager: SaveManager
var current_screen: Node
var current_game: GameScreen

func _ready() -> void:
	settings_manager = SettingsManagerScript.new()
	settings_manager.load_settings()

	localization_manager = LocalizationManagerScript.new()
	localization_manager.load_language(settings_manager.language)

	save_manager = SaveManagerScript.new()
	show_main_menu()

func show_main_menu(message_key: String = "") -> void:
	_clear_screen()
	current_game = null

	var menu := MainMenuScript.new()
	add_child(menu)
	current_screen = menu
	menu.setup(localization_manager, settings_manager, save_manager, message_key)
	menu.new_game_requested.connect(_on_new_game_requested)
	menu.continue_requested.connect(_on_continue_requested)
	menu.settings_changed.connect(_on_settings_changed)

func _on_new_game_requested() -> void:
	_start_game({})

func _on_continue_requested() -> void:
	var save_data := save_manager.load_match()
	if save_data.is_empty():
		show_main_menu("MENU_SAVE_LOAD_FAILED")
		return
	_start_game(save_data)

func _start_game(save_data: Dictionary) -> void:
	_clear_screen()

	var game := GameScreenScript.new()
	game.setup(settings_manager, localization_manager, save_manager)
	game.exit_to_menu_requested.connect(show_main_menu)
	add_child(game)
	current_screen = game
	current_game = game

	var loaded := false
	if save_data.is_empty():
		game.start_new_match()
		loaded = true
	else:
		loaded = game.start_from_save(save_data)

	if not loaded:
		show_main_menu("MENU_SAVE_LOAD_FAILED")

func _on_settings_changed() -> void:
	localization_manager.load_language(settings_manager.language)
	show_main_menu()

func _clear_screen() -> void:
	if current_screen != null:
		current_screen.queue_free()
	current_screen = null

func _notification(what: int) -> void:
	if current_game == null:
		return

	if what == NOTIFICATION_APPLICATION_PAUSED \
		or what == NOTIFICATION_APPLICATION_FOCUS_OUT \
		or what == NOTIFICATION_WM_CLOSE_REQUEST:
		current_game.pause_for_lifecycle()

