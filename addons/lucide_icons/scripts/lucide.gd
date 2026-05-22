@tool
class_name Lucide
extends TextureRect

const ICON_ROOT := "res://addons/lucide_icons/icons/"

@export var icon_name := "menu":
	set(value):
		icon_name = value.strip_edges()
		_update_icon()

@export var icon_color := Color.WHITE:
	set(value):
		icon_color = value
		modulate = icon_color

@export_range(8.0, 128.0, 1.0) var icon_size := 24.0:
	set(value):
		icon_size = value
		custom_minimum_size = Vector2(icon_size, icon_size)
		_update_size()

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = icon_color
	_update_size()
	_update_icon()

func set_icon(name: String, color := Color.WHITE, size_px := 24.0) -> void:
	icon_name = name
	icon_color = color
	icon_size = size_px

func _update_size() -> void:
	custom_minimum_size = Vector2(icon_size, icon_size)
	size = Vector2(icon_size, icon_size)

func _update_icon() -> void:
	if icon_name.is_empty():
		texture = null
		return
	var path := ICON_ROOT + icon_name + ".svg"
	if ResourceLoader.exists(path):
		texture = load(path)
	else:
		texture = null
