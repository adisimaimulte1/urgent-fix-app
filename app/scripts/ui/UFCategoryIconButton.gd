extends Button
class_name UFCategoryIconButton

var title := ""
var icon_texture: Texture2D
var icon_color := Color("#058C99")
var bubble_color := Color("#E9FCFD")
var text_color := Color("#02286E")

func _ready() -> void:
	text = ""
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)
	toggled.connect(func(_v: bool) -> void: queue_redraw())

func _draw() -> void:
	var k := clampf(size.y / 104.0, 0.7, 2.5)
	var bubble_size := minf(size.x * 0.56, 44.0 * k)
	var bubble_rect := Rect2((size.x - bubble_size) * 0.5, 13.0 * k, bubble_size, bubble_size)
	draw_circle(bubble_rect.get_center(), bubble_size * 0.5, bubble_color)
	if icon_texture != null:
		var icon_size := bubble_size * 0.66
		var icon_rect := Rect2(bubble_rect.position + (bubble_rect.size - Vector2(icon_size, icon_size)) * 0.5, Vector2(icon_size, icon_size))
		draw_texture_rect(icon_texture, icon_rect, false, icon_color)
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	if font == null:
		return
	var lines := title.split("\n")
	var line_h := float(font_size) + 2.0 * k
	var total_h := line_h * lines.size()
	var start_y := size.y - 18.0 * k - total_h + line_h * 0.75
	for i in range(lines.size()):
		var line := String(lines[i])
		var text_size := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2((size.x - text_size.x) * 0.5, start_y + line_h * i), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
