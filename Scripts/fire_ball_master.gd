extends Area2D
@onready var audio = $AudioStreamPlayer2D
var player = null

var speed: float = 350.0
var direction: int = 1
var fire_damage = 20
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("fireball creado")
	audio.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x += speed * direction * delta

func _on_area_entered(area: Area2D) -> void:
	print("colision con: ", area.name)
	var enemy = area.get_parent()
	if enemy.has_method("on_hit") and player != null:
		var result = player.calculate_damage(fire_damage)
		var damage = result[0]
		var is_critical = result[1]
		enemy.call("on_hit", damage, player, is_critical)
		queue_free()
