extends Control

signal login_requested(email: String, password: String, account_type: String)
signal register_requested(email: String, password: String, account_type: String, profile_data: Dictionary)

var _email: LineEdit
var _password: LineEdit
var _company_name: LineEdit
var _company_phone: LineEdit
var _status: Label
var _client_button: Button
var _company_button: Button
var _mode_login_button: Button
var _mode_register_button: Button
var _panel: PanelContainer
var _app_font: Font
var _scale := 1.0
var _selected_account_type := "user"
var _mode := "login"
var _first_build_done := false

const BLUE := Color("#02286E")
const BLUE_SOFT := Color("#0B3A8F")
const FIX_GREEN := Color("#159EA3")
const TEAL := Color("#12BAC2")
const MUTED := Color("#5D789B")
const BORDER := Color("#B9D3EA")
const SOFT := Color("#F3FAFF")
const BACKGROUND_PATH := "res://assets/background/app_background.png"
const LOGO_PATH := "res://assets/icon/logo_cropped.png"
const FALLBACK_LOGO_PATH := "res://assets/icon/adaptive_foreground.png"
const UF_KEYBOARD_AWARE_SCROLL_SCRIPT := preload("res://app/scripts/ui/UFKeyboardAwareScroll.gd")
const USER_LABEL := "Client"
const COMPANY_LABEL := "Firmă"

func setup(scale_value: float, font: Font) -> void:
	_scale = scale_value
	_app_font = font
	_build_auth_screen(_mode)

func set_status(text: String, is_error: bool = false) -> void:
	if is_instance_valid(_status):
		_status.text = text
		_status.visible = text.strip_edges() != ""
		_status.add_theme_color_override("font_color", Color("#C0392B") if is_error else MUTED)

func _dp(v: float) -> int:
	return int(round(v * _scale))

func _apply_font(c: Control, font_size: int) -> void:
	if _app_font != null:
		c.add_theme_font_override("font", _app_font)
	c.add_theme_font_size_override("font_size", _dp(font_size))

func _clear() -> void:
	for child: Node in get_children():
		child.queue_free()

	_email = null
	_password = null
	_company_name = null
	_company_phone = null
	_status = null
	_client_button = null
	_company_button = null
	_mode_login_button = null
	_mode_register_button = null
	_panel = null
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _base_panel() -> VBoxContainer:
	_clear()
	_build_background()

	var scroll := UF_KEYBOARD_AWARE_SCROLL_SCRIPT.new()
	scroll.name = "AuthKeyboardScroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.follow_focus = false
	scroll.reset_scroll_when_keyboard_hidden = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	var scroll_body := VBoxContainer.new()
	scroll_body.name = "AuthScrollBody"
	scroll_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_body.custom_minimum_size = get_viewport_rect().size
	scroll.add_child(scroll_body)

	var center := CenterContainer.new()
	center.custom_minimum_size = get_viewport_rect().size
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll_body.add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(_dp(322), 0)
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.965), BLUE, 27, 2))
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dp(17))
	margin.add_theme_constant_override("margin_right", _dp(17))
	margin.add_theme_constant_override("margin_top", _dp(17))
	margin.add_theme_constant_override("margin_bottom", _dp(17))
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", _dp(9))
	margin.add_child(box)

	var keyboard_spacer := Control.new()
	keyboard_spacer.name = "KeyboardBottomSpacer"
	scroll_body.add_child(keyboard_spacer)
	scroll.set_bottom_spacer(keyboard_spacer)

	return box

func _build_background() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(BACKGROUND_PATH):
		var tex: Variant = load(BACKGROUND_PATH)
		if tex is Texture2D:
			bg.texture = tex
	add_child(bg)

	var wash := ColorRect.new()
	wash.color = Color(1, 1, 1, 0.10)
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var glow_top := ColorRect.new()
	glow_top.color = Color("#12BAC2", 0.12)
	glow_top.anchor_left = 0.0
	glow_top.anchor_top = 0.0
	glow_top.anchor_right = 1.0
	glow_top.anchor_bottom = 0.0
	glow_top.offset_bottom = _dp(210)
	glow_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow_top)

func _build_auth_screen(mode: String) -> void:
	_mode = mode
	var box: VBoxContainer = _base_panel()

	box.add_child(_logo_block())

	var title := Label.new()
	title.text = "Bine ai revenit" if _mode == "login" else "Creează cont"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", BLUE)
	_apply_font(title, 27)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Alege tipul de cont potrivit: client pentru cereri rapide sau firmă pentru intervenții."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", MUTED)
	_apply_font(subtitle, 12)
	box.add_child(subtitle)

	box.add_child(_mode_switch())

	var role_row := HBoxContainer.new()
	role_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	role_row.add_theme_constant_override("separation", _dp(8))
	box.add_child(role_row)

	_client_button = _role_switch_button(USER_LABEL, "user")
	role_row.add_child(_client_button)

	_company_button = _role_switch_button(COMPANY_LABEL, "company")
	role_row.add_child(_company_button)

	_update_role_switch_styles()
	_update_mode_switch_styles()

	_email = _create_line_input("Email")
	box.add_child(_email)

	_password = _create_line_input("Parolă")
	_password.secret = true
	box.add_child(_password)

	if _mode == "register" and _selected_account_type == "company":
		_add_company_register_fields(box)

	var primary_text: String = "Intră în cont" if _mode == "login" else "Creează cont"
	box.add_child(_auth_button(primary_text, true, func() -> void:
		_submit_auth()
	))

	_status = _status_label("")
	_status.visible = false
	box.add_child(_status)

	if not _first_build_done and is_instance_valid(_panel):
		_first_build_done = true
		_panel.modulate.a = 0.0
		_panel.scale = Vector2(0.92, 0.92)
		call_deferred("_animate_in", _panel)

