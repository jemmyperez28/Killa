extends CharacterBody2D
@onready var animation = $Sprite2D/AnimationPlayer
var ice_particles_scene = preload("res://Scenes/ice_particles.tscn")
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 3000
var hp = 15
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
		emit_particles()
		animation.play("hit")
		hp -= dmg

func destroy():
	queue_free()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "hit":
		speed = 3000
		on_hit_bool = false
		animation.play("RESET")
		#Emision de particulas

func emit_particles():
	# Instanciar el nodo de partículas
	var ice_particles = ice_particles_scene.instantiate()  
	# Añadir el nodo de partículas como hijo del nodo actual (el enemigo)
	add_child(ice_particles)
	# Posicionar el nodo de partículas en la posición del enemigo
	ice_particles.global_position = global_position
	# Emitir partículas
	ice_particles.emitting = true
	ice_particles.restart()
	
	# Detener la emisión después de un breve período
	await get_tree().create_timer(0.1).timeout
	ice_particles.emitting = false
	# Opcional: Eliminar el nodo de partículas después de un tiempo para limpiar la escena
	await get_tree().create_timer(ice_particles.lifetime).timeout
	ice_particles.queue_free()
