extends Area2D
@onready var enemy = load("res://Scenes/Enemy1.tscn")
var spawn = true
var random = RandomNumberGenerator.new()

func _ready():
	random.randomize()

func _process(delta):
	spawn_enemy()

func spawn_enemy():
	if spawn == true:
		$Timer.start()
		spawn = false
		var EnemyInstance = enemy.instantiate()
		EnemyInstance.position = Vector2(random.randi_range(350,400),random.randi_range(30,100))
		add_child(EnemyInstance)
		
func _on_timer_timeout():
	spawn = true
