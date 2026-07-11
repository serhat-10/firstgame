extends Control
class_name HUD

signal pause_pressed
signal resume_pressed
signal restart_pressed
signal menu_pressed
signal skip_tutorial_pressed
signal send_fraction_selected(fraction: float)

var localization: LocalizationManager
var emblem_badge: PanelContainer
var emblem_label: Label
var influence_label: Label
var faction_count_label: Label
var selected_label: Label
var send_control: HBoxContainer
var send_buttons: Dictionary = {}
var prompt_panel: PanelContainer
var prompt_label: Label
var tutorial_skip_button: Button
var pause_layer: Control
var pause_title: Label
var resume_button: Button
var player_color := Color(0.16, 0.84, 1.0)
var prompt_tween: Tween

func setup(localization_manager: LocalizationManager) -> void:
	localization = localization_manager
	_build()

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_top_hud()
	_build_bottom_hud()
	_build_pause_panel()
	set_selection_info("", 0, false)
	set_tutorial_key("", false)

func _build_top_hud() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.offset_bottom = 76
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 18)
	add_child(margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _glass_style(Color(0.06, 0.075, 0.10, 0.70), 10))
	margin.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	emblem_badge = PanelContainer.new()
	emblem_badge.custom_minimum_size = Vector2(36, 34)
	row.add_child(emblem_badge)

	emblem_label = Label.new()
	emblem_label.text = "AZ"
	emblem_label.custom_minimum_size = Vector2(34, 34)
	emblem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emblem_label.add_theme_font_size_override("font_size", 12)
	emblem_label.add_theme_color_override("font_color", Color(0.03, 0.05, 0.07))
	emblem_badge.add_child(emblem_label)

	influence_label = Label.new()
	influence_label.text = "0 %s" % localization.translate("GAME_INFLUENCE")
	influence_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	influence_label.add_theme_font_size_override("font_size", 15)
	influence_label.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	row.add_child(influence_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	faction_count_label = Label.new()
	faction_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	faction_count_label.add_theme_font_size_override("font_size", 13)
	faction_count_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.86))
	row.add_child(faction_count_label)

	var pause_button := Button.new()
	pause_button.text = "II"
	pause_button.tooltip_text = localization.translate("GAME_PAUSE")
	pause_button.custom_minimum_size = Vector2(42, 38)
	pause_button.add_theme_stylebox_override("normal", _button_style(Color(0.10, 0.12, 0.16, 0.82), 9))
	pause_button.add_theme_stylebox_override("hover", _button_style(Color(0.15, 0.18, 0.23, 0.90), 9))
	pause_button.add_theme_stylebox_override("pressed", _button_style(Color(0.20, 0.24, 0.30, 0.95), 9))
	pause_button.pressed.connect(func() -> void:
		emit_signal("pause_pressed")
	)
	row.add_child(pause_button)

func _build_bottom_hud() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	margin.offset_top = -158
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	selected_label = Label.new()
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_label.add_theme_font_size_override("font_size", 13)
	selected_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.94))
	column.add_child(selected_label)

	send_control = HBoxContainer.new()
	send_control.alignment = BoxContainer.ALIGNMENT_CENTER
	send_control.add_theme_constant_override("separation", 6)
	column.add_child(send_control)

	for percent in [25, 50, 75, 100]:
		var button := _make_send_button(percent)
		var fraction := float(percent) / 100.0
		send_control.add_child(button)
		send_buttons[fraction] = button

	prompt_panel = PanelContainer.new()
	prompt_panel.add_theme_stylebox_override("panel", _glass_style(Color(0.06, 0.075, 0.10, 0.72), 10))
	column.add_child(prompt_panel)

	var prompt_row := HBoxContainer.new()
	prompt_row.alignment = BoxContainer.ALIGNMENT_CENTER
	prompt_row.add_theme_constant_override("separation", 8)
	prompt_panel.add_child(prompt_row)

	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_row.add_child(prompt_label)

	tutorial_skip_button = Button.new()
	tutorial_skip_button.text = localization.translate("TUTORIAL_SKIP")
	tutorial_skip_button.custom_minimum_size = Vector2(56, 30)
	tutorial_skip_button.add_theme_stylebox_override("normal", _button_style(Color(0.11, 0.13, 0.18, 0.84), 8))
	tutorial_skip_button.pressed.connect(func() -> void:
		emit_signal("skip_tutorial_pressed")
	)
	prompt_row.add_child(tutorial_skip_button)

