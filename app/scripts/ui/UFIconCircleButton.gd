extends Button
class_name UFIconCircleButton

var icon_texture: Texture2D
var icon_color := Color("#02286E")
var circle_color := Color.WHITE
var icon_scale := 0.46
var circle_ratio := 0.84

func _ready() -> void:
	text = ""
	flat = true
	focus_mode = Control.FOCUS_NONE
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)

func _draw() -> void:
	var d: float = minf(size.x, size.y) * circle_ratio
	var c := size * 0.5
	draw_circle(c, d * 0.5, circle_color)
	if icon_texture == null:
		return
	var icon_size := d * icon_scale
	var rect := Rect2(c - Vector2(icon_size, icon_size) * 0.5, Vector2(icon_size, icon_size))
	draw_texture_rect(icon_texture, rect, false, icon_color)
