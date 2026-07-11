extends RefCounted
class_name SaveManager

const MATCH_SAVE_PATH := "user://match_save.json"
const SAVE_VERSION := 1

func has_match_save() -> bool:
	return FileAccess.file_exists(MATCH_SAVE_PATH)

func save_match(data: Dictionary) -> bool:
	var save_data := data.duplicate(true)
	save_data["version"] = SAVE_VERSION
	save_data["saved_at_unix"] = Time.get_unix_time_from_system()

	var file := FileAccess.open(MATCH_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write match save.")
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	return true

func load_match() -> Dictionary:
	if not has_match_save():
		return {}

	var file := FileAccess.open(MATCH_SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open match save.")
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Match save is not valid JSON.")
		return {}

	var data: Dictionary = parsed
	if int(data.get("version", 0)) != SAVE_VERSION:
		push_error("Unsupported save version: %s" % str(data.get("version", "missing")))
		return {}

	return data

func clear_match() -> void:
	if FileAccess.file_exists(MATCH_SAVE_PATH):
		var directory := DirAccess.open("user://")
		if directory != null:
			directory.remove("match_save.json")
