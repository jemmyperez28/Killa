extends TextureProgressBar

@export var player : Node
var a : int
# Called when the node enters the scene tree for the first time.
func _ready():
	#print(player.cambio_vida)
	player.mp = player.maxMP
	max_value = 100
	player.cambio_mana.connect(update)
	update()

func update():
	print("MANA : ", player.mp)
	#value = player.mp
	value = player.mp * 100 / player.maxMP
