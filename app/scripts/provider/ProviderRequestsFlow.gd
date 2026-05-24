extends Control

signal back_requested
signal requests_changed(requests: Array)

const BLUE := Color("#02286E")
const BLUE_DARK := Color("#011C50")
const FIX_GREEN := Color("#159EA3")
const TEXT := Color("#02286E")
const MUTED := Color("#7289A8")
const BORDER := Color("#DDEDF8")
const SOFT := Color("#F3FAFF")
const GREEN_SOFT := Color("#E9FCFD")
const WARNING_SOFT := Color("#FFF6DB")
const CARD := Color.WHITE
const LOGO_PATH := "res://assets/icon/logo_cropped.png"
const FALLBACK_LOGO_PATH := "res://assets/icon/adaptive_foreground.png"
const DEMO_PHOTO_PATH := "res://app/assets/demo/plumbing_preview.png"
const UF_KEYBOARD_AWARE_SCROLL_SCRIPT := preload("res://app/scripts/ui/UFKeyboardAwareScroll.gd")

var _requests: Array = []
var _time_filter := "Toate"
var _type_filter := "Toate"
var _selected_request_id := ""
var _scale := 1.0
var _app_font: Font
var _notice_overlay: Control
var _list_box: VBoxContainer
var _empty_label: Control
var _pressed_card_id := ""
var _pressed_card_pos := Vector2.ZERO
var _rounded_image_shader_cache: Shader
var _details_carousel_scroll: ScrollContainer
var _details_carousel_dots: Array[PanelContainer] = []
var _details_page_index := 0

func setup(initial_requests: Array, scale_value: float = 1.0, app_font: Font = null) -> void:
	_requests = initial_requests.duplicate(true)
	_scale = clampf(scale_value, 0.86, 2.65)
	_app_font = app_font
	if is_inside_tree():
		_rebuild()

func refresh_view() -> void:
	_rebuild()

func _ready() -> void:
	_rebuild()

func _dp(value: float) -> int:
	return int(round(value * _scale))

func _safe_width() -> int:
	var available := get_viewport_rect().size.x - _dp(36)
	if size.x > 0.0:
		available = minf(available, size.x)
	return int(round(clampf(available, _dp(300), _dp(340))))

func _apply_font(control: Control, font_size: int) -> void:
	if _app_font != null:
		control.add_theme_font_override("font", _app_font)
	control.add_theme_font_size_override("font_size", _dp(font_size))

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true
	if _selected_request_id.strip_edges() != "":
		_build_details_page(_selected_request_id)
	else:
		_build_list_page()

func _page_shell() -> VBoxContainer:
	var center := HBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)
	var page := VBoxContainer.new()
	page.name = "ProviderPage"
	page.custom_minimum_size.x = _safe_width()
	page.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.alignment = BoxContainer.ALIGNMENT_BEGIN
	page.add_theme_constant_override("separation", _dp(8))
	center.add_child(page)
	return page

func _build_list_page() -> void:
	var root := _page_shell()
	root.add_child(_gap(34))
	root.add_child(_header_block())
	root.add_child(_minimal_steps())
	root.add_child(_filters_panel())
	root.add_child(_works_scroll())
	call_deferred("_refresh_work_list")

func _header_block() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", _dp(-5))

	var holder := TextureRect.new()
	holder.custom_minimum_size = Vector2(_dp(108), _dp(92))
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	holder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var logo := _load_texture(LOGO_PATH)
	if logo == null:
		logo = _load_texture(FALLBACK_LOGO_PATH)
	holder.texture = logo
	box.add_child(holder)

	var word := HBoxContainer.new()
	word.alignment = BoxContainer.ALIGNMENT_CENTER
	word.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	word.add_theme_constant_override("separation", 0)
	var urgent := _label("Urgent", 32, TEXT)
	urgent.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	urgent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var fix := _label("Fix", 32, FIX_GREEN)
	fix.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fix.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	word.add_child(urgent)
	word.add_child(fix)
	box.add_child(word)

	box.add_child(_gap(14))
	box.add_child(_headline("Lucrări disponibile", 23))
	return box

func _minimal_steps(active_step: int = 1) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = _dp(38)
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.92), BORDER, 16, 1))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", _dp(28))
	margin.add_theme_constant_override("margin_right", _dp(28))
	margin.add_theme_constant_override("margin_top", _dp(6))
	margin.add_theme_constant_override("margin_bottom", _dp(6))
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", _dp(6))
	margin.add_child(row)
	for i in range(1, 5):
		row.add_child(_step_dot(str(i), i <= active_step, i == active_step))
		if i < 4:
			row.add_child(_step_line(i < active_step))
	return panel

func _step_dot(number: String, completed: bool = false, current: bool = false) -> PanelContainer:
	var circle := PanelContainer.new()
	circle.custom_minimum_size = Vector2(_dp(27), _dp(27))
	circle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill := FIX_GREEN if completed else Color(1, 1, 1, 0.0)
	var border := FIX_GREEN if completed or current else BLUE
	circle.add_theme_stylebox_override("panel", _frame_style(fill, border, 50, 2 if current else 1))
	var number_label := _center_text(number, 11)
	number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number_label.add_theme_color_override("font_color", Color.WHITE if completed else BLUE)
	circle.add_child(number_label)
	return circle

func _step_line(active: bool = false) -> PanelContainer:
	var line := PanelContainer.new()
	line.custom_minimum_size = Vector2(_dp(16), max(1, _dp(1)))
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var color := FIX_GREEN if active else Color("#B7DDE5")
	line.add_theme_stylebox_override("panel", _frame_style(color, color, 50, 0))
	return line

