extends Button
class_name UFActionButton

var icon_kind := ""
var icon_color := Color.WHITE
var arrow_color := Color.WHITE
var icon_size_dp := 32.0
var icon_texture: Texture2D
var arrow_texture: Texture2D

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)

func _draw() -> void:
	var h := size.y
	if h <= 0.0:
		return
	var k := h / 57.0
	var icon_size := icon_size_dp * k
	var cx := 32.0 * k
	var cy := h * 0.5
	if icon_texture != null:
		draw_texture_rect(icon_texture, Rect2(cx - icon_size * 0.5, cy - icon_size * 0.5, icon_size, icon_size), false, icon_color)
	var arrow_size := 20.0 * k
	if arrow_texture != null:
		draw_texture_rect(arrow_texture, Rect2(size.x - 31.0 * k - arrow_size * 0.5, cy - arrow_size * 0.5, arrow_size, arrow_size), false, arrow_color)
