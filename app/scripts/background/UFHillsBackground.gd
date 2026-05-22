extends Control

func _draw() -> void:
	var s := get_rect().size
	var k := minf(s.x / 390.0, s.y / 844.0)
	k = clampf(k, 0.9, 1.25)
	var y := s.y - 104.0 * k
	var far := PackedVector2Array([Vector2(0, y + 28 * k), Vector2(0, y), Vector2(50 * k, y - 16 * k), Vector2(105 * k, y + 2 * k), Vector2(160 * k, y - 25 * k), Vector2(230 * k, y - 5 * k), Vector2(300 * k, y - 22 * k), Vector2(s.x, y), Vector2(s.x, s.y), Vector2(0, s.y)])
	draw_colored_polygon(far, Color("#AEE5F1"))
	var near := PackedVector2Array([Vector2(0, s.y), Vector2(0, y + 34 * k), Vector2(35 * k, y + 10 * k), Vector2(78 * k, y + 30 * k), Vector2(130 * k, y + 3 * k), Vector2(180 * k, y + 28 * k), Vector2(225 * k, y + 8 * k), Vector2(280 * k, y + 25 * k), Vector2(335 * k, y + 6 * k), Vector2(s.x, y + 22 * k), Vector2(s.x, s.y)])
	draw_colored_polygon(near, Color("#3DB8CA"))
	var step := int(44 * k)
	if step <= 0:
		step = 44
	for x in range(int(12 * k), int(s.x), step):
		var house_y := s.y - 34 * k - (x % 3) * 4 * k
		draw_rect(Rect2(x, house_y, 28 * k, 24 * k), Color("#EEF9FD"))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 3 * k, house_y), Vector2(x + 14 * k, house_y - 12 * k), Vector2(x + 31 * k, house_y)]), Color("#206EA7"))
		draw_rect(Rect2(x + 10 * k, house_y + 11 * k, 7 * k, 13 * k), Color("#167F9B"))
