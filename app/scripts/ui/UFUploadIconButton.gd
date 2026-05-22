extends Button

var title := ""
var icon_texture: Texture2D
var icon_color := Color("#12BAC2")
var text_color := Color("#02286E")
var fallback_kind := "camera"
var icon_size_ratio := 0.34
var icon_top_ratio := 0.17
var label_bottom_ratio := 0.21

var _icon_rect: TextureRect
var _label: Label

func _ready() -> void:
	text = ""
	flat = false
	focus_mode = Control.FOCUS_NONE
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_build_visual_children()
	resized.connect(_sync_visual_children)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	toggled.connect(func(_pressed: bool) -> void: queue_redraw())
	_sync_visual_children()

func _build_visual_children() -> void:
	_icon_rect = TextureRect.new()
	_icon_rect.name = "LucideUploadIcon"
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_icon_rect)

	_label = Label.new()
	_label.name = "UploadLabel"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)

func _sync_visual_children() -> void:
	if is_instance_valid(_icon_rect):
		var icon_size := minf(size.x, size.y) * icon_size_ratio
		_icon_rect.size = Vector2(icon_size, icon_size)
		_icon_rect.position = Vector2((size.x - icon_size) * 0.5, size.y * icon_top_ratio)
		_icon_rect.texture = icon_texture
		_icon_rect.modulate = icon_color
		_icon_rect.visible = icon_texture != null

	if is_instance_valid(_label):
		_label.text = title
		_label.size = Vector2(size.x - 10.0, size.y * 0.30)
		_label.position = Vector2(5.0, size.y - size.y * label_bottom_ratio - _label.size.y * 0.5)
		_label.add_theme_color_override("font_color", text_color)
		var inherited_font := get_theme_font("font")
		var inherited_size := get_theme_font_size("font_size")
		if inherited_font != null:
			_label.add_theme_font_override("font", inherited_font)
		if inherited_size > 0:
			_label.add_theme_font_size_override("font_size", inherited_size)

func _draw() -> void:
	if icon_texture != null:
		return
	var c := Vector2(size.x * 0.5, size.y * icon_top_ratio + minf(size.x, size.y) * icon_size_ratio * 0.5)
	var d := minf(size.x, size.y) * icon_size_ratio
	var w := maxf(2.2, d * 0.075)
	if fallback_kind == "image":
		_draw_image_fallback(c, d, w)
	else:
		_draw_camera_fallback(c, d, w)

func _draw_camera_fallback(c: Vector2, d: float, w: float) -> void:
	var body := Rect2(c.x - d * 0.43, c.y - d * 0.20, d * 0.86, d * 0.58)
	_draw_rounded_outline(body, d * 0.10, icon_color, w)
	draw_line(Vector2(c.x - d * 0.24, c.y - d * 0.20), Vector2(c.x - d * 0.12, c.y - d * 0.38), icon_color, w, true)
	draw_line(Vector2(c.x - d * 0.12, c.y - d * 0.38), Vector2(c.x + d * 0.15, c.y - d * 0.38), icon_color, w, true)
	draw_line(Vector2(c.x + d * 0.15, c.y - d * 0.38), Vector2(c.x + d * 0.27, c.y - d * 0.20), icon_color, w, true)
	draw_arc(c + Vector2(0.0, d * 0.09), d * 0.18, 0.0, TAU, 44, icon_color, w, true)
	draw_circle(c + Vector2(d * 0.28, -d * 0.06), d * 0.035, icon_color)

func _draw_image_fallback(c: Vector2, d: float, w: float) -> void:
	var frame := Rect2(c.x - d * 0.43, c.y - d * 0.33, d * 0.86, d * 0.66)
	_draw_rounded_outline(frame, d * 0.09, icon_color, w)
	draw_arc(frame.position + Vector2(frame.size.x * 0.72, frame.size.y * 0.28), d * 0.07, 0.0, TAU, 24, icon_color, w, true)
	draw_polyline(PackedVector2Array([
		frame.position + Vector2(frame.size.x * 0.12, frame.size.y * 0.82),
		frame.position + Vector2(frame.size.x * 0.36, frame.size.y * 0.56),
		frame.position + Vector2(frame.size.x * 0.52, frame.size.y * 0.72),
		frame.position + Vector2(frame.size.x * 0.67, frame.size.y * 0.52),
		frame.position + Vector2(frame.size.x * 0.88, frame.size.y * 0.82)
	]), icon_color, w, true)

func _draw_rounded_outline(rect: Rect2, radius: float, color: Color, width: float) -> void:
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := rect.end.x
	var y1 := rect.end.y
	draw_line(Vector2(x0 + radius, y0), Vector2(x1 - radius, y0), color, width, true)
	draw_line(Vector2(x1, y0 + radius), Vector2(x1, y1 - radius), color, width, true)
	draw_line(Vector2(x1 - radius, y1), Vector2(x0 + radius, y1), color, width, true)
	draw_line(Vector2(x0, y1 - radius), Vector2(x0, y0 + radius), color, width, true)
	draw_arc(Vector2(x0 + radius, y0 + radius), radius, PI, PI * 1.5, 12, color, width, true)
	draw_arc(Vector2(x1 - radius, y0 + radius), radius, PI * 1.5, TAU, 12, color, width, true)
	draw_arc(Vector2(x1 - radius, y1 - radius), radius, 0.0, PI * 0.5, 12, color, width, true)
	draw_arc(Vector2(x0 + radius, y1 - radius), radius, PI * 0.5, PI, 12, color, width, true)
