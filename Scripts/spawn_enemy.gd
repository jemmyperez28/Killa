extends Area2D
@onready var enemy = load("res://Scenes/Enemy1.tscn")
@onready var lord_scene = load("res://Scenes/lord.tscn")
@onready var player = $"../player_test"
var spawn = true
var random = RandomNumberGenerator.new()
var lord_spawned = false

func _ready():
	random.randomize()
	spawn_lord()

func _process(delta):
	spawn_enemy()

func spawn_enemy():
	if spawn == true:
		$Timer.start()
		spawn = false
		var EnemyInstance = enemy.instantiate()
		EnemyInstance.position = Vector2(random.randi_range(350,400),random.randi_range(30,100))

		#Calculo del nivel enemigo en base a Player
		var min_level: int = max(1, player.level_player - 5)
		var max_level: int = max(1, player.level_player - 3)
		var enemy_level: int = random.randi_range(min_level, max_level)
		add_child(EnemyInstance)
		EnemyInstance.set_level(enemy_level)

func spawn_lord():
	if lord_spawned:
		return
	lord_spawned = true
	var lord_instance = lord_scene.instantiate()
	lord_instance.position = Vector2(400, 50)
	add_child(lord_instance)
	lord_instance.set_level(player.level_player)

func _on_timer_timeout():
	spawn = true
