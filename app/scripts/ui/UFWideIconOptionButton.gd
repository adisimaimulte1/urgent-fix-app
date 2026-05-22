extends Button
class_name UFWideIconOptionButton

var title := ""
var icon_texture: Texture2D
var icon_color := Color("#4F83D9")
var text_color := Color("#02286E")

func _ready() -> void:
	text = ""
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)

func _draw() -> void:
	var h := size.y
	var k := clampf(h / 52.0, 0.7, 2.0)
	var cx := 38.0 * k
	var cy := h * 0.5
	if icon_texture != null:
		var icon_size := 26.0 * k
		draw_texture_rect(icon_texture, Rect2(cx - icon_size * 0.5, cy - icon_size * 0.5, icon_size, icon_size), false, icon_color)
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	if font == null:
		return
	draw_string(font, Vector2(74.0 * k, cy + font_size * 0.35), title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
