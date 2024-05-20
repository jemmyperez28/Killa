extends CharacterBody2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 3000
func _physics_process(delta):

	velocity.x = -speed * delta
	velocity.y += gravity * delta
	move_and_slide()

func destroy():
	queue_free()