func _build_pause_panel() -> void:
	pause_layer = Control.new()
	pause_layer.visible = false
	pause_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(pause_layer)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.50)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(shade)

	var center_container := CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(center_container)

	var pause_panel := PanelContainer.new()
	pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_panel.custom_minimum_size = Vector2(260, 236)
	pause_panel.add_theme_stylebox_override("panel", _glass_style(Color(0.07, 0.085, 0.11, 0.94), 12))
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

func set_player_identity(emblem: String, color: Color) -> void:
	player_color = color
	emblem_label.text = emblem
	emblem_badge.add_theme_stylebox_override("panel", _button_style(Color(color.r, color.g, color.b, 0.95), 17))

func set_player_influence(influence: int) -> void:
	influence_label.text = "%d %s" % [influence, localization.translate("GAME_INFLUENCE")]

func set_status_key(key: String) -> void:
	set_prompt_key(key)

func set_prompt_key(key: String) -> void:
	set_prompt_text(localization.translate(key))

func set_prompt_text(text: String) -> void:
	prompt_label.text = text
	if prompt_tween != null:
		prompt_tween.kill()
	prompt_panel.modulate.a = 0.0
	prompt_tween = create_tween()
	prompt_tween.tween_property(prompt_panel, "modulate:a", 1.0, 0.16)

func set_gang_count(count: int) -> void:
	faction_count_label.text = "%d %s" % [count, localization.translate("GAME_REMAINING_FACTIONS")]

func set_selection_info(district_name: String, population: int, is_visible: bool) -> void:
	selected_label.visible = is_visible
	send_control.visible = is_visible
	if is_visible:
		selected_label.text = "%s: %s - %d %s" % [
			localization.translate("GAME_SELECTED"),
			district_name,
			population,
			localization.translate("GAME_UNITS")
		]

func set_send_fraction(fraction: float) -> void:
	for key in send_buttons.keys():
		var button: Button = send_buttons[key]
		var selected := is_equal_approx(float(key), fraction)
		var color := player_color if selected else Color(0.10, 0.12, 0.16, 0.82)
		button.add_theme_stylebox_override("normal", _button_style(Color(color.r, color.g, color.b, 0.90), 8))
		button.add_theme_stylebox_override("hover", _button_style(Color(color.r, color.g, color.b, 0.98), 8))
		button.add_theme_color_override("font_color", Color(0.03, 0.05, 0.07) if selected else Color(0.82, 0.88, 0.96))

func show_pause_menu(is_visible: bool) -> void:
	pause_layer.visible = is_visible
	resume_button.visible = true
	pause_title.text = localization.translate("GAME_PAUSED")

func show_result(result_key: String) -> void:
	pause_layer.visible = true
	resume_button.visible = false
	pause_title.text = localization.translate(result_key)

func set_tutorial_key(key: String, skippable: bool) -> void:
	if key.is_empty():
		set_prompt_key("GAME_RUNNING")
	else:
		set_prompt_key(key)
	tutorial_skip_button.visible = skippable and not key.is_empty()

func _make_overlay_button(key: String) -> Button:
	var button := Button.new()
	button.text = localization.translate(key)
	button.custom_minimum_size = Vector2(180, 42)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_stylebox_override("normal", _button_style(Color(0.10, 0.12, 0.16, 0.88), 9))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.15, 0.18, 0.23, 0.95), 9))
	return button

func _make_send_button(percent: int) -> Button:
	var button := Button.new()
	button.text = "%d%%" % percent
	button.custom_minimum_size = Vector2(58, 36)
	var fraction := float(percent) / 100.0
	button.pressed.connect(func() -> void:
		emit_signal("send_fraction_selected", fraction)
	)
	return button

func _glass_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = Color(0.65, 0.78, 0.92, 0.10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

func _button_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
