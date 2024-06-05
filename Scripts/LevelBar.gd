extends TextureProgressBar

@export var player : Node
var a : int
# Called when the node enters the scene tree for the first time.
func _ready():
	#print(player.cambio_vida)
	#player.cambio_vida.connect(update)
	#player.set_exp.connect(update)
	player.connect("set_exp", Callable(self, "_update_exp"))
	_update_exp(player.current_exp, player.cap_level)
	#set_exp.emit(current_exp, cap_level)

func _update_exp(current_exp: int, cap_level: int):
	#print(player.current_exp)
	#value = current_exp * 100 / cap_level
	value = current_exp * 100 / cap_level
	#print("ENTRE")
	#print(value)
