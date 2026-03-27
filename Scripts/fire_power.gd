extends Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $HitBox/CollisionShape2D
@onready var player = get_parent()

var active: bool = false
var damage: int = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false 
	collision_shape.disabled = true

func cast() -> void:
	if active:
		return

	active = true
	visible = true
	animation_player.play("fire_idle")

func _on_animation_player_animation_finished(anim_name: String) -> void:
	if anim_name == "fire_idle":
		active = false
		visible = false
		collision_shape.disabled = true



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
