extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var radius_x: float = 30.0
@export var radius_y: float = 50.0
@export var angular_speed: float = 1.5
@export var start_angle: float = 0.0

var center_position: Vector2
var angle: float = 0.0
var rng := RandomNumberGenerator.new()

var is_busy: bool = false
var orbit_initialized: bool = false  # 🔥 NUEVO

func _ready() -> void:
	rng.randomize()

	# 🔥 SOLO si no fue configurado desde el spawner
	if not orbit_initialized:
		center_position = position
		angle = start_angle

	animation_player.animation_finished.connect(_on_animation_player_animation_finished)

	if animation_player.has_animation("spawn"):
		is_busy = true
		animation_player.play("spawn")
	elif animation_player.has_animation("idle"):
		animation_player.play("idle")

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
	if anim_name == "spawn" or anim_name == "summon":
		is_busy = false
		if animation_player.has_animation("idle"):
			animation_player.play("idle")
