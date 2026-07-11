extends Control
class_name HUD

signal pause_pressed
signal resume_pressed
signal restart_pressed
signal menu_pressed
signal skip_tutorial_pressed

var localization: LocalizationManager
var gang_label: Label
var status_label: Label
var tutorial_label: Label
var tutorial_skip_button: Button
var pause_layer: Control
var pause_panel: PanelContainer
var pause_title: Label
var resume_button: Button

func setup(localization_manager: LocalizationManager) -> void:
	localization = localization_manager
	_build()

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top_margin := MarginContainer.new()
	top_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_margin.offset_bottom = 78
	top_margin.add_theme_constant_override("margin_left", 16)
	top_margin.add_theme_constant_override("margin_right", 16)
	top_margin.add_theme_constant_override("margin_top", 22)
	add_child(top_margin)

	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_margin.add_child(top_row)

	gang_label = Label.new()
	gang_label.add_theme_color_override("font_color", Color.WHITE)
	gang_label.add_theme_font_size_override("font_size", 16)
	top_row.add_child(gang_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	var pause_button := Button.new()
	pause_button.text = localization.translate("GAME_PAUSE")
	pause_button.custom_minimum_size = Vector2(86, 44)
	pause_button.pressed.connect(func() -> void:
		emit_signal("pause_pressed")
	)
	top_row.add_child(pause_button)

	var bottom_margin := MarginContainer.new()
	bottom_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_margin.offset_top = -96
	bottom_margin.add_theme_constant_override("margin_left", 16)
	bottom_margin.add_theme_constant_override("margin_right", 16)
	bottom_margin.add_theme_constant_override("margin_bottom", 26)
	add_child(bottom_margin)

	var bottom_box := VBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 6)
	bottom_margin.add_child(bottom_box)

	tutorial_label = Label.new()
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.add_theme_font_size_override("font_size", 15)
	tutorial_label.add_theme_color_override("font_color", Color(0.93, 0.96, 1.0))
	bottom_box.add_child(tutorial_label)

	tutorial_skip_button = Button.new()
	tutorial_skip_button.text = localization.translate("TUTORIAL_SKIP")
	tutorial_skip_button.custom_minimum_size = Vector2(86, 34)
	tutorial_skip_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tutorial_skip_button.pressed.connect(func() -> void:
		emit_signal("skip_tutorial_pressed")
	)
	bottom_box.add_child(tutorial_skip_button)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(0.7, 0.76, 0.86))
	bottom_box.add_child(status_label)

	_build_pause_panel()
	set_tutorial_key("", false)

func _build_pause_panel() -> void:
	pause_layer = Control.new()
	pause_layer.visible = false
	pause_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(pause_layer)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(shade)

	var center_container := CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(center_container)

	pause_panel = PanelContainer.new()
	pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_panel.custom_minimum_size = Vector2(260, 246)
	center_container.add_child(pause_panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	pause_panel.add_child(box)

	pause_title = Label.new()
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.add_theme_font_size_override("font_size", 24)
	pause_title.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(pause_title)

	resume_button = _make_overlay_button("GAME_RESUME")
	resume_button.pressed.connect(func() -> void:
		emit_signal("resume_pressed")
	)
	box.add_child(resume_button)

	var restart_button := _make_overlay_button("GAME_RESTART")
	restart_button.pressed.connect(func() -> void:
		emit_signal("restart_pressed")
	)
	box.add_child(restart_button)

	var menu_button := _make_overlay_button("GAME_MENU")
	menu_button.pressed.connect(func() -> void:
		emit_signal("menu_pressed")
	)
	box.add_child(menu_button)

func _make_overlay_button(key: String) -> Button:
	var button := Button.new()
	button.text = localization.translate(key)
	button.custom_minimum_size = Vector2(180, 42)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return button

func set_status_key(key: String) -> void:
	status_label.text = localization.translate(key)

func set_status_text(text: String) -> void:
	status_label.text = text

func set_gang_count(count: int) -> void:
	gang_label.text = "%s: %d" % [localization.translate("GAME_REMAINING_GANGS"), count]

func show_pause_menu(is_visible: bool) -> void:
	pause_layer.visible = is_visible
	resume_button.visible = true
	pause_title.text = localization.translate("GAME_PAUSED")

func show_result(result_key: String) -> void:
	pause_layer.visible = true
	resume_button.visible = false
	pause_title.text = localization.translate(result_key)

func set_tutorial_key(key: String, skippable: bool) -> void:
	tutorial_label.text = localization.translate(key)
	tutorial_label.visible = not key.is_empty()
	tutorial_skip_button.visible = skippable and not key.is_empty()