func _filters_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.94), BORDER, 18, 1))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dp(12))
	margin.add_theme_constant_override("margin_right", _dp(12))
	margin.add_theme_constant_override("margin_top", _dp(8))
	margin.add_theme_constant_override("margin_bottom", _dp(8))
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", _dp(10))
	margin.add_child(row)
	row.add_child(_dropdown("Timp", ["Toate", "Urgent", "Azi", "2-3 zile", "Săptămâna aceasta"], _time_filter, func(value: String) -> void:
		_time_filter = value
		_refresh_work_list()
	))
	row.add_child(_dropdown("Tip", ["Toate", "Instalații", "Electric", "Zugrăveli", "Centrală / încălzire", "Infiltrații", "Aer condiționat", "Altele"], _type_filter, func(value: String) -> void:
		_type_filter = value
		_refresh_work_list()
	))
	return panel

func _dropdown(label_text: String, values: Array[String], selected: String, cb: Callable) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", _dp(5))
	var label := _label(label_text + ":", 15, BLUE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", _dp(1))
	box.add_child(label)
	var button := Button.new()
	button.text = selected
	button.custom_minimum_size.y = _dp(44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(button, 11)
	button.add_theme_color_override("font_color", BLUE)
	button.add_theme_color_override("font_hover_color", BLUE)
	button.add_theme_color_override("font_pressed_color", BLUE)
	button.add_theme_stylebox_override("normal", _style(Color.WHITE, BLUE, 14, 2))
	button.add_theme_stylebox_override("hover", _style(SOFT, FIX_GREEN, 14, 2))
	button.add_theme_stylebox_override("pressed", _style(Color.WHITE, FIX_GREEN, 14, 3))
	button.pressed.connect(func() -> void:
		_show_dropdown_popup(label_text, values, selected, cb)
	)
	_make_bouncy(button)
	box.add_child(button)
	return box

func _show_dropdown_popup(title_text: String, values: Array[String], selected: String, cb: Callable) -> void:
	if is_instance_valid(_notice_overlay):
		_notice_overlay.queue_free()
	_notice_overlay = Control.new()
	_notice_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_notice_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_notice_overlay.z_index = 960
	add_child(_notice_overlay)
	var dim := ColorRect.new()
	dim.color = Color(1, 1, 1, 0.58)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_notice_overlay.queue_free()
		elif event is InputEventScreenTouch and event.pressed:
			_notice_overlay.queue_free()
	)
	_notice_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_dp(300), 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.98), BLUE, 24, 2))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dp(16))
	margin.add_theme_constant_override("margin_right", _dp(16))
	margin.add_theme_constant_override("margin_top", _dp(16))
	margin.add_theme_constant_override("margin_bottom", _dp(16))
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", _dp(8))
	margin.add_child(box)
	box.add_child(_headline(title_text, 19))
	for value in values:
		var is_selected := value == selected
		var option := Button.new()
		option.text = value
		option.custom_minimum_size.y = _dp(42)
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.focus_mode = Control.FOCUS_NONE
		option.clip_text = true
		option.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_apply_font(option, 12)
		var fill := BLUE if is_selected else SOFT
		var border := BLUE if is_selected else BORDER
		var color := Color.WHITE if is_selected else TEXT
		option.add_theme_color_override("font_color", color)
		option.add_theme_color_override("font_hover_color", color)
		option.add_theme_color_override("font_pressed_color", color)
		option.add_theme_stylebox_override("normal", _style(fill, border, 14, 1 if not is_selected else 0))
		option.add_theme_stylebox_override("hover", _style(fill, FIX_GREEN, 14, 2))
		option.add_theme_stylebox_override("pressed", _style(BLUE_DARK if is_selected else Color.WHITE, FIX_GREEN, 14, 2))
		var selected_value := str(value)
		option.pressed.connect(func() -> void:
			if is_instance_valid(_notice_overlay):
				_notice_overlay.queue_free()
			cb.call(selected_value)
			_rebuild()
		)
		_make_bouncy(option)
		box.add_child(option)

	panel.scale = Vector2(0.92, 0.92)
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _works_scroll() -> PanelContainer:
	var shell := PanelContainer.new()
	shell.mouse_filter = Control.MOUSE_FILTER_PASS
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	shell.custom_minimum_size.y = _dp(345)
	shell.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.18), Color(1, 1, 1, 0.0), 20, 0))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_top", _dp(4))
	margin.add_theme_constant_override("margin_bottom", _dp(4))
	shell.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.name = "WorksScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = false
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.add_child(scroll)
	_list_box = VBoxContainer.new()
	_list_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_list_box.name = "WorksList"
	_list_box.custom_minimum_size.x = _safe_width()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", _dp(10))
	scroll.add_child(_list_box)
	return shell

func _refresh_work_list() -> void:
	if not is_instance_valid(_list_box):
		return
	for child in _list_box.get_children():
		child.queue_free()
	var visible_requests := _visible_requests()
	if visible_requests.is_empty():
		_list_box.add_child(_empty_state())
		return
	for item in visible_requests:
		if item is Dictionary:
			_list_box.add_child(_work_preview_card(item as Dictionary))

