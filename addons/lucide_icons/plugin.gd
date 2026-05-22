@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type(
		"Lucide",
		"TextureRect",
		preload("res://addons/lucide_icons/scripts/lucide.gd"),
		preload("res://addons/lucide_icons/plugin_icon.svg")
	)

func _exit_tree() -> void:
	remove_custom_type("Lucide")
