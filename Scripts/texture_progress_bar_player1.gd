extends TextureProgressBar

@export var player : Node
var a : int
# Called when the node enters the scene tree for the first time.
func _ready():
	player.hp = 0
	#print(player.cambio_vida)
	player.cambio_vida.connect(update)
	update()

func update():
	print(player.hp)
	value = player.hp * 100 / player.maxHealth
