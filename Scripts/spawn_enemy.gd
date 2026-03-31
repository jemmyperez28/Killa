extends Area2D

@onready var player = $"../player_test"

var enemy_scene = preload("res://Scenes/Enemy1.tscn")
var undead_scene = preload("res://Scenes/undead.tscn")
var lord_scene = preload("res://Scenes/lord.tscn")
var explosion_scene = preload("res://Scenes/explosion_lord.tscn")
var upgrade_menu_script = preload("res://Scripts/upgrade_menu.gd")

var random = RandomNumberGenerator.new()

# Wave system
const MAX_WAVES: int = 9
var current_wave: int = 0
var current_cycle: int = 1
var wave_in_cycle: int = 0
var kills_in_wave: int = 0
var wave_active: bool = false
var between_waves: bool = false

# Spawn timers
var enemy_timer: float = 0.0
var undead_timer: float = 0.0
var explosion_timer: float = 0.0
var explosion_interval: float = 5.0
var has_explosions: bool = false

# Current wave config
var enemies_to_kill: int = 0
var enemy_spawn_interval: float = 2.5
var undead_spawn_interval: float = 4.0
var max_enemies: int = 5
var max_undeads: int = 0
var enemy_alive: int = 0
var undead_alive: int = 0
var has_lord: bool = false
var lord_spawned: bool = false
var lord_alive: bool = false
var undeads_spawned: int = 0
var enemies_spawned: int = 0
var max_enemies_total: int = -1
var is_boss_wave: bool = false

# Wave announcement
var wave_label: Label = null

# Score points per kill
var score_enemy: int = 10
var score_undead: int = 25
var score_summon: int = 5
var score_lord: int = 100

func _ready():
	random.randomize()
	create_wave_label()
	start_next_wave()

func create_wave_label() -> void:
	wave_label = Label.new()
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_label.add_theme_font_size_override("font_size", 12)
	wave_label.add_theme_color_override("font_color", Color(1, 1, 1))
	wave_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	wave_label.add_theme_constant_override("shadow_offset_x", 2)
	wave_label.add_theme_constant_override("shadow_offset_y", 2)
	wave_label.anchors_preset = Control.PRESET_CENTER
	wave_label.position = Vector2(70, 60)
	wave_label.size = Vector2(200, 40)
	wave_label.visible = false

	var canvas = CanvasLayer.new()
	canvas.add_child(wave_label)
	add_child(canvas)

func start_next_wave() -> void:
	current_wave += 1
	wave_in_cycle += 1

	if wave_in_cycle > 3:
		wave_in_cycle = 1
		current_cycle += 1

	# Mostrar menu de mejora entre oleadas (excepto la primera)
	if current_wave > 1:
		await show_upgrade_menu()

	kills_in_wave = 0
	undeads_spawned = 0
	enemies_spawned = 0
	configure_wave()
	show_wave_announcement()

func configure_wave() -> void:
	var c = current_cycle

	match wave_in_cycle:
		1:
			enemies_to_kill = 6
			max_enemies_total = 6
			max_undeads = 0
			has_lord = false
			is_boss_wave = false
			has_explosions = false
		2:
			enemies_to_kill = 7 + (c - 1) * 3
			max_enemies_total = enemies_to_kill
			max_undeads = min(1 + (c - 1), 3)
			has_lord = false
			is_boss_wave = false
			has_explosions = true
		3:
			enemies_to_kill = -1
			max_enemies_total = -1
			max_undeads = min(2 + (c - 1), 3)
			has_lord = true
			is_boss_wave = true
			has_explosions = false

	if wave_in_cycle == 1:
		enemy_spawn_interval = 1.0
	else:
		enemy_spawn_interval = max(0.6, 2.5 - (c - 1) * 0.2)
	undead_spawn_interval = max(1.5, 4.0 - (c - 1) * 0.3)

	lord_spawned = false
	lord_alive = false

func show_wave_announcement() -> void:
	between_waves = true
	wave_active = false

	if current_wave == MAX_WAVES:
		wave_label.text = "WAVE FINAL\nKILL BOSS"
	elif is_boss_wave:
		wave_label.text = "WAVE " + str(current_wave) + "\nKILL BOSS"
	else:
		wave_label.text = "WAVE " + str(current_wave) + "\nGET READY"

	# Parpadeo durante 5 segundos
	var blink_time: float = 0.0
	wave_label.visible = true
	while blink_time < 5.0:
		wave_label.visible = true
		await get_tree().create_timer(0.4).timeout
		wave_label.visible = false
		await get_tree().create_timer(0.2).timeout
		blink_time += 0.6

	wave_label.visible = false
	between_waves = false
	wave_active = true
	enemy_timer = 0.0
	undead_timer = 0.0
	explosion_timer = 0.0

