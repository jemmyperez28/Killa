extends Node

const CONFIG_PATH = "user://input_config.cfg"

# Acciones del juego (no incluye ui_up/down/accept que son para menus)
var actions = {
	"move_left": "Mover Izquierda",
	"move_right": "Mover Derecha",
	"jump": "Salto",
	"attack": "Espada",
	"fireball": "Fireball",
	"fire": "Fire Attack",
}

# Teclas por defecto (keyboard)
var default_keys = {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"jump": KEY_J,
	"attack": KEY_K,
	"fireball": KEY_I,
	"fire": KEY_U,
}

# Botones de gamepad por defecto
var default_pad = {
	"move_left": JOY_AXIS_LEFT_X,  # se maneja como eje
	"move_right": JOY_AXIS_LEFT_X, # se maneja como eje
	"jump": JOY_BUTTON_A,
	"attack": JOY_BUTTON_X,
	"fireball": JOY_BUTTON_B,
	"fire": JOY_BUTTON_Y,
}

var gamepad_connected: bool = false

signal gamepad_status_changed(connected: bool)

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	gamepad_connected = Input.get_connected_joypads().size() > 0
	setup_actions()
	load_config()

func setup_actions() -> void:
	for action in actions.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)

	# Asignar teclas por defecto
	for action in default_keys:
		var event = InputEventKey.new()
		event.physical_keycode = default_keys[action]
		InputMap.action_add_event(action, event)

	# Agregar START del gamepad a ui_accept (menus)
	var start_event = InputEventJoypadButton.new()
	start_event.button_index = JOY_BUTTON_START
	InputMap.action_add_event("ui_accept", start_event)

	# Asignar gamepad por defecto
	for action in default_pad:
		if action == "move_left":
			var event = InputEventJoypadMotion.new()
			event.axis = JOY_AXIS_LEFT_X
			event.axis_value = -1.0
			InputMap.action_add_event(action, event)
		elif action == "move_right":
			var event = InputEventJoypadMotion.new()
			event.axis = JOY_AXIS_LEFT_X
			event.axis_value = 1.0
			InputMap.action_add_event(action, event)
		else:
			var event = InputEventJoypadButton.new()
			event.button_index = default_pad[action]
			InputMap.action_add_event(action, event)

func remap_key(action: String, keycode: int) -> void:
	# Eliminar solo eventos de teclado, mantener gamepad
	var pad_events = []
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			pad_events.append(event)

	InputMap.action_erase_events(action)

	# Re-agregar pad events
	for event in pad_events:
		InputMap.action_add_event(action, event)

	# Agregar nueva tecla
	var new_event = InputEventKey.new()
	new_event.physical_keycode = keycode
	InputMap.action_add_event(action, new_event)

	save_config()

func remap_pad(action: String, button_index: int) -> void:
	# Eliminar solo eventos de gamepad button, mantener teclado
	var key_events = []
	var motion_events = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			key_events.append(event)
		elif event is InputEventJoypadMotion:
			motion_events.append(event)

	InputMap.action_erase_events(action)

	for event in key_events:
		InputMap.action_add_event(action, event)
	for event in motion_events:
		InputMap.action_add_event(action, event)

	var new_event = InputEventJoypadButton.new()
	new_event.button_index = button_index
	InputMap.action_add_event(action, new_event)

	save_config()

func get_key_name(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode)
	return "---"

func get_pad_name(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			return "Pad " + str(event.button_index)
	return "---"

func save_config() -> void:
	var config = ConfigFile.new()
	for action in actions.keys():
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				config.set_value("keyboard", action, event.physical_keycode)
			elif event is InputEventJoypadButton:
				config.set_value("gamepad", action, event.button_index)
	config.save(CONFIG_PATH)

func load_config() -> void:
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return

	# Cargar teclas de teclado
	if config.has_section("keyboard"):
		for action in config.get_section_keys("keyboard"):
			if actions.has(action):
				var keycode = config.get_value("keyboard", action)
				remap_key(action, keycode)

	# Cargar botones de gamepad
	if config.has_section("gamepad"):
		for action in config.get_section_keys("gamepad"):
			if actions.has(action):
				var button = config.get_value("gamepad", action)
				remap_pad(action, button)

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	gamepad_connected = Input.get_connected_joypads().size() > 0
	gamepad_status_changed.emit(gamepad_connected)
