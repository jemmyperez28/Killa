extends CharacterBody2D
@onready var animation = $Sprite2D/AnimationPlayer

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 3000
var hp = 10
var on_hit_bool = false

func _physics_process(delta):
	velocity.x = -speed * delta
	velocity.y += gravity * delta
	if hp <= 0:
		destroy()
	move_and_slide()
	
func on_hit(dmg):
	if on_hit_bool == false:
		on_hit_bool = true
		speed = 0
		animation.play("hit")
		hp -= dmg

func destroy():
	queue_free()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "hit":
		speed = 3000
		on_hit_bool = false
		animation.play("RESET")
