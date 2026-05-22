extends Control

func _draw() -> void:
	var r := get_rect()
	draw_rect(r, Color("#F7FCFF"))
	for i in range(24):
		var t := float(i) / 23.0
		var c := Color("#E4F8FF").lerp(Color("#FDFEFF"), t)
		draw_rect(Rect2(0, r.size.y * t, r.size.x, r.size.y / 23.0 + 2.0), c)
