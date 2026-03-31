extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var hit_box = $HitBox

var hp_potion_scene = preload("res://Scenes/hp_potion.tscn")
var mp_potion_scene = preload("res://Scenes/mp_potion.tscn")

@export var drop_chance: float = 1.0
@export var mp_drop_weight: float = 0.8

var speed: float = 80.0
var direction: Vector2 = Vector2.ZERO
var player: CharacterBody2D = null
var damage: float = 5.0
var is_busy: bool = false

func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	is_busy = true
	animation_player.play("new")

func setup(target: CharacterBody2D, dmg: float) -> void:
	player = target
	damage = dmg

func _physics_process(delta: float) -> void:
	if is_busy or player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	direction = (player.global_position - global_position).normalized()
	sprite.flip_h = direction.x > 0
	velocity = direction * speed
	move_and_slide()

func on_hit(_dmg, _player_node, _is_critical) -> void:
	DamageNumbers.display_number(_dmg, global_position, _is_critical)
	if _player_node != null and _player_node.has_method("add_score"):
		_player_node.add_score(5)
	destroy()

func destroy() -> void:
	drop_potion()
	is_busy = true
	hit_box.set_deferred("monitoring", false)
	collision_layer = 0
	collision_mask = 0
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

func _on_animation_player_animation_finished(anim_name: String) -> void:
	if anim_name == "death":
		queue_free()
		return
	if anim_name == "new":
		is_busy = false
		animation_player.play("idle")

func _on_hit_box_area_entered(area: Area2D) -> void:
	var target = area.get_parent()
	if target.is_in_group("player") and target.has_method("on_hit") and not target.hitted and not target.invulnerable:
		target.call("on_hit", damage)
		destroy()
