extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: ProgressBar = $ProgressBar
@onready var level_label = $LabelLeveL
@onready var sprite = $Sprite2D
@onready var hit_box = $HitBox
@onready var hurt_box = $HurtBox

var ice_particles_scene = preload("res://Scenes/ice_particles.tscn")
var summon_scene = preload("res://Scenes/summon.tscn")
var hp_potion_scene = preload("res://Scenes/hp_potion.tscn")
var mp_potion_scene = preload("res://Scenes/mp_potion.tscn")

@export var drop_chance: float = 0.5
@export var mp_drop_weight: float = 0.8

@export var summon_radius: float = 80.0

@export var radius_x: float = 30.0
@export var radius_y: float = 50.0
@export var angular_speed: float = 1.5
@export var start_angle: float = 0.0

# Stats base
var level: int = 10

@export var base_hp: float = 10.0
@export var base_damage: float = 7.5
@export var base_give_exp: float = 10.0

# Factores de crecimiento
@export var hp_growth: float = 1.25
@export var damage_growth: float = 1.12
@export var exp_growth: float = 1.25

# Stats finales
var hp: float = 0.0
var max_hp: float = 0.0
var damage: float = 0.0
var give_exp: float = 0.0

var on_hit_bool = false

var center_position: Vector2
var angle: float = 0.0
var rng := RandomNumberGenerator.new()

var is_busy: bool = false
var orbit_initialized: bool = false

func _ready() -> void:
	rng.randomize()

	if not orbit_initialized:
		center_position = position
		angle = start_angle

	apply_level_stats()

	animation_player.animation_finished.connect(_on_animation_player_animation_finished)

	if animation_player.has_animation("spawn"):
		is_busy = true
		animation_player.play("spawn")
	elif animation_player.has_animation("idle"):
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

func on_hit(dmg, player_node, is_critical) -> void:
	if on_hit_bool == false:
		on_hit_bool = true
		is_busy = true

		DamageNumbers.display_number(dmg, global_position, is_critical)
		emit_particles()

		hit_box.set_deferred("monitoring", false)

		hp -= dmg
		health_bar.value = hp

		if hp <= 0:
			if player_node != null and player_node.has_method("get_exp"):
				player_node.call("get_exp", give_exp)
			destroy()
		else:
			start_blink()
			await get_tree().create_timer(0.5).timeout
			stop_blink()
			hit_box.monitoring = true
			is_busy = false
			on_hit_bool = false

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

func destroy() -> void:
	drop_potion()
	hit_box.set_deferred("monitoring", false)
	hurt_box.set_deferred("monitorable", false)
	if animation_player.has_animation("death"):
		is_busy = true
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

# 🔥 NUEVA FUNCION (CLAVE)
func setup_orbit(center: Vector2, initial_angle: float) -> void:
	center_position = center
	angle = initial_angle
	orbit_initialized = true

func _physics_process(delta: float) -> void:
	if is_busy:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	angle += angular_speed * delta

	var target_position := center_position + Vector2(
		cos(angle) * radius_x,
		sin(angle) * radius_y
	)

	velocity = (target_position - position) / delta
	move_and_slide()

func _on_timer_timeout() -> void:
	if is_busy:
		return
	if rng.randi_range(0, 1) == 0:
		play_summon_animation()

func play_summon_animation() -> void:
	if animation_player.has_animation("summon"):
		is_busy = true
		velocity = Vector2.ZERO
		animation_player.play("summon")

func _on_animation_player_animation_finished(anim_name: String) -> void:
	if anim_name == "death":
		queue_free()
		return
	if anim_name == "summon":
		spawn_summon()
		is_busy = false
		if animation_player.has_animation("idle"):
			animation_player.play("idle")
	if anim_name == "spawn":
		is_busy = false
		if animation_player.has_animation("idle"):
			animation_player.play("idle")

func spawn_summon() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var random_angle = rng.randf_range(0, TAU)
	var random_dist = rng.randf_range(20.0, summon_radius)
	var offset = Vector2(cos(random_angle) * random_dist, sin(random_angle) * random_dist)

	var summon_instance = summon_scene.instantiate()
	summon_instance.global_position = global_position + offset
	summon_instance.setup(player, damage)
	get_tree().current_scene.add_child(summon_instance)

func _on_hit_box_area_entered(area: Area2D) -> void:
	var player = area.get_parent()
	if player.is_in_group("player") and player.has_method("on_hit") and not player.hitted and not player.invulnerable:
		player.call("on_hit", damage)
