extends TileMap

var velocidad = 100
var tile_size = Vector2i(16, 16)  # Tamaño de los tiles, en tu caso 16x16
var camera_limit_right = 0  # Límite derecho de la cámara, ajusta según sea necesario
var base_y = 0  # Altura base inicial para agregar nuevos tiles
var tile_lifetime = 8.0  # Tiempo en segundos antes de eliminar los tiles

func _ready():
	# Obtén el límite derecho de la cámara (asumiendo que la cámara está centrada en la escena)
	camera_limit_right = get_viewport_rect().size.x * 2

	# Encuentra la altura base de los tiles iniciales
	base_y = find_base_y()
	
	# Configura temporizadores para los tiles iniciales
	setup_initial_tiles_timers()

func _process(delta):
	# Mueve el TileMap completo hacia la izquierda
	position.x -= velocidad * delta

	# Verifica si el último tile visible está saliendo de la pantalla
	var last_tile_position = position.x + (get_used_rect().size.x * tile_size.x)
	if last_tile_position < camera_limit_right:
		add_new_tiles()

func find_base_y() -> int:
	var used_rect = get_used_rect()
	for y in range(used_rect.position.y, used_rect.position.y + used_rect.size.y):
		for x in range(used_rect.position.x, used_rect.position.x + used_rect.size.x):
			var source_id = get_cell_source_id(0, Vector2i(x, y))
			if source_id != -1:
				return y
	return -1  # Devuelve -1 si no se encuentra ninguna altura base

func add_new_tiles():
	# Añade nuevos tiles al final de la derecha
	var tile_count = 10  # Número de tiles que deseas agregar, ajusta según sea necesario
	var start_position = get_used_rect().end.x  # Empieza desde el último tile actual

	if base_y == -1:
		base_y = 0

	for i in range(tile_count):
		var cell_position_top = Vector2i(start_position + i, base_y)
		var cell_position_bottom = Vector2i(start_position + i, base_y + 1)
		set_cell(0, cell_position_top, 0, Vector2i(0, 0), 0)  # Añade un tile en la nueva posición
		set_cell(0, cell_position_bottom, 0, Vector2i(1, 0), 0)  # Añade un tile debajo del nuevo tile
		start_timer_to_remove_tile(cell_position_top)
		start_timer_to_remove_tile(cell_position_bottom)

func setup_initial_tiles_timers():
	var used_rect = get_used_rect()
	for y in range(used_rect.position.y, used_rect.position.y + used_rect.size.y):
		for x in range(used_rect.position.x, used_rect.position.x + used_rect.size.x):
			var source_id = get_cell_source_id(0, Vector2i(x, y))
			if source_id != -1:
				var cell_position = Vector2i(x, y)
				start_timer_to_remove_tile(cell_position)

func start_timer_to_remove_tile(cell_position):
	var timer = Timer.new()
	timer.wait_time = tile_lifetime
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_tile_timeout").bind(cell_position))
	add_child(timer)
	timer.start()

func _on_tile_timeout(cell_position):
	set_cell(0, cell_position, -1)  # Elimina el tile de la posición especificada