func _process(delta):
	if not wave_active or between_waves:
		return

	# Spawn calaberas
	enemy_timer += delta
	var can_spawn = enemy_alive < max_enemies and (max_enemies_total == -1 or enemies_spawned < max_enemies_total)
	if enemy_timer >= enemy_spawn_interval and can_spawn:
		enemy_timer = 0.0
		spawn_enemy()

	# Spawn undeads
	if max_undeads > 0:
		if is_boss_wave:
			# Boss wave: respawnean infinitamente
			undead_timer += delta
			if undead_timer >= undead_spawn_interval and undead_alive < max_undeads:
				undead_timer = 0.0
				spawn_undead()
		else:
			# Normal wave: solo se spawnean una vez
			if undeads_spawned < max_undeads:
				spawn_undead()

	# Spawn explosions (wave 2)
	if has_explosions:
		explosion_timer += delta
		if explosion_timer >= explosion_interval:
			explosion_timer = 0.0
			spawn_explosion_chain()

	# Spawn lord
	if has_lord and not lord_spawned:
		spawn_lord()

	# Check wave complete
	if is_boss_wave:
		# Boss wave: solo termina al matar al lord
		if lord_spawned and not lord_alive:
			wave_active = false
			clear_all_enemies()
			await get_tree().create_timer(1.5).timeout
			if current_wave >= MAX_WAVES:
				go_to_credits()
				return
			start_next_wave()
	else:
		if kills_in_wave >= enemies_to_kill and enemy_alive <= 0 and undead_alive <= 0:
			wave_active = false
			await get_tree().create_timer(1.5).timeout
			start_next_wave()

func spawn_enemy():
	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.position = Vector2(random.randi_range(350, 400), random.randi_range(30, 100))

	var enemy_level = max(1, current_wave + random.randi_range(-1, 1))

	if wave_in_cycle == 1:
		enemy_instance.drop_chance = 1.0

	add_child(enemy_instance)
	enemy_instance.set_level(enemy_level)
	enemy_alive += 1
	enemies_spawned += 1
	enemy_instance.tree_exited.connect(_on_enemy_killed.bind("enemy"))

func spawn_undead():
	var undead_instance = undead_scene.instantiate()

	var orbit_center: Vector2 = Vector2(random.randi_range(200, 280), random.randi_range(40, 90))
	var initial_angle: float = random.randf_range(0.0, TAU)

	var offset := Vector2(
		cos(initial_angle) * undead_instance.radius_x,
		sin(initial_angle) * undead_instance.radius_y
	)

	undead_instance.position = orbit_center + offset
	undead_instance.setup_orbit(orbit_center, initial_angle)

	var undead_level = max(1, player.level_player + 5 + (current_cycle - 1))

	add_child(undead_instance)
	undead_instance.set_level(undead_level)
	undead_alive += 1
	undeads_spawned += 1
	undead_instance.tree_exited.connect(_on_enemy_killed.bind("undead"))

func spawn_lord():
	lord_spawned = true
	lord_alive = true
	var lord_instance = lord_scene.instantiate()
	lord_instance.position = Vector2(400, 50)

	var lord_level = max(1, player.level_player + 8 + (current_cycle - 1) * 2)

	match current_cycle:
		1: lord_instance.attack_interval = 5.0
		2: lord_instance.attack_interval = 4.0
		3: lord_instance.attack_interval = 3.0

	add_child(lord_instance)
	lord_instance.set_level(lord_level)
	lord_instance.tree_exited.connect(_on_enemy_killed.bind("lord"))

func show_upgrade_menu() -> void:
	var menu = CanvasLayer.new()
	menu.set_script(upgrade_menu_script)
	menu.player = player
	get_tree().current_scene.add_child(menu)
	get_tree().paused = true
	await menu.upgrade_selected
	get_tree().paused = false

func clear_all_enemies() -> void:
	for child in get_children():
		if child is CharacterBody2D and child != player:
			child.queue_free()
	enemy_alive = 0
	undead_alive = 0

func _on_enemy_killed(type: String):
	match type:
		"enemy":
			enemy_alive = max(enemy_alive - 1, 0)
			kills_in_wave += 1
			if player != null:
				player.add_score(score_enemy * current_wave)
		"undead":
			undead_alive = max(undead_alive - 1, 0)
			if player != null:
				player.add_score(score_undead * current_wave)
		"lord":
			lord_alive = false
			if player != null:
				player.add_score(score_lord * current_wave)

func spawn_explosion_chain() -> void:
	var explosion_count: int = 18
	var explosion_spacing: float = 25.0
	var explosion_delay: float = 0.1
	var explosion_damage: float = 10.0 + (current_cycle - 1) * 5.0
	var start_x: float = 300.0
	var start_y: float = 197.0

	for i in range(explosion_count):
		if not wave_active:
			break
		var explosion = explosion_scene.instantiate()
		explosion.global_position = Vector2(start_x - i * explosion_spacing, start_y)
		explosion.damage = explosion_damage
		get_tree().current_scene.add_child(explosion)
		await get_tree().create_timer(explosion_delay).timeout

func go_to_credits() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/credits.tscn")
