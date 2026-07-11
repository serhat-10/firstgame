extends RefCounted
class_name SettingsManager

const SETTINGS_PATH := "user://settings.cfg"
const SUPPORTED_LANGUAGES := ["en", "tr"]

var sound_enabled := true
var haptics_enabled := true
var language := "en"
var tutorial_completed := false

func load_settings() -> void:
	language = _detect_language()

	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)
	if error != OK:
		return

	sound_enabled = bool(config.get_value("audio", "sound_enabled", true))
	haptics_enabled = bool(config.get_value("haptics", "haptics_enabled", true))
	language = String(config.get_value("localization", "language", language))
	tutorial_completed = bool(config.get_value("tutorial", "completed", false))

	if not SUPPORTED_LANGUAGES.has(language):
		language = "en"

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "sound_enabled", sound_enabled)
	config.set_value("haptics", "haptics_enabled", haptics_enabled)
	config.set_value("localization", "language", language)
	config.set_value("tutorial", "completed", tutorial_completed)
	config.save(SETTINGS_PATH)

func set_language(new_language: String) -> void:
	if not SUPPORTED_LANGUAGES.has(new_language):
		new_language = "en"
	language = new_language
	save_settings()

func to_dict() -> Dictionary:
	return {
		"sound_enabled": sound_enabled,
		"haptics_enabled": haptics_enabled,
		"language": language,
		"tutorial_completed": tutorial_completed
	}

func apply_snapshot(snapshot: Dictionary) -> void:
	sound_enabled = bool(snapshot.get("sound_enabled", sound_enabled))
	haptics_enabled = bool(snapshot.get("haptics_enabled", haptics_enabled))
	language = String(snapshot.get("language", language))
	tutorial_completed = bool(snapshot.get("tutorial_completed", tutorial_completed))
	if not SUPPORTED_LANGUAGES.has(language):
		language = "en"
	save_settings()

func _detect_language() -> String:
	var device_language := OS.get_locale_language()
	if SUPPORTED_LANGUAGES.has(device_language):
		return device_language
	return "en"

