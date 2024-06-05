extends ProgressBar

@export var player : Node
var a : int
# Called when the node enters the scene tree for the first time.
func _ready():
	player.hp = 99
	player.cambio_vida.connect(update)
	update()

func update():
	#print(player.hp)
	value = player.hp * 100 / player.maxHealth
			
	#value = player.hp * 100 / player.maxHealth
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	value = player.hp * 100 / player.maxHealth
	
