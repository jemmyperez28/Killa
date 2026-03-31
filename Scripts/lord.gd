extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: ProgressBar = $ProgressBar
@onready var level_label = $LevelLavel
@onready var sprite = $Sprite2D

var ice_particles_scene = preload("res://Scenes/ice_particles.tscn")
var explosion_scene = preload("res://Scenes/explosion_lord.tscn")
var hp_potion_scene = preload("res://Scenes/hp_potion.tscn")
var mp_potion_scene = preload("res://Scenes/mp_potion.tscn")

@export var drop_chance: float = 0.0
@export var mp_drop_weight: float = 0.0

var rng := RandomNumberGenerator.new()
@export var explosion_count: int = 10
@export var explosion_spacing: float = 25.0
@export var explosion_delay: float = 0.1
@export var attack_chance: float = 0.8

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Stats base
var level: int = 1

@export var base_hp: float = 150.0
@export var base_damage: float = 10.0
@export var base_give_exp: float = 30.0

# Factores de crecimiento
@export var hp_growth: float = 1.15
@export var damage_growth: float = 1.10
@export var exp_growth: float = 1.25

# Stats finales
var hp: float = 0.0
var max_hp: float = 0.0
var damage: float = 0.0
var give_exp: float = 0.0

var on_hit_bool = false
var is_busy: bool = false

@export var target_x: float = 220.0
@export var walk_speed: float = 50.0
var reached_position: bool = false

var attack_timer: float = 0.0
@export var attack_interval: float = 3.0

func _ready() -> void:
	rng.randomize()
	apply_level_stats()
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	animation_player.play("idle")

func set_level(nivel: int) -> void:
	level = max(nivel, 1)
	if is_node_ready():
		apply_level_stats()

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

func _physics_process(delta: float) -> void:
	if not is_busy or not reached_position:
		velocity.y += gravity * delta
	else:
		velocity = Vector2.ZERO

	if not reached_position and not is_busy:
		if position.x > target_x:
			velocity.x = -walk_speed
		else:
			velocity.x = 0
			reached_position = true
	elif not is_busy:
		velocity.x = 0

	if reached_position and not is_busy and hp > 0:
		attack_timer += delta
		if attack_timer >= attack_interval:
			attack_timer = 0.0	
			if rng.randf() < attack_chance:
				start_attack()

	move_and_slide()

func on_hit(dmg, player_node, is_critical) -> void:
	if on_hit_bool == false:
		on_hit_bool = true

		DamageNumbers.display_number(dmg, global_position, is_critical)
		emit_particles()

		hp -= dmg
		health_bar.value = hp

		if hp <= 0:
			if player_node != null and player_node.has_method("get_exp"):
				player_node.call("get_exp", give_exp)
			destroy()
		else:
			start_blink()
			await get_tree().create_timer(0.3).timeout
			stop_blink()
			on_hit_bool = false

func destroy() -> void:
	drop_potion()
	is_busy = true
	collision_layer = 0
	collision_mask = 0
	health_bar.visible = false
	level_label.visible = false
	$Label.visible = false
	if animation_player.has_animation("death"):
		animation_player.play("death")
	else:
		queue_free()

func drop_potion() -> void:
	if randf() > drop_chance:
		return
	var potion
	if randf() < mp_drop_weight:
		potion = mp_potion_scene.instantiate()
	else:
		potion = hp_potion_scene.instantiate()
	potion.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", potion)

func start_attack() -> void:
	is_busy = true
	animation_player.play("attack")
	await get_tree().create_timer(0.42).timeout
	spawn_explosion_chain()

func spawn_explosion_chain() -> void:
	for i in range(explosion_count):
		if hp <= 0:
			break
		var explosion = explosion_scene.instantiate()
		explosion.global_position = Vector2(
			global_position.x - (i + 1) * explosion_spacing,
			global_position.y + 15
		)
		explosion.damage = damage
		get_tree().current_scene.add_child(explosion)
		await get_tree().create_timer(explosion_delay).timeout

func _on_animation_player_animation_finished(anim_name: String) -> void:
	if anim_name == "death":
		queue_free()
		return
	if anim_name == "attack":
		is_busy = false
		animation_player.play("idle")

func start_blink() -> void:
	while on_hit_bool:
		sprite.modulate.a = 0.3
		await get_tree().create_timer(0.08).timeout
		sprite.modulate.a = 1.0
		await get_tree().create_timer(0.08).timeout

func stop_blink() -> void:
	sprite.modulate.a = 1.0

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
