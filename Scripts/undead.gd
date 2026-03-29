extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var radius_x: float = 30.0
@export var radius_y: float = 50.0
@export var angular_speed: float = 1.5
@export var start_angle: float = 0.0

var center_position: Vector2
var angle: float = 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

	center_position = global_position
	angle = start_angle

	if animation_player.has_animation("idle"):
		animation_player.play("idle")

func _physics_process(delta: float) -> void:
	angle += angular_speed * delta

	var target_position := center_position + Vector2(
		cos(angle) * radius_x,
		sin(angle) * radius_y
	)

	velocity = (target_position - global_position) / delta
	move_and_slide()

func _on_timer_timeout() -> void:
	if rng.randi_range(0, 1) == 0:
		play_summon_animation()

func play_summon_animation() -> void:
	if animation_player.has_animation("summon"):
		animation_player.play("summon")