func _logo_block() -> Control:
	var holder := CenterContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.custom_minimum_size.y = _dp(58)

	var logo := TextureRect.new()
	logo.custom_minimum_size = Vector2(_dp(190), _dp(54))
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tex := _load_texture(LOGO_PATH)
	if tex == null:
		tex = _load_texture(FALLBACK_LOGO_PATH)
	if tex != null:
		logo.texture = tex

	holder.add_child(logo)
	return holder

func _load_texture(path: String) -> Texture2D:
	if path.strip_edges() == "" or not ResourceLoader.exists(path):
		return null
	var resource: Variant = load(path)
	if resource is Texture2D:
		return resource
	return null

func _mode_switch() -> Control:
	var shell := PanelContainer.new()
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_theme_stylebox_override("panel", _style(Color("#EAF7FA", 0.90), Color("#D2EEF4"), 17, 1))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dp(4))
	margin.add_theme_constant_override("margin_right", _dp(4))
	margin.add_theme_constant_override("margin_top", _dp(4))
	margin.add_theme_constant_override("margin_bottom", _dp(4))
	shell.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", _dp(5))
	margin.add_child(row)

	_mode_login_button = _small_tab_button("Login", "login")
	row.add_child(_mode_login_button)

	_mode_register_button = _small_tab_button("Register", "register")
	row.add_child(_mode_register_button)

	return shell