func _work_preview_card(request: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = _dp(168)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.99), BLUE, 22, 2))
	panel.gui_input.connect(func(event: InputEvent) -> void:
		_handle_card_input(event, str(request.get("id", "")))
	)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", _dp(12))
	margin.add_theme_constant_override("margin_right", _dp(12))
	margin.add_theme_constant_override("margin_top", _dp(12))
	margin.add_theme_constant_override("margin_bottom", _dp(12))
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", _dp(12))
	margin.add_child(row)
	row.add_child(_request_thumb(request, _dp(112)))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", _dp(4))
	row.add_child(info)
	info.add_child(_labeled_value_line("Tip:", _request_title(request), 13, TEXT))
	info.add_child(_labeled_value_line("Nume client:", _request_user(request), 12, MUTED))
	info.add_child(_labeled_value_line("Localitate:", _request_area(request), 12, MUTED))
	info.add_child(_labeled_value_line("Descriere:", _trim_preview(str(request.get("description", "Fără descriere.")), 42), 12, MUTED))
	var bottom := HBoxContainer.new()
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", _dp(7))
	info.add_child(bottom)
	bottom.add_child(_info_chip(_short_badge(str(request.get("urgency", "Nespecificat"))), GREEN_SOFT, FIX_GREEN))
	bottom.add_child(_status_chip(request))
	return panel

func _handle_card_input(event: InputEvent, request_id: String) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_pressed_card_id = request_id
			_pressed_card_pos = touch.position
		elif _pressed_card_id == request_id and touch.position.distance_to(_pressed_card_pos) <= float(_dp(10)):
			_open_request(request_id)
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			_pressed_card_id = request_id
			_pressed_card_pos = mouse.position
		elif _pressed_card_id == request_id and mouse.position.distance_to(_pressed_card_pos) <= float(_dp(10)):
			_open_request(request_id)

func _open_request(request_id: String) -> void:
	_pressed_card_id = ""
	_selected_request_id = request_id
	_rebuild()

func _labeled_value_line(label_text: String, value_text: String, font_size: int, value_color: Color) -> Label:
	var line := _label(label_text + " " + value_text, font_size, value_color)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.clip_text = true
	line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return line

func _trim_preview(text: String, max_len: int) -> String:
	var clean := text.replace("\n", " ").strip_edges()
	if clean.length() <= max_len:
		return clean
	return clean.left(max_len - 3) + "..."

func _info_chip(text: String, bg: Color, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(0, _dp(32))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(bg, color, 16, 2))
	var label := _center_text(text, 11)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	panel.add_child(label)
	return panel

func _request_thumb(request: Dictionary, side: int = 0) -> Control:
	var thumb_side := side if side > 0 else _dp(100)
	var shell := Control.new()
	shell.custom_minimum_size = Vector2(thumb_side, thumb_side)
	shell.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	shell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture := _first_media_texture(request)
	if texture != null:
		var image := ColorRect.new()
		image.set_anchors_preset(Control.PRESET_FULL_RECT)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.color = Color.WHITE
		var material := ShaderMaterial.new()
		material.shader = _rounded_image_shader()
		material.set_shader_parameter("image_texture", texture)
		material.set_shader_parameter("rect_size", Vector2(thumb_side, thumb_side))
		material.set_shader_parameter("radius_px", float(_dp(18)))
		material.set_shader_parameter("border_width_px", float(_dp(3)))
		material.set_shader_parameter("border_color", BLUE)
		material.set_shader_parameter("bg_color", SOFT)
		image.material = material
		shell.add_child(image)
	else:
		var panel := PanelContainer.new()
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.clip_contents = true
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override("panel", _frame_style(SOFT, BLUE, 18, 3))
		shell.add_child(panel)
		var placeholder := VBoxContainer.new()
		placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
		placeholder.alignment = BoxContainer.ALIGNMENT_CENTER
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mark := _center_text("+", 22)
		mark.add_theme_color_override("font_color", BLUE)
		placeholder.add_child(mark)
		var text := _center_text("poză", 8)
		text.add_theme_color_override("font_color", MUTED)
		placeholder.add_child(text)
		panel.add_child(placeholder)
	return shell

func _rounded_image_shader() -> Shader:
	if _rounded_image_shader_cache != null:
		return _rounded_image_shader_cache
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D image_texture;
uniform vec4 border_color : source_color = vec4(0.01, 0.16, 0.43, 1.0);
uniform vec4 bg_color : source_color = vec4(0.91, 0.99, 0.99, 1.0);
uniform vec2 rect_size = vec2(100.0, 100.0);
uniform float radius_px = 18.0;
uniform float border_width_px = 3.0;

