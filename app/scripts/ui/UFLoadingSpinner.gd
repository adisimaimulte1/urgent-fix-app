extends Control

@export var spinner_color := Color("#02286E")
@export var line_width := 10.5
@export var speed := 5.2

var _angle := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(123, 123)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	_angle = fmod(_angle + speed * delta, TAU)
	queue_redraw()

func _draw() -> void:
	var radius := maxf(4.0, minf(size.x, size.y) * 0.5 - line_width)
	var center := size * 0.5
	draw_arc(center, radius, _angle, _angle + TAU * 0.72, 128, spinner_color, line_width, true)
