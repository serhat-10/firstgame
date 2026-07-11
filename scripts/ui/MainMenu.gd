extends Control
class_name MainMenu

signal new_game_requested
signal continue_requested
signal settings_changed

var localization: LocalizationManager
var settings: SettingsManager
var save_manager: SaveManager
var message_key := ""
var settings_panel: PanelContainer

func setup(
	localization_manager: LocalizationManager,
	settings_manager: SettingsManager,
	match_save_manager: SaveManager,
	optional_message_key: String = ""
) -> void:
	localization = localization_manager
	settings = settings_manager
	save_manager = match_save_manager
	message_key = optional_message_key
	_build()

func _build() -> void:
	for child in get_children():
		child.queue_free()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color(0.05, 0.06, 0.08)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 34)
	add_child(margin)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var title := Label.new()
	title.text = localization.translate("APP_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	column.add_child(title)

	if not message_key.is_empty():
		var message := Label.new()
		message.text = localization.translate(message_key)
		message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		message.add_theme_color_override("font_color", Color(1.0, 0.78, 0.45))
		column.add_child(message)

	var new_game_button := _make_button("MENU_NEW_GAME")
	new_game_button.pressed.connect(func() -> void:
		emit_signal("new_game_requested")
	)
	column.add_child(new_game_button)

	var continue_button := _make_button("MENU_CONTINUE")
	continue_button.disabled = not save_manager.has_match_save()
	continue_button.pressed.connect(func() -> void:
		emit_signal("continue_requested")
	)
	column.add_child(continue_button)

	var settings_button := _make_button("MENU_SETTINGS")
	settings_button.pressed.connect(func() -> void:
		settings_panel.visible = not settings_panel.visible
	)
	column.add_child(settings_button)

	settings_panel = _build_settings_panel()
	settings_panel.visible = false
	column.add_child(settings_panel)

func _make_button(key: String) -> Button:
	var button := Button.new()
	button.text = localization.translate(key)
	button.custom_minimum_size = Vector2(220, 48)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return button

func _build_settings_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var sound_toggle := CheckButton.new()
	sound_toggle.text = localization.translate("SETTINGS_SOUND")
	sound_toggle.button_pressed = settings.sound_enabled
	sound_toggle.toggled.connect(func(enabled: bool) -> void:
		settings.sound_enabled = enabled
		settings.save_settings()
	)
	box.add_child(sound_toggle)

	var haptics_toggle := CheckButton.new()
	haptics_toggle.text = localization.translate("SETTINGS_HAPTICS")
	haptics_toggle.button_pressed = settings.haptics_enabled
	haptics_toggle.toggled.connect(func(enabled: bool) -> void:
		settings.haptics_enabled = enabled
		settings.save_settings()
	)
	box.add_child(haptics_toggle)

	var language_label := Label.new()
	language_label.text = localization.translate("SETTINGS_LANGUAGE")
	box.add_child(language_label)

	var language_option := OptionButton.new()
	language_option.add_item(localization.translate("LANGUAGE_EN"))
	language_option.set_item_metadata(0, "en")
	language_option.add_item(localization.translate("LANGUAGE_TR"))
	language_option.set_item_metadata(1, "tr")
	language_option.selected = 1 if settings.language == "tr" else 0
	language_option.item_selected.connect(func(index: int) -> void:
		var selected_language := String(language_option.get_item_metadata(index))
		settings.set_language(selected_language)
		emit_signal("settings_changed")
	)
	box.add_child(language_option)

	return panel