float rounded_box(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * rect_size;
	float d = rounded_box(p, rect_size * 0.5, radius_px);
	float alpha = 1.0 - smoothstep(0.0, 1.0, d);
	vec4 sampled = texture(image_texture, UV);
	vec4 base = mix(bg_color, sampled, sampled.a);
	float border_mask = step(-border_width_px, d);
	COLOR = mix(base, border_color, border_mask) * alpha;
}
"""
	_rounded_image_shader_cache = shader
	return _rounded_image_shader_cache

func _build_details_page(request_id: String) -> void:
	var request := _request_by_id(request_id)
	if request.is_empty():
		_selected_request_id = ""
		_build_list_page()
		return
	var root := _page_shell()
	root.add_child(_gap(92))
	root.add_child(_minimal_steps(_flow_step_for_request(request)))
	var actions := GridContainer.new()
	actions.columns = 2
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	actions.add_theme_constant_override("h_separation", _dp(8))
	actions.add_theme_constant_override("v_separation", _dp(8))
	root.add_child(actions)
	actions.add_child(_flow_action_button(request, "1. Propune", 1, func() -> void: _show_proposal_popup(request_id)))
	actions.add_child(_flow_action_button(request, "2. Contract", 2, func() -> void: _sign_contract(request_id)))
	actions.add_child(_flow_action_button(request, "3. Gata", 3, func() -> void: _mark_work_done(request_id)))
	actions.add_child(_flow_action_button(request, "4. Încasează", 4, func() -> void: _approve_close_delete(request_id)))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = _dp(470)
	scroll.follow_focus = false
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(scroll)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.custom_minimum_size.x = _safe_width()
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	box.add_theme_constant_override("separation", _dp(10))
	scroll.add_child(box)
	box.add_child(_details_media_carousel(request))
	box.add_child(_contract_hero(request))
	box.add_child(_proposal_panel(request, request_id))
	box.add_child(_info_section("Date client", [
		"Nume client: " + _request_user(request),
		"Telefon: " + str(request.get("user_phone", "+40 700 000 000")),
		"Localitate: " + _request_area(request),
		"Data cererii: " + str(request.get("created_at", "azi"))
	]))
	box.add_child(_info_section("Lucrare", [
		"Tip: " + _request_title(request),
		"Timp: " + str(request.get("urgency", "Nespecificat")),
		"Status: " + _status_text_short(request),
		"Descriere: " + str(request.get("description", "Fără descriere."))
	]))
	box.add_child(_contract_box(request))
	box.add_child(_payment_box(request))
	box.add_child(_gap(24))

func _details_media_carousel(request: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.98), BORDER, 24, 1))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", _dp(10))
	margin.add_theme_constant_override("margin_right", _dp(10))
	margin.add_theme_constant_override("margin_top", _dp(10))
	margin.add_theme_constant_override("margin_bottom", _dp(10))
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_theme_constant_override("separation", _dp(7))
	margin.add_child(box)
	var title := _label("Poze atașate", 17, TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_details_carousel_scroll = ScrollContainer.new()
	var side := _details_preview_size()
	_details_carousel_scroll.custom_minimum_size = Vector2(side, side)
	_details_carousel_scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_details_carousel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_details_carousel_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_details_carousel_scroll.follow_focus = false
	_details_carousel_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_details_carousel_scroll.gui_input.connect(_on_details_carousel_input)
	box.add_child(_details_carousel_scroll)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_theme_constant_override("separation", 0)
	_details_carousel_scroll.add_child(row)
	var textures := _media_textures(request)
	_details_page_index = clampi(_details_page_index, 0, max(0, textures.size() - 1))
	for texture in textures:
		var item := _large_media_square(texture)
		item.custom_minimum_size = Vector2(side, side)
		row.add_child(item)
	if textures.size() > 1:
		box.add_child(_details_dots(textures.size()))
	call_deferred("_restore_details_carousel_position")
	return panel

func _details_preview_size() -> int:
	return min(_safe_width() - _dp(20), _dp(260))

func _on_details_carousel_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed:
			call_deferred("_snap_details_carousel_to_nearest")
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed:
			call_deferred("_snap_details_carousel_to_nearest")

func _restore_details_carousel_position() -> void:
	if not is_instance_valid(_details_carousel_scroll):
		return
	var bar := _details_carousel_scroll.get_h_scroll_bar()
	if bar == null:
		return
	bar.visible = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.value = float(_details_page_index * max(1, _details_preview_size()))
	_update_details_dots()
	if not bar.value_changed.is_connected(_on_details_carousel_value_changed):
		bar.value_changed.connect(_on_details_carousel_value_changed)

func _on_details_carousel_value_changed(value: float) -> void:
	var page_width: float = max(1.0, float(_details_preview_size()))
	_details_page_index = max(0, int(round(value / page_width)))
	_update_details_dots()

func _snap_details_carousel_to_nearest() -> void:
	if not is_instance_valid(_details_carousel_scroll):
		return
	var bar := _details_carousel_scroll.get_h_scroll_bar()
	if bar == null:
		return
	var page_width: float = max(1.0, float(_details_preview_size()))
	_details_page_index = max(0, int(round(float(bar.value) / page_width)))
	var target := float(_details_page_index) * page_width
	var tween := create_tween()
	tween.tween_property(bar, "value", target, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_update_details_dots()

func _details_dots(count: int) -> HBoxContainer:
	_details_carousel_dots.clear()
	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dots.add_theme_constant_override("separation", _dp(5))
	for i in range(count):
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(_dp(7), _dp(7))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_theme_stylebox_override("panel", _frame_style(Color("#B8C8D8"), Color("#B8C8D8"), 50, 0))
		dots.add_child(dot)
		_details_carousel_dots.append(dot)
	_update_details_dots()
	return dots

func _update_details_dots() -> void:
	for i in range(_details_carousel_dots.size()):
		var dot := _details_carousel_dots[i]
		if not is_instance_valid(dot):
			continue
		var active := i == _details_page_index
		dot.custom_minimum_size = Vector2(_dp(18 if active else 7), _dp(7))
		dot.add_theme_stylebox_override("panel", _frame_style(FIX_GREEN if active else Color("#B8C8D8"), FIX_GREEN if active else Color("#B8C8D8"), 50, 0))


func _media_textures(request: Dictionary) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var media: Variant = request.get("media", [])
	if media is Array:
		for item in media:
			if item is Dictionary:
				var path := str((item as Dictionary).get("path", ""))
				var texture := _texture_from_path(path)
				if texture != null:
					textures.append(texture)
	if textures.is_empty():
		var demo := _load_texture(DEMO_PHOTO_PATH)
		if demo != null:
			textures.append(demo)
	return textures

func _large_media_square(texture: Texture2D) -> Control:
	var side := _details_preview_size()
	var shell := Control.new()
	shell.custom_minimum_size = Vector2(side, side)
	shell.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	shell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shell.mouse_filter = Control.MOUSE_FILTER_PASS
	var image := ColorRect.new()
	image.set_anchors_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.color = Color.WHITE
	var material := ShaderMaterial.new()
	material.shader = _rounded_image_shader()
	material.set_shader_parameter("image_texture", texture)
	material.set_shader_parameter("rect_size", Vector2(side, side))
	material.set_shader_parameter("radius_px", float(_dp(18)))
	material.set_shader_parameter("border_width_px", float(_dp(3)))
	material.set_shader_parameter("border_color", BLUE)
	material.set_shader_parameter("bg_color", SOFT)
	image.material = material
	shell.add_child(image)
	return shell

func _contract_hero(request: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.98), BLUE, 22, 2))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", _dp(14))
	margin.add_theme_constant_override("margin_right", _dp(14))
	margin.add_theme_constant_override("margin_top", _dp(12))
	margin.add_theme_constant_override("margin_bottom", _dp(12))
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", _dp(6))
	margin.add_child(box)
	var title := _label(_request_title(request), 20, TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var subtitle := _label(_request_user(request) + " • " + _request_area(request), 13, MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(subtitle)
	box.add_child(_mini_badge(_status_text_short(request), _status_bg(request), _status_color(request)))
	return panel

func _info_section(title: String, lines: Array) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.98), BLUE, 22, 2))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", _dp(12))
	margin.add_theme_constant_override("margin_right", _dp(12))
	margin.add_theme_constant_override("margin_top", _dp(12))
	margin.add_theme_constant_override("margin_bottom", _dp(12))
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_theme_constant_override("separation", _dp(8))
	margin.add_child(box)
	var header := PanelContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_stylebox_override("panel", _style(BLUE, BLUE, 16, 0))
	var header_label := _label(title, 16, Color.WHITE)
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(header_label)
	box.add_child(header)
	for line in lines:
		box.add_child(_detail_line(str(line)))
	return panel

func _detail_line(text: String) -> PanelContainer:
	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", _style(SOFT, BORDER, 14, 1))
	var label := _label(text, 14, TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(label)
	return row

func _proposal_panel(request: Dictionary, request_id: String) -> PanelContainer:
	var amount := _proposal_amount_text(request)
	var message := str(request.get("provider_message", "Apasă Propune ca să trimiți o ofertă și un mesaj clientului."))
	var status := _status_text_short(request)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(GREEN_SOFT, FIX_GREEN, 22, 2))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", _dp(14))
	margin.add_theme_constant_override("margin_right", _dp(14))
	margin.add_theme_constant_override("margin_top", _dp(12))
	margin.add_theme_constant_override("margin_bottom", _dp(12))
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", _dp(8))
	margin.add_child(box)
	var title := _label("Ofertă și comunicare", 18, BLUE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var amount_chip := _info_chip("Ofertă: " + amount, Color.WHITE, BLUE)
	box.add_child(amount_chip)
	var status_chip := _info_chip("Status: " + status, Color.WHITE, _status_color(request))
	box.add_child(status_chip)
	var msg := _label("Mesaj: " + message, 13, TEXT)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(msg)
	box.add_child(_small_action_button("Editează mesaj/ofertă", false, func() -> void: _show_proposal_popup(request_id)))
	return panel

func _proposal_amount_text(request: Dictionary) -> String:
	var amount := str(request.get("proposed_amount", "")).strip_edges()
	if amount == "":
		return "Netrimisă"
	if amount.is_valid_int() or amount.is_valid_float():
		return amount + " lei"
	return amount

func _show_proposal_popup(request_id: String) -> void:
	var request := _request_by_id(request_id)
	if request.is_empty():
		return
	if is_instance_valid(_notice_overlay):
		_notice_overlay.queue_free()
	_notice_overlay = Control.new()
	_notice_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_notice_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_notice_overlay.z_index = 970
	add_child(_notice_overlay)
	var dim := ColorRect.new()
	dim.color = Color(1, 1, 1, 0.58)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_notice_overlay.add_child(dim)
	var scroll := UF_KEYBOARD_AWARE_SCROLL_SCRIPT.new()
	scroll.name = "ProposalKeyboardScroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_notice_overlay.add_child(scroll)
	var scroll_body := VBoxContainer.new()
	scroll_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_body.custom_minimum_size = get_viewport_rect().size
	scroll.add_child(scroll_body)
	var center := CenterContainer.new()
	center.custom_minimum_size = get_viewport_rect().size
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_body.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_dp(315), 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.98), BLUE, 24, 2))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dp(16))
	margin.add_theme_constant_override("margin_right", _dp(16))
	margin.add_theme_constant_override("margin_top", _dp(16))
	margin.add_theme_constant_override("margin_bottom", _dp(16))
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", _dp(10))
	margin.add_child(box)
	box.add_child(_headline("Propune oferta", 20))
	var amount := LineEdit.new()
	amount.placeholder_text = "Suma propusă, ex: 250"
	amount.text = str(request.get("proposed_amount", ""))
	amount.custom_minimum_size.y = _dp(46)
	amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	amount.focus_mode = Control.FOCUS_CLICK
	amount.add_theme_color_override("font_color", TEXT)
	amount.add_theme_color_override("font_placeholder_color", MUTED)
	amount.add_theme_color_override("caret_color", BLUE)
	amount.add_theme_stylebox_override("normal", _style(Color.WHITE, BORDER, 14, 1))
	amount.add_theme_stylebox_override("focus", _style(Color.WHITE, FIX_GREEN, 14, 2))
	_apply_font(amount, 13)
	box.add_child(amount)
	var message := TextEdit.new()
	message.placeholder_text = "Mesaj pentru client..."
	message.text = str(request.get("provider_message", "Bună! Pot prelua lucrarea. Îți propun această ofertă și pot începe după confirmarea ta."))
	message.custom_minimum_size.y = _dp(92)
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	message.add_theme_color_override("font_color", TEXT)
	message.add_theme_color_override("font_placeholder_color", MUTED)
	message.add_theme_color_override("caret_color", BLUE)
	message.add_theme_stylebox_override("normal", _style(Color.WHITE, BORDER, 14, 1))
	message.add_theme_stylebox_override("focus", _style(Color.WHITE, FIX_GREEN, 14, 2))
	_apply_font(message, 12)
	box.add_child(message)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _dp(8))
	box.add_child(row)
	row.add_child(_small_action_button("Renunță", false, func() -> void:
		if is_instance_valid(_notice_overlay):
			_notice_overlay.queue_free()
	))
	row.add_child(_small_action_button("Trimite", true, func() -> void:
		_submit_proposal(request_id, amount.text, message.text)
		if is_instance_valid(_notice_overlay):
			_notice_overlay.queue_free()
	))
	panel.scale = Vector2(0.92, 0.92)
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _submit_proposal(request_id: String, amount_text: String, message_text: String) -> void:
	var index := _find_request_index(request_id)
	if index < 0:
		return
	var request := _requests[index] as Dictionary
	var clean_amount := amount_text.strip_edges()
	request["proposed_amount"] = clean_amount if clean_amount != "" else "De stabilit"
	request["provider_message"] = message_text.strip_edges() if message_text.strip_edges() != "" else "Bună! Pot prelua lucrarea."
	request["provider_contacted"] = true
	request["status"] = "provider_contacted"
	_requests[index] = request
	_emit_change(true)

func _contract_box(request: Dictionary) -> PanelContainer:
	var proposal := _proposal_amount_text(request)
	return _info_section("Contract", [
		"Lucrare: " + _request_title(request),
		"Ofertă firmă: " + proposal,
		"Contractul se semnează după ce clientul acceptă oferta.",
		"Plata intră în escrow virtual după semnare.",
		"Încasarea se face doar după aprobarea clientului."
	])

func _payment_box(request: Dictionary) -> PanelContainer:
	return _info_section("Plată și închidere", [
		"Pas curent: " + _status_text_short(request),
		"Firma propune suma, clientul acceptă, apoi contractul blochează plata.",
		"După lucrare, firma trimite lucrarea la aprobare.",
		"Când clientul aprobă, plata se eliberează și cererea dispare din listă."
	])


func _go_back_in_flow() -> bool:
	if _selected_request_id.strip_edges() != "":
		_selected_request_id = ""
		_rebuild()
		return true
	return false

func _flow_step_for_request(request: Dictionary) -> int:
	var status := str(request.get("status", "public_waiting_provider"))
	match status:
		"provider_contacted": return 2
		"contract_signed", "work_in_progress": return 3
		"awaiting_user_approval": return 4
		_: return 1

func _flow_action_button(request: Dictionary, text: String, step: int, cb: Callable) -> Button:
	var current := _flow_step_for_request(request)
	var enabled := step == current
	var button := _small_action_button(text, enabled, cb)
	button.custom_minimum_size.y = _dp(46)
	button.disabled = not enabled
	button.modulate.a = 1.0
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_FORBIDDEN
	_apply_unlock_button_visual(button, enabled)
	return button

func _status_text_short(request: Dictionary) -> String:
	var status := str(request.get("status", "public_waiting_provider"))
	match status:
		"public_waiting_provider": return "Disponibilă"
		"provider_contacted": return "Acceptată"
		"contract_signed", "work_in_progress": return "Contract"
		"awaiting_user_approval": return "Aprobare"
		_: return "Disponibilă"

func _status_bg(request: Dictionary) -> Color:
	return GREEN_SOFT if _status_text_short(request) == "Disponibilă" else SOFT

func _status_color(request: Dictionary) -> Color:
	return FIX_GREEN if _status_text_short(request) == "Disponibilă" else BLUE

func _visible_requests() -> Array:
	var result: Array = []
	for item in _requests:
		if not (item is Dictionary):
			continue
		var request := item as Dictionary
		if _is_request_closed(request):
			continue
		if _matches_time(request) and _matches_type(request):
			result.append(request)
	return result

func _matches_time(request: Dictionary) -> bool:
	if _time_filter == "Toate":
		return true
	return str(request.get("urgency", "")) == _time_filter

func _matches_type(request: Dictionary) -> bool:
	if _type_filter == "Toate":
		return true
	return str(request.get("problem_category", "")) == _type_filter

func _is_request_closed(request: Dictionary) -> bool:
	var status := str(request.get("status", ""))
	return status == "closed" or status == "deleted"

func _request_title(request: Dictionary) -> String:
	var category := str(request.get("problem_category", "Lucrare"))
	if category == "Altele":
		var other := str(request.get("other_issue", "")).strip_edges()
		if other != "":
			category = other
	return category

func _request_user(request: Dictionary) -> String:
	var name := str(request.get("user_name", "")).strip_edges()
	if name != "":
		return name
	return "Client local"

func _request_area(request: Dictionary) -> String:
	var area := str(request.get("area", request.get("location", ""))).strip_edges()
	if area != "":
		return area
	return "Baia Mare"

func _request_price(request: Dictionary) -> String:
	if request.has("price"):
		return str(request.get("price"))
	return "250 lei"

func _payment_text(request: Dictionary) -> String:
	var payment := str(request.get("payment_status", "pending_offer"))
	match payment:
		"pending_offer": return "Costul va fi stabilit de firmă"
		"blocked_in_escrow": return "Plata este în siguranță"
		"released": return "Plata a fost trimisă"
		_: return payment

func _status_chip(request: Dictionary) -> PanelContainer:
	var status := str(request.get("status", "public_waiting_provider"))
	if status == "public_waiting_provider":
		return _info_chip(_work_status_label(request), GREEN_SOFT, FIX_GREEN)
	return _info_chip(_work_status_label(request), BLUE, Color.WHITE)

func _work_status_label(request: Dictionary) -> String:
	var status := str(request.get("status", "public_waiting_provider"))
	match status:
		"public_waiting_provider": return "Disponibilă"
		"provider_contacted": return "Contactat"
		"contract_signed": return "Contract"
		"work_in_progress": return "În lucru"
		"awaiting_user_approval": return "Aprobare"
		"closed": return "Finalizată"
		_: return "Disponibilă"


func _short_badge(text: String) -> String:
	var clean := text.replace("\n", " ").strip_edges()
	if clean.length() <= 12:
		return clean
	return clean.left(10) + "…"

func _short_payment(request: Dictionary) -> String:
	return _work_status_label(request)

func _first_media_texture(request: Dictionary) -> Texture2D:
	var media: Variant = request.get("media", [])
	if media is Array:
		for item in media:
			if item is Dictionary:
				var path := str((item as Dictionary).get("path", ""))
				var texture := _texture_from_path(path)
				if texture != null:
					return texture
	var demo := _load_texture(DEMO_PHOTO_PATH)
	return demo

func _load_texture(path: String) -> Texture2D:
	if path.strip_edges() == "" or not ResourceLoader.exists(path):
		return null
	var resource: Variant = load(path)
	if resource is Texture2D:
		return resource
	return null

func _texture_from_path(path: String) -> Texture2D:
	if path.strip_edges() == "":
		return null
	if path.begins_with("res://"):
		return _load_texture(path)
	var img := Image.new()
	var err := img.load(path)
	if err == OK and not img.is_empty():
		return ImageTexture.create_from_image(img)
	return null

func _request_by_id(request_id: String) -> Dictionary:
	for item in _requests:
		if item is Dictionary and str((item as Dictionary).get("id", "")) == request_id:
			return (item as Dictionary).duplicate(true)
	return {}

func _find_request_index(request_id: String) -> int:
	for i in range(_requests.size()):
		var item: Variant = _requests[i]
		if item is Dictionary and str((item as Dictionary).get("id", "")) == request_id:
			return i
	return -1

func _contact_client(request_id: String) -> void:
	var index := _find_request_index(request_id)
	if index < 0:
		return
	var request := _requests[index] as Dictionary
	request["provider_contacted"] = true
	request["status"] = "provider_contacted"
	request["provider_message"] = str(request.get("provider_message", "Bună! Sunt disponibil să preiau lucrarea. Îmi poți confirma adresa și intervalul dorit?"))
	if not request.has("proposed_amount"):
		request["proposed_amount"] = "De stabilit"
	_requests[index] = request
	_emit_change(true)
	_show_notice("Client contactat", "Am pregătit mesajul de contact și am mutat cererea în pasul de ofertă.")

func _sign_contract(request_id: String) -> void:
	var index := _find_request_index(request_id)
	if index < 0:
		return
	var request := _requests[index] as Dictionary
	request["contract_signed"] = true
	request["status"] = "contract_signed"
	request["payment_status"] = "blocked_in_escrow"
	request["contract_summary"] = "Contract demo: intervenție la domiciliu. Firma stabilește costul după evaluare, iar plata se eliberează doar după aprobarea clientului."
	_requests[index] = request
	_emit_change(true)
	_show_notice("Contract semnat", "Contractul demo este activ. Plata este blocată și nu poate fi eliberată până când clientul aprobă lucrarea.")

func _mark_work_done(request_id: String) -> void:
	var index := _find_request_index(request_id)
	if index < 0:
		return
	var request := _requests[index] as Dictionary
	request["work_done"] = true
	request["status"] = "awaiting_user_approval"
	if not request.has("payment_status") or str(request.get("payment_status", "")) == "":
		request["payment_status"] = "blocked_in_escrow"
	_requests[index] = request
	_emit_change(true)
	_show_notice("Lucrare trimisă la aprobare", "Clientul trebuie să confirme lucrarea. Până atunci, plata rămâne blocată.")

func _approve_close_delete(request_id: String) -> void:
	var index := _find_request_index(request_id)
	if index < 0:
		return
	_requests.remove_at(index)
	_selected_request_id = ""
	_emit_change(true)
	_show_notice("Cerere închisă", "Clientul a aprobat lucrarea, plata a fost eliberată, iar cererea a fost ștearsă din lista disponibilă.")

func _emit_change(rebuild_now: bool = true) -> void:
	requests_changed.emit(_requests.duplicate(true))
	if rebuild_now:
		_rebuild()

func _ensure_demo_requests() -> void:
	return

func _add_demo_requests(emit_update: bool = true) -> void:
	var now := Time.get_datetime_string_from_system()
	_requests.append({"id": "DEMO-PLUMBING", "created_at": now, "status": "public_waiting_provider", "problem_category": "Instalații", "urgency": "Urgent", "description": "Țeava de sub chiuvetă curge și udă dulapul. Clientul cere intervenție cât mai rapidă.", "price": "300 lei", "payment_status": "pending_offer", "user_name": "Andrei Popescu", "user_phone": "+40 721 000 111", "area": "Baia Mare - Centru", "media": []})
	_requests.append({"id": "DEMO-ELECTRIC", "created_at": now, "status": "public_waiting_provider", "problem_category": "Electric", "urgency": "Azi", "description": "Prizele din bucătărie nu mai funcționează după o pană de curent.", "price": "220 lei", "payment_status": "pending_offer", "user_name": "Maria Ionescu", "user_phone": "+40 733 000 222", "area": "Baia Mare - Vasile Alecsandri", "media": []})
	_requests.append({"id": "DEMO-PAINT", "created_at": now, "status": "public_waiting_provider", "problem_category": "Zugrăveli", "urgency": "2-3 zile", "description": "Perete afectat de infiltrații, trebuie curățat și reparat înainte de vopsire.", "price": "450 lei", "payment_status": "pending_offer", "user_name": "Radu Marin", "user_phone": "+40 744 000 333", "area": "Baia Mare - Săsar", "media": []})
	if emit_update:
		_emit_change(true)

func _empty_state() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.94), BORDER, 20, 1))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dp(18))
	margin.add_theme_constant_override("margin_right", _dp(18))
	margin.add_theme_constant_override("margin_top", _dp(26))
	margin.add_theme_constant_override("margin_bottom", _dp(26))
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", _dp(10))
	margin.add_child(box)
	box.add_child(_headline("Nu există lucrări", 19))
	var text := _center_text("Schimbă filtrele pentru a vedea alte lucrări disponibile.", 13)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text)
	return panel

func _price_badge(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_dp(58), _dp(30))
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	panel.add_theme_stylebox_override("panel", _style(BLUE, BLUE, 15, 0))
	var label := _center_text(text, 11)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	panel.add_child(label)
	return panel

func _mini_badge(text: String, bg: Color, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(0, _dp(26))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(bg, bg, 50, 0))
	var label := _center_text(text, 8)
	label.add_theme_color_override("font_color", color)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	panel.add_child(label)
	return panel


func _apply_unlock_button_visual(button: Button, enabled: bool) -> void:
	var fill := BLUE if enabled else Color(1, 1, 1, 0.0)
	var border := BLUE
	var text_color := Color.WHITE if enabled else BLUE
	var border_width := 0 if enabled else 3
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", text_color)
	button.add_theme_stylebox_override("normal", _style(fill, border, 14, border_width))
	button.add_theme_stylebox_override("hover", _style(fill, border, 14, border_width))
	button.add_theme_stylebox_override("pressed", _style(fill if enabled else SOFT, border, 14, border_width))
	button.add_theme_stylebox_override("disabled", _style(fill, border, 14, border_width))

func _small_action_button(text: String, primary: bool, cb: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = _dp(44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_apply_font(button, 11)
	var fill := BLUE if primary else Color.WHITE
	var border := BLUE
	var text_color := Color.WHITE if primary else BLUE
	var border_width := 0 if primary else 2
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_stylebox_override("normal", _style(fill, border, 13, border_width))
	button.add_theme_stylebox_override("hover", _style(fill, border, 13, border_width))
	button.add_theme_stylebox_override("pressed", _style(BLUE_DARK if primary else SOFT, border, 13, border_width))
	button.pressed.connect(cb)
	_make_bouncy(button)
	return button

func _show_notice(title_text: String, body_text: String) -> void:
	if is_instance_valid(_notice_overlay):
		_notice_overlay.queue_free()
	_notice_overlay = Control.new()
	_notice_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_notice_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_notice_overlay.z_index = 950
	add_child(_notice_overlay)
	var dim := ColorRect.new()
	dim.color = Color(1, 1, 1, 0.58)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_notice_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_dp(306), 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.97), BLUE, 24, 2))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dp(18))
	margin.add_theme_constant_override("margin_right", _dp(18))
	margin.add_theme_constant_override("margin_top", _dp(18))
	margin.add_theme_constant_override("margin_bottom", _dp(18))
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", _dp(12))
	margin.add_child(box)
	box.add_child(_headline(title_text, 20))
	var body := _center_text(body_text, 13)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	box.add_child(_small_action_button("Am înțeles", true, func() -> void:
		if is_instance_valid(_notice_overlay):
			_notice_overlay.queue_free()
		_rebuild()
	))
	panel.scale = Vector2(0.90, 0.90)
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _headline(text: String, font_size: int) -> Label:
	var label := _label(text, font_size, TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _center_text(text: String, font_size: int) -> Label:
	var label := _label(text, font_size, MUTED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", color)
	_apply_font(label, font_size)
	return label

func _gap(height: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size.y = _dp(height)
	return gap

func _style(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(_dp(width))
	style.set_corner_radius_all(_dp(radius))
	style.content_margin_left = _dp(8)
	style.content_margin_right = _dp(8)
	style.content_margin_top = _dp(5)
	style.content_margin_bottom = _dp(5)
	return style

func _frame_style(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := _style(bg, border, radius, width)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _make_bouncy(button: Button) -> void:
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.pivot_offset = button.custom_minimum_size * 0.5
	button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	button.button_down.connect(func() -> void: _bounce_to(button, Vector2(0.965, 0.965), 0.10, Tween.TRANS_SINE, Tween.EASE_OUT))
	button.button_up.connect(func() -> void: _bounce_to(button, Vector2.ONE, 0.24, Tween.TRANS_BACK, Tween.EASE_OUT))
	button.mouse_exited.connect(func() -> void: _bounce_to(button, Vector2.ONE, 0.20, Tween.TRANS_BACK, Tween.EASE_OUT))

func _bounce_to(control: Control, target: Vector2, duration: float, trans: Tween.TransitionType, ease_type: Tween.EaseType) -> void:
	if not is_instance_valid(control):
		return
	var tween := create_tween()
	tween.tween_property(control, "scale", target, duration).set_trans(trans).set_ease(ease_type)
