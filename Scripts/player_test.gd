extends CharacterBody2D

enum State { IDLE, RUN, JUMP, ATTACK, ATTACK_AIR, HIT }
var current_state := State.IDLE
#Init Values
var disable_inputs = false
const SPEED = 450.0
const JUMP_VELOCITY = -250.0
var invulnerable = false
var hitted = false
var air_hit_enemies := []
var defense: float = 0.0
#Affected by level values
@export var level_player = 1
@export var base_damage = 10
@export var maxHealth = 100
@export var base_cap_level = 30
@export var maxMP = 40
var cap_level: int = 30
@export var exp_increment_factor = 1.18
@export var current_exp = 0
@onready var hp = maxHealth
@onready var mp = maxMP
@export var critical_chance = 0.10 #0.05  # Probabilidad de crítico (5%)
@export var damage_variation = 5  # Variación de daño (+/- 2)
@export var magic_power = 10
#Initialize instances
@onready var hitTimer = $HitTimer
@onready var blinkTimer = $BlinkTimer
@onready var playerHurtBox = $HurtBox
@onready var sprite = $Sprite2D
@onready var fire_attack = $FirePower
@onready var hit_box_air_shape = $HitBoxAir/CollisionShape2D
@onready var label_level = $CanvasLayer/level
@onready var label_basic_damage = $CanvasLayer/basic_damage
@onready var label_magic_atack = $CanvasLayer/LabelMagicATK
@onready var label_debug = $CanvasLayer/debug
@onready var label_score = $CanvasLayer/score
#SOUNDS
@onready var attack_sound = $AttackSound
@onready var damage_sound = $DamageSound
@onready var no_mana = $NoManaSound
var fireball_scene = preload("res://Scenes/fire_ball_master.tscn")

var score: int = 0

#Signals
signal cambio_vida(valor)
signal cambio_mana(valor)
signal set_exp(current_exp,cap_level)
signal cambio_score(score)
signal level_up_signal
signal player_died

#DEBUG ZONE
var concatenado = " "

#Levels multiplicators 

#State Animations
var state_animations = {
	State.IDLE: "run",
	State.RUN: "run",
	State.JUMP: ["jump_up", "jump_down"],
	State.ATTACK: "attack",
	State.ATTACK_AIR: "attack_air",
	State.HIT: "hit"
}

func _ready():
	label_level.text = str(level_player)
	label_basic_damage.text = str(base_damage)
	label_magic_atack.text = str(magic_power)
	current_state = State.IDLE
	cambio_vida.emit()
	cambio_mana.emit()
	cap_level = get_cap_for_level(level_player)
	set_exp.emit(current_exp, cap_level)
	
func _physics_process(delta):
	if Input.is_action_just_pressed("fireball"):
		if mp >= 2:
			shoot_fireball()
			use_mana(2)
		else:
			no_mana.play()
			DamageNumbers.display_text("NO MANA", global_position + Vector2(-15, -20), "#4CC9FF")
	if Input.is_action_just_pressed("fire"):
		if mp >= 10:
			fire_attack.cast()
			use_mana(10)
		else:
			no_mana.play()
			DamageNumbers.display_text("NO MANA", global_position + Vector2(-15, -20), "#4CC9FF")
	#DEBUG ZONE
	#print(velocity.x)
	var state_name = state_animations[current_state] 
	concatenado = str(state_name) + " " + str(disable_inputs)
	label_debug.text = str(concatenado) 
	# Gravity
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	velocity.y += gravity * delta
	
	# Movement and State Transitionss
	if is_on_floor():
		# Horizontal movement with delta
		var movement_strength = (Input.get_action_strength("move_right") - Input.get_action_strength("move_left")) * 20.0
		#desactivar movimiento en otro estado
		if disable_inputs == false :
			velocity.x = movement_strength * SPEED * delta
		#print(velocity.x)
		# State transitions based on input
		if Input.is_action_just_pressed("jump") and disable_inputs == false:
			velocity.y = JUMP_VELOCITY
			current_state = State.JUMP
		elif Input.is_action_just_pressed("attack")  and disable_inputs == false:
			attack_sound.play()
			current_state = State.ATTACK
	else:
		if Input.is_action_just_pressed("attack") and disable_inputs == false and current_state != State.ATTACK_AIR:
			attack_sound.play()
			air_hit_enemies.clear()
			current_state = State.ATTACK_AIR
	
	#Hit State
	if current_state == State.HIT:
		# En el estado HIT, mantenemos la velocidad en X y aplicamos el brinco
		# La velocidad en X ya está configurada en `on_hit`
		# Solo aplicamos la gravedad aquí
		velocity.y += gravity * delta
		velocity.x = -150
	else:
		# Reset horizontal movement in other states
		pass
	
	if current_state == State.ATTACK:
		disable_inputs = true
		velocity.x = 0

	if current_state == State.ATTACK_AIR:
		disable_inputs = true
		if is_on_floor():
			hit_box_air_shape.disabled = true
			disable_inputs = false
			current_state = State.RUN
	
	# Animation Control
	if current_state == State.JUMP:
		disable_inputs = false
		if velocity.y > 0:  # Play jump_up when ascending
			#$Sprite2D/AnimationPlayer.set_speed_scale(3.0)
			$Sprite2D/AnimationPlayer.play("jump_down")
			
		else:  # Play jump_down when falling
			$Sprite2D/AnimationPlayer.play("jump_up")
	else:
		var animation_to_play = state_animations[current_state]
		if typeof(animation_to_play) == TYPE_ARRAY:
			for anim_name in animation_to_play:
				$Sprite2D/AnimationPlayer.play(anim_name)
		else:
			$Sprite2D/AnimationPlayer.play(animation_to_play)
	#print(current_exp)
	move_and_slide()
	#print("monitoring: ", playerHurtBox.monitoring)
	#print(invulnerable)
	#debug

