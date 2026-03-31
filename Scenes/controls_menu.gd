extends Control

@onready var title = $Title
@onready var joystick_status = $JostickStatus
@onready var action_label = $ActionLabel
@onready var back_label = $Back

var action_keys: Array = []
var action_index: int = 0
var waiting_input: bool = false
var waiting_start: bool = true
var all_done: bool = false

var color_normal = Color(1, 1, 1)
var color_selected = Color(1, 0.85, 0.2)
var color_success = Color(0.3, 1, 0.3)

func _ready() -> void:
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)

	for label in [joystick_status, action_label, back_label]:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)

	action_keys = InputManager.actions.keys()
	update_joystick_status()
	InputManager.gamepad_status_changed.connect(_on_gamepad_changed)

	back_label.text = ""
	action_label.text = "Press ENTER or START\nto configure"
	action_label.add_theme_color_override("font_color", color_selected)

func update_joystick_status() -> void:
	if InputManager.gamepad_connected:
		joystick_status.text = "Joystick OK"
		joystick_status.add_theme_color_override("font_color", color_success)
	else:
		joystick_status.text = "Joystick NOT FOUND"
		joystick_status.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

func start_remap_flow() -> void:
	action_index = 0
	all_done = false
	show_current_action()

func show_current_action() -> void:
	if action_index >= action_keys.size():
		all_done = true
		waiting_input = false
		var current_key = InputManager.get_key_name(action_keys[action_keys.size() - 1])
		action_label.text = action_keys[action_keys.size() - 1].to_upper() + ": " + current_key
		action_label.add_theme_color_override("font_color", color_success)
		back_label.text = "DONE - Press ENTER"
		back_label.add_theme_color_override("font_color", color_selected)
		return

	var action = action_keys[action_index]
	var display_name = InputManager.actions[action]
	action_label.text = "Press key for " + display_name + "..."
	action_label.add_theme_color_override("font_color", color_selected)
	waiting_input = true

func _input(event: InputEvent) -> void:
	if waiting_start:
		var is_enter = event is InputEventKey and event.pressed and event.keycode == KEY_ENTER
		var is_start = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START
		if is_enter or is_start:
			get_viewport().set_input_as_handled()
			waiting_start = false
			start_remap_flow()
		return

	if waiting_input:
		if event is InputEventKey and event.pressed:
			var action = action_keys[action_index]
			InputManager.remap_key(action, event.physical_keycode)

			var key_name = OS.get_keycode_string(event.physical_keycode)
			action_label.text = InputManager.actions[action] + ": " + key_name
			action_label.add_theme_color_override("font_color", color_success)

			waiting_input = false
			get_viewport().set_input_as_handled()
			await get_tree().create_timer(0.5).timeout
			action_index += 1
			show_current_action()

		elif event is InputEventJoypadButton and event.pressed:
			var action = action_keys[action_index]
			InputManager.remap_pad(action, event.button_index)

			action_label.text = InputManager.actions[action] + ": Pad " + str(event.button_index)
			action_label.add_theme_color_override("font_color", color_success)

			waiting_input = false
			get_viewport().set_input_as_handled()
			await get_tree().create_timer(0.5).timeout
			action_index += 1
			show_current_action()

	elif all_done:
		var is_enter = event is InputEventKey and event.pressed and event.keycode == KEY_ENTER
		var is_start = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START
		if is_enter or is_start:
			get_viewport().set_input_as_handled()
			get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_gamepad_changed(_connected: bool) -> void:
	update_joystick_status()
