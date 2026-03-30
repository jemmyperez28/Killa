extends CharacterBody2D

enum PotionType { HEALTH, MANA }

@export var potion_type: PotionType = PotionType.HEALTH
@export var restore_amount: int = 10
var speed: float = 200.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	if is_on_floor():
		velocity.x = -speed
	else:
		velocity.x = 0
	move_and_slide()

func _on_area_2d_area_entered(area: Area2D) -> void:
	var player = area.get_parent()
	if player.is_in_group("player"):
		if potion_type == PotionType.HEALTH and player.has_method("restore_health"):
			player.call("restore_health", restore_amount)
		elif potion_type == PotionType.MANA and player.has_method("restore_mana"):
			player.call("restore_mana", restore_amount)
		queue_free()
