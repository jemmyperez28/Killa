extends Control

@onready var title = $Title
@onready var options = [$Play, $Controls, $Ranking, $Exit]

var current_index: int = 0
var color_normal = Color(1, 1, 1)
var color_selected = Color(1, 0.85, 0.2)

func _ready() -> void:
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)

	for label in options:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)

	update_selection()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_down"):
		current_index = (current_index + 1) % options.size()
		update_selection()
	elif Input.is_action_just_pressed("ui_up"):
		current_index = (current_index - 1 + options.size()) % options.size()
		update_selection()
	elif Input.is_action_just_pressed("ui_accept"):
		select_option()

func update_selection() -> void:
	for i in range(options.size()):
		if i == current_index:
			options[i].add_theme_color_override("font_color", color_selected)
		else:
			options[i].add_theme_color_override("font_color", color_normal)

func select_option() -> void:
	match current_index:
		0: # Play
			get_tree().change_scene_to_file("res://Scenes/level_1.tscn")
		1: # Controls
			pass # TODO: mostrar pantalla de controles
		2: # Ranking
			pass # TODO: mostrar pantalla de ranking
		3: # Exit
			get_tree().quit()
