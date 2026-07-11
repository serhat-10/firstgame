extends RefCounted
class_name LocalizationManager

const FALLBACK_LANGUAGE := "en"

var current_language := FALLBACK_LANGUAGE
var dictionary: Dictionary = {}

func load_language(language_code: String) -> void:
	current_language = language_code
	dictionary = DataLoader.load_json_file("res://data/localization/%s.json" % FALLBACK_LANGUAGE)

	if language_code != FALLBACK_LANGUAGE:
		var localized := DataLoader.load_json_file("res://data/localization/%s.json" % language_code)
		dictionary.merge(localized, true)

func translate(key: String) -> String:
	if key.is_empty():
		return ""
	return String(dictionary.get(key, key))