func get_cap_for_level(nivel: int) -> int:
	return int((base_cap_level + nivel * 8) * pow(exp_increment_factor, nivel - 1))

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "attack":
		disable_inputs = false
		current_state = State.RUN
	elif anim_name == "attack_air":
		disable_inputs = false
		if is_on_floor():
			current_state = State.RUN
		else:
			current_state = State.JUMP
	elif anim_name == "jump_down" and not is_on_floor():
		$Sprite2D/AnimationPlayer.seek(0.1)
	elif anim_name == "jump_down" and is_on_floor():
		current_state = State.RUN  # Transition back to run upon landing
	elif anim_name == "hit":
		if is_on_floor():
			disable_inputs = false
			current_state = State.RUN
		else:
			disable_inputs = false
			current_state = State.JUMP
func _on_hit_box_area_entered(area):
	var enemy = area.get_parent()
	print("[ATAQUE ESPADA] golpeó a: ", enemy.name)
	if enemy.has_method("on_hit"):
		var result = calculate_damage(base_damage)
		var damage = result[0]
		var is_critical = result[1]
		enemy.call("on_hit", damage, self, is_critical)

func use_mana(mana):
	mp -= mana
	cambio_mana.emit()

func restore_health(amount):
	hp = min(hp + amount, maxHealth)
	cambio_vida.emit()
	pickup_flash()

func restore_mana(amount):
	mp = min(mp + amount, maxMP)
	cambio_mana.emit()
	pickup_flash()

func pickup_flash() -> void:
	sprite.modulate = Color(3, 3, 3, 1)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1, 1)

func add_score(points: int) -> void:
	score = max(score + points, 0)
	label_score.text = str(score) + " pts"
	cambio_score.emit(score)

func calculate_defense(dmg) -> int:
	var reduction = defense / (defense + 10.0)
	return max(1, int(dmg * (1.0 - reduction)))

func on_hit(dmg):
	if not hitted and not invulnerable:
		var final_dmg = calculate_defense(dmg)
		damage_sound.play()
		hitted = true
		invulnerable = true
		current_state = State.HIT
		hp -= final_dmg
		add_score(-5)
		cambio_vida.emit()
		if hp <= 0:
			die()
			return
		#Salto a la izquierda
		velocity.y = -200 #
		$Sprite2D/AnimationPlayer.play("hit")
		playerHurtBox.monitoring = false
		hitTimer.start()
		blinkTimer.start()

func die() -> void:
	disable_inputs = true
	invulnerable = true
	playerHurtBox.monitoring = false
	hitTimer.stop()
	blinkTimer.stop()
	velocity = Vector2.ZERO
	$Sprite2D/AnimationPlayer.play("hit")
	player_died.emit()

func _on_hit_timer_timeout():
	#print("Timer terminado")
	hitted = false
	invulnerable = false
	playerHurtBox.monitoring = true
	blinkTimer.stop()
	sprite.show()

func _on_blink_timer_timeout():
	if sprite.visible:
		sprite.hide()
	else:
		sprite.show()

#func get_exp(exp):
#	current_exp += exp
#	if current_exp > cap_level:
#		level_up()
#	set_exp.emit(current_exp, cap_level)

func get_exp(exp):
	current_exp += exp
	while current_exp >= cap_level:
		level_up()
	set_exp.emit(current_exp, cap_level)
	
func level_up():
	level_player = level_player + 1
	base_damage = base_damage + 5
	magic_power = magic_power + 2
	maxHealth += 6
	maxMP += 2
	current_exp = current_exp - cap_level
	cap_level = get_cap_for_level(level_player)
	label_level.text = str(level_player)
	label_basic_damage.text = str(base_damage)
	label_magic_atack.text = str(magic_power)
	cambio_vida.emit()
	cambio_mana.emit()
	level_up_signal.emit()
	
func calculate_damage(current_damage):
	var is_critical = false
	var random_variation = randi() % (damage_variation * 2 + 1) - damage_variation
	var damage = current_damage + random_variation
	if randf() < critical_chance:
		is_critical = true
		damage *= 3  # Daño crítico (doble de daño)
	return [damage, is_critical]
	
func shoot_fireball():
	var fireball_instance = fireball_scene.instantiate()
	fireball_instance.global_position = global_position
	fireball_instance.direction = 1
	fireball_instance.player = self
	get_tree().current_scene.add_child(fireball_instance)
	


func _on_hit_box_air_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	print("[ATAQUE AEREO] golpeó a: ", enemy.name)
	if enemy.has_method("on_hit") and enemy not in air_hit_enemies:
		air_hit_enemies.append(enemy)
		var result = calculate_damage(base_damage)
		var damage = result[0]
		var is_critical = result[1]
		enemy.call("on_hit", damage, self, is_critical)
