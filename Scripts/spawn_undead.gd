extends Area2D

@onready var undead = load("res://Scenes/undead.tscn")
@onready var player = $"../player_test"

var spawn = true
var random = RandomNumberGenerator.new()

@export var base_max_alive: int = 1
var alive_count: int = 0

func _ready():
	random.randomize()

func _process(delta):
	spawn_undead()

func spawn_undead():
	var max_alive := get_max_alive()

	if spawn == true and alive_count < max_alive:
		$Timer.start()
		spawn = false

		var undead_instance = undead.instantiate()

		var orbit_center: Vector2 = get_random_point_in_spawn_area()
		var initial_angle: float = random.randf_range(0.0, TAU)

		var offset := Vector2(
			cos(initial_angle) * undead_instance.radius_x,
			sin(initial_angle) * undead_instance.radius_y
		)

		undead_instance.position = orbit_center + offset
		undead_instance.setup_orbit(orbit_center, initial_angle)

		add_child(undead_instance)

		alive_count += 1
		undead_instance.tree_exited.connect(_on_undead_removed)

func _on_timer_timeout():
	spawn = true

func _on_undead_removed():
	alive_count = max(alive_count - 1, 0)

func get_max_alive() -> int:
	return 2
	# if player == null:
	# 	return base_max_alive
	#
	# var lvl: int = player.level_player
	#
	# if lvl < 5:
	# 	return 1
	# elif lvl < 10:
	# 	return 2
	# elif lvl < 15:
	# 	return 3
	# else:
	# 	return 4

func get_random_point_in_spawn_area() -> Vector2:
	var rect_shape = $CollisionShape2D.shape as RectangleShape2D
	var half_size: Vector2 = rect_shape.size / 2.0

	var local_point := Vector2(
		random.randf_range(-half_size.x, half_size.x),
		random.randf_range(-half_size.y, half_size.y)
	)

	return local_point
