extends Button
class_name UFPillIconButton

var title := ""
var icon_texture: Texture2D

const BLUE := Color("#02286E")
const WHITE := Color.WHITE

func _ready() -> void:
	text = ""
	flat = true
	focus_mode = Control.FOCUS_NONE
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	toggled.connect(func(_v: bool) -> void: queue_redraw())
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)

func _draw() -> void:
	var h := size.y
	var w := size.x
	if h <= 0.0 or w <= 0.0:
		return

	var k := clampf(h / 48.0, 0.75, 2.0)
	var selected := button_pressed
	var border_width := maxf(2.0 * k, 2.0)
	var radius := minf(h * 0.30, 12.0 * k)
	var fill_col := BLUE if selected else WHITE
	var border_col := WHITE if selected else BLUE
	_draw_rounded_mask(fill_col, border_col, radius, border_width)

	var col := WHITE if selected else BLUE
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	if font == null:
		return

	var icon_size := 16.5 * k
	var gap := 4.0 * k
	var lines := title.split("\n")
	var max_text_w := 0.0
	for raw_line in lines:
		var line := String(raw_line)
		max_text_w = maxf(max_text_w, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)

	var group_w := icon_size + gap + max_text_w
	var start_x := (w - group_w) * 0.5
	var text_x := start_x + icon_size + gap
	var cy := h * 0.5

	if icon_texture != null:
		draw_texture_rect(icon_texture, Rect2(start_x, cy - icon_size * 0.5, icon_size, icon_size), false, col)

	var line_h := float(font_size) + 1.0 * k
	if lines.size() == 1:
		var y := cy + float(font_size) * 0.36
		draw_string(font, Vector2(text_x, y), String(lines[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
	else:
		var total_h := line_h * float(lines.size())
		var first_y := cy - total_h * 0.5 + float(font_size) * 0.8
		for i in range(lines.size()):
			var line := String(lines[i])
			var line_w := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var line_x := text_x + (max_text_w - line_w) * 0.5
			draw_string(font, Vector2(line_x, first_y + line_h * float(i)), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)

func _draw_rounded_mask(fill_col: Color, border_col: Color, radius: float, border_width: float) -> void:
	var r := Rect2(Vector2.ZERO, size)
	var inner := r.grow(-border_width)
	_draw_rounded_rect(r, radius, border_col)
	_draw_rounded_rect(inner, maxf(0.0, radius - border_width), fill_col)

func _draw_rounded_rect(rect: Rect2, radius: float, color: Color) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	if r <= 0.0:
		draw_rect(rect, color, true)
		return
	draw_rect(Rect2(rect.position + Vector2(r, 0.0), Vector2(rect.size.x - 2.0 * r, rect.size.y)), color, true)
	draw_rect(Rect2(rect.position + Vector2(0.0, r), Vector2(rect.size.x, rect.size.y - 2.0 * r)), color, true)
	draw_circle(rect.position + Vector2(r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)