func _small_tab_button(text: String, target_mode: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = _dp(37)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.shortcut_feedback = false
	_apply_font(b, 13)
	b.pressed.connect(func() -> void:
		if _mode == target_mode:
			_bounce(b)
			return
		_bounce(b)
		_build_auth_screen(target_mode)
	)
	return b

func _update_mode_switch_styles() -> void:
	_apply_tab_style(_mode_login_button, _mode == "login")
	_apply_tab_style(_mode_register_button, _mode == "register")

func _apply_tab_style(button: Button, selected: bool) -> void:
	if not is_instance_valid(button):
		return
	var fill := BLUE if selected else Color(1, 1, 1, 0.0)
	var font := Color.WHITE if selected else BLUE
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_color_override("font_focus_color", font)
	button.add_theme_stylebox_override("normal", _style(fill, BLUE, 14, 0))
	button.add_theme_stylebox_override("hover", _style(fill, BLUE, 14, 0))
	button.add_theme_stylebox_override("pressed", _style(fill, BLUE, 14, 0))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _add_company_register_fields(box: VBoxContainer) -> void:
	var section := Label.new()
	section.text = "Date firmă"
	section.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_theme_color_override("font_color", BLUE)
	_apply_font(section, 14)
	box.add_child(section)

	_company_name = _create_line_input("Nume firmă / prestator")
	box.add_child(_company_name)

	_company_phone = _create_line_input("Telefon contact")
	box.add_child(_company_phone)

func _role_switch_button(title_text: String, account_type: String) -> Button:
	var b := Button.new()
	b.text = title_text
	b.custom_minimum_size.y = _dp(47)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.shortcut_feedback = false
	_apply_font(b, 12)
	b.pressed.connect(func() -> void:
		_bounce(b)
		_selected_account_type = account_type
		if _mode == "register":
			call_deferred("_build_auth_screen", _mode)
		else:
			_update_role_switch_styles()
	)
	return b

func _update_role_switch_styles() -> void:
	_apply_role_switch_style(_client_button, _selected_account_type == "user")
	_apply_role_switch_style(_company_button, _selected_account_type == "company")

func _apply_role_switch_style(button: Button, selected: bool) -> void:
	if not is_instance_valid(button):
		return
	var fill := BLUE if selected else Color(1, 1, 1, 0.0)
	var font := Color.WHITE if selected else BLUE
	var border_width := 0 if selected else 2
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_color_override("font_focus_color", font)
	button.add_theme_stylebox_override("normal", _style(fill, BLUE, 15, border_width))
	button.add_theme_stylebox_override("hover", _style(fill, BLUE, 15, border_width))
	button.add_theme_stylebox_override("pressed", _style(fill, BLUE, 15, border_width))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _submit_auth() -> void:
	if not is_instance_valid(_email) or not is_instance_valid(_password):
		return

	var email_value: String = _email.text.strip_edges()
	var password_value: String = _password.text

	if email_value == "" or password_value.length() < 6:
		set_status("Completează emailul și o parolă de minim 6 caractere.", true)
		return
	if not email_value.contains("@") or not email_value.contains("."):
		set_status("Scrie un email valid.", true)
		return

	if _mode == "register":
		var profile_data: Dictionary = _collect_extra_profile_data()
		if _selected_account_type == "company" and not _validate_company_profile(profile_data):
			return
		register_requested.emit(email_value, password_value, _selected_account_type, profile_data)
	else:
		login_requested.emit(email_value, password_value, _selected_account_type)

func _collect_extra_profile_data() -> Dictionary:
	if _selected_account_type != "company":
		return {}

	var company_name := _company_name.text.strip_edges() if is_instance_valid(_company_name) else ""
	return {
		"company_name": company_name,
		"display_name": company_name,
		"phone": _company_phone.text.strip_edges() if is_instance_valid(_company_phone) else ""
	}

func _validate_company_profile(profile_data: Dictionary) -> bool:
	if str(profile_data.get("company_name", "")).strip_edges() == "" or str(profile_data.get("phone", "")).strip_edges() == "":
		set_status("Pentru firmă trebuie completate toate cele 4 câmpuri.", true)
		return false
	if str(profile_data.get("company_name", "")).length() < 2:
		set_status("Scrie numele firmei sau al prestatorului.", true)
		return false
	if str(profile_data.get("phone", "")).length() < 6:
		set_status("Adaugă un număr de telefon valid.", true)
		return false
	return true

func _create_line_input(placeholder: String) -> LineEdit:
	var line := LineEdit.new()
	line.placeholder_text = placeholder
	line.custom_minimum_size.y = _dp(50)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.focus_mode = Control.FOCUS_CLICK
	line.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_font(line, 14)
	line.add_theme_color_override("font_color", BLUE)
	line.add_theme_color_override("font_placeholder_color", Color("#4F6F94"))
	line.add_theme_color_override("caret_color", BLUE)
	line.add_theme_constant_override("caret_width", _dp(3))
	line.caret_blink = true
	line.caret_blink_interval = 0.42
	line.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.99), Color("#8DBBDB"), 14, 2))
	line.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.99), Color("#8DBBDB"), 14, 2))
	line.add_theme_stylebox_override("focus", _style(Color.WHITE, FIX_GREEN, 14, 3))
	return line

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_release_focus_if_tapping_outside_input(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_release_focus_if_tapping_outside_input(event.position)

func _release_focus_if_tapping_outside_input(point: Vector2) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if not (focused is LineEdit or focused is TextEdit):
		return

	var focused_control := focused as Control
	if focused_control.get_global_rect().has_point(point):
		return

	_release_input_focus_after_keyboard()


func _release_input_focus_after_keyboard() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit:
		(focused as Control).release_focus()

	if DisplayServer.has_method("virtual_keyboard_hide"):
		DisplayServer.virtual_keyboard_hide()

func _auth_button(text: String, primary: bool, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = _dp(52)
	b.focus_mode = Control.FOCUS_NONE
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.shortcut_feedback = false
	_apply_font(b, 14)
	_apply_button_style(b, primary)
	b.pressed.connect(func() -> void:
		_bounce(b)
		callback.call()
	)
	return b

func _apply_button_style(button: Button, primary: bool) -> void:
	var fill := BLUE if primary else Color(1, 1, 1, 0.0)
	var font := Color.WHITE if primary else BLUE
	var border_width := 0 if primary else 2
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_color_override("font_focus_color", font)
	button.add_theme_stylebox_override("normal", _style(fill, BLUE, 15, border_width))
	button.add_theme_stylebox_override("hover", _style(fill, BLUE, 15, border_width))
	button.add_theme_stylebox_override("pressed", _style(fill, BLUE, 15, border_width))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _bounce(button: Control) -> void:
	if not is_instance_valid(button):
		return
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.94, 0.94), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _status_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", MUTED)
	_apply_font(label, 11)
	return label

func _animate_in(panel: Control) -> void:
	if not is_instance_valid(panel):
		return

	await get_tree().process_frame
	if not is_instance_valid(panel):
		return

	panel.pivot_offset = panel.size * 0.5
	var start_y := panel.position.y
	panel.position.y = start_y + _dp(30)
	panel.scale = Vector2(0.92, 0.92)
	panel.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "position:y", start_y, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _style(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.border_width_left = width
	s.border_width_right = width
	s.border_width_top = width
	s.border_width_bottom = width
	s.corner_radius_top_left = _dp(radius)
	s.corner_radius_top_right = _dp(radius)
	s.corner_radius_bottom_left = _dp(radius)
	s.corner_radius_bottom_right = _dp(radius)
	s.content_margin_left = _dp(12)
	s.content_margin_right = _dp(12)
	s.content_margin_top = _dp(7)
	s.content_margin_bottom = _dp(7)
	return s
