extends Node2D

@export var velocidad: float = 200.0
@export var y_fija: float = 200
@onready var pisos: Array[Sprite2D] = [
	$Piso1,
	$Piso2,
	$Piso3,
	$Piso4
]

func _ready():
	var x_actual: float = 0.0

	for piso in pisos:
		if piso.texture == null:
			push_error("El sprite %s no tiene textura." % piso.name)
			continue

		piso.centered = false

		# Mantener la Y actual que pusiste en el editor
		piso.position = Vector2(x_actual, piso.position.y)

		var ancho: float = piso.texture.get_size().x * abs(piso.scale.x)
		print(piso.name, " ancho = ", ancho, " x = ", piso.position.x)

		x_actual += ancho

func _process(delta):
	for piso in pisos:
		piso.position.x -= velocidad * delta
		piso.position.y = y_fija

	for piso in pisos:
		var ancho: float = piso.texture.get_size().x * abs(piso.scale.x)

		if piso.position.x + ancho < 0:
			var ultimo: Sprite2D = _get_piso_mas_derecha()
			var ancho_ultimo: float = ultimo.texture.get_size().x * abs(ultimo.scale.x)
			piso.position.x = ultimo.position.x + ancho_ultimo
			piso.position.y = y_fija

func _get_piso_mas_derecha() -> Sprite2D:
	var mas_derecha: Sprite2D = pisos[0]

	for piso in pisos:
		if piso.position.x > mas_derecha.position.x:
			mas_derecha = piso

	return mas_derecha
