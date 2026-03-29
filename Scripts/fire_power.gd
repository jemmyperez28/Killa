extends Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $HitBox/CollisionShape2D
@onready var fire1_sound = $Fire1
@onready var fire2_sound = $Fire2
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
	if randi() % 2 == 0:
		fire1_sound.play()
	else:
		fire2_sound.play()
	

func _on_animation_player_animation_finished(anim_name: String) -> void:
	if anim_name == "fire_idle":
		active = false
		visible = false
		collision_shape.disabled = true

func _on_hit_box_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()

	if enemy.has_method("on_hit"):
		var result = player.calculate_damage(player.fire_damage)
		var damage = result[0]
		var is_critical = result[1]
		enemy.call("on_hit", damage, player, is_critical)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
