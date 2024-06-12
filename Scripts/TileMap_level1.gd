extends TileMap

var velocidad = 100
var tile_size = Vector2i(16, 16)  # Tamaño de los tiles, en tu caso 16x16
var eliminar_x = -tile_size.x  # Punto en el eje X donde se eliminarán los tiles, ajusta según sea necesario
var tile_count = 10  # Número de tiles que deseas agregar, ajusta según sea necesario

func _ready():
	# Inicializa los primeros tiles
	add_initial_tiles()

func _process(delta):
	# Mueve el TileMap completo hacia la izquierda
	position.x -= velocidad * delta

	# Verifica y elimina los tiles que han salido de la pantalla
	check_and_remove_tiles()

	# Añade nuevos tiles si es necesario
	add_new_tiles_if_needed()

func check_and_remove_tiles():
	var used_rect = get_used_rect()
	for y in range(used_rect.position.y, used_rect.position.y + used_rect.size.y):
		for x in range(used_rect.position.x, used_rect.position.x + used_rect.size.x):
			var tile_position = map_to_local(Vector2(x, y))
			if tile_position.x < eliminar_x:
				print("elimine?")
				set_cell(0, Vector2i(x, y), -1)

func add_new_tiles_if_needed():
	var last_tile_position = map_to_local(Vector2i(get_used_rect().end.x, 0)).x + position.x
	if last_tile_position < get_viewport_rect().size.x:
		add_new_tiles()

func add_initial_tiles():
	var used_rect = get_used_rect()
	var start_position = used_rect.end.x
	var new_y = find_base_y()
	if new_y == -1:
		new_y = 0

	for i in range(tile_count):
		var cell_position_top = Vector2i(start_position + i, new_y)
		var cell_position_bottom = Vector2i(start_position + i, new_y + 1)
		set_cell(0, cell_position_top, 0, Vector2i(0, 0), 0)
		set_cell(0, cell_position_bottom, 0, Vector2i(1, 0), 0)

func add_new_tiles():
	var used_rect = get_used_rect()
	var start_position = used_rect.end.x
	var new_y = find_base_y()
	if new_y == -1:
		new_y = 0

	for i in range(tile_count):
		var cell_position_top = Vector2i(start_position + i, new_y)
		var cell_position_bottom = Vector2i(start_position + i, new_y + 1)
		set_cell(0, cell_position_top, 0, Vector2i(0, 0), 0)
		set_cell(0, cell_position_bottom, 0, Vector2i(1, 0), 0)

func find_base_y() -> int:
	var used_rect = get_used_rect()
	for y in range(used_rect.position.y, used_rect.position.y + used_rect.size.y):
		for x in range(used_rect.position.x, used_rect.position.x + used_rect.size.x):
			var source_id = get_cell_source_id(0, Vector2i(x, y))
			if source_id != -1:
				return y
	return -1  # Devuelve -1 si no se encuentra ninguna altura base
