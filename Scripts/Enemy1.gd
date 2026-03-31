extends CharacterBody2D

@onready var animation = $Sprite2D/AnimationPlayer
@onready var hit_box = $HitBox
@onready var damage_number_origin = $DamageNumberOrigin
@onready var health_bar: ProgressBar = $HealthBar
@onready var level_label = $LevelLabel

var ice_particles_scene = preload("res://Scenes/ice_particles.tscn")
var hp_potion_scene = preload("res://Scenes/hp_potion.tscn")
var mp_potion_scene = preload("res://Scenes/mp_potion.tscn")

@export var drop_chance: float = 0.3
@export var hp_drop_weight: float = 0.8

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 3000.0

# Stats Variables
var level: int = 1

@export var base_hp: float = 10.0
@export var base_damage: float = 7.5
@export var base_give_exp: float = 10.0

# Factores de crecimiento
@export var hp_growth: float = 1.35
@export var damage_growth: float = 1.14
@export var exp_growth: float = 1.25

# Stats finales
var hp: float = 0.0
var max_hp: float = 0.0
var damage: float = 0.0
var give_exp: float = 0.0

var on_hit_bool = false

# FUNCION DE SETEO DE NIVEL
func set_level(nivel: int) -> void:
	level = max(nivel, 1)
	if is_node_ready():
		apply_level_stats()

# FUNCION QUE APLICA LOS STATS SEGUN EL NIVEL
func apply_level_stats() -> void:
	var lvl_factor: int = max(level - 1, 0)

	max_hp = base_hp * pow(hp_growth, lvl_factor)
	hp = max_hp
	damage = base_damage * pow(damage_growth, lvl_factor)
	give_exp = base_give_exp * pow(exp_growth, lvl_factor)

	hp = round(hp)
	max_hp = round(max_hp)
	damage = round(damage)
	give_exp = round(give_exp)

	health_bar.max_value = max_hp
	health_bar.value = hp
	
	level_label.text = str(level)

func on_hit(dmg, player_node, is_critical) -> void:
	if on_hit_bool == false:
		on_hit_bool = true
		speed = 0

		DamageNumbers.display_number(dmg, damage_number_origin.global_position, is_critical)
		emit_particles()
		animation.play("hit")

		hp -= dmg
		health_bar.value = hp

		if hp <= 0:
			if player_node != null and player_node.has_method("get_exp"):
				player_node.call("get_exp", give_exp)
			else:
				pass
			destroy()


func destroy() -> void:
	drop_potion()
	queue_free()

func drop_potion() -> void:
	if randf() > drop_chance:
		return
	var potion
	if randf() < hp_drop_weight:
		potion = hp_potion_scene.instantiate()
	else:
		potion = mp_potion_scene.instantiate()
	potion.global_position = global_position
	get_tree().current_scene.add_child(potion)

func _on_animation_player_animation_finished(anim_name) -> void:
	if anim_name == "hit":
		speed = 3000
		on_hit_bool = false
		animation.play("idle")

func emit_particles() -> void:
	var ice_particles = ice_particles_scene.instantiate()
	add_child(ice_particles)
	ice_particles.global_position = global_position
	ice_particles.emitting = true
	ice_particles.restart()

	await get_tree().create_timer(0.1).timeout
	ice_particles.emitting = false

	await get_tree().create_timer(ice_particles.lifetime).timeout
	ice_particles.queue_free()

func _on_hit_box_area_entered(area) -> void:
	var player = area.get_parent()
	if player.is_in_group("player") and player.has_method("on_hit") and not player.hitted and not player.invulnerable:
		player.call("on_hit", damage)

func _ready() -> void:
	apply_level_stats()
	animation.play("idle")

func _physics_process(delta) -> void:
	velocity.x = -speed * delta
	velocity.y += gravity * delta
	move_and_slide()
