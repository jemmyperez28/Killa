extends CharacterBody2D

enum State { IDLE, RUN, JUMP, ATTACK, HIT }
var current_state := State.IDLE
#Init Values
const SPEED = 450.0
const JUMP_VELOCITY = -250.0
var invulnerable = false
var hitted = false
#Affected by level values
@export var exp_increment_factor = 1.5
@export var level_player = 1
@export var sword_damage = 5
@export var maxHealth = 30
@export var cap_level = 30
@export var current_exp = 0
@onready var hp = maxHealth
#Initialize instances
@onready var hitTimer = $HitTimer
@onready var blinkTimer = $BlinkTimer
@onready var playerHurtBox = $HurtBox
@onready var sprite = $Sprite2D
@onready var label_level = $CanvasLayer/level
@onready var label_basic_damage = $CanvasLayer/basic_damage
#Signials
signal cambio_vida(valor)
signal set_exp(current_exp,cap_level)

#Levels multiplicators 

#State Animations
var state_animations = {
	State.IDLE: "run",
	State.RUN: "run",
	State.JUMP: ["jump_up", "jump_down"],
	State.ATTACK: "attack",
	State.HIT: "hit"
}

#Check current level for 

func _ready():
	label_level.text = str(level_player)
	label_basic_damage.text = str(sword_damage)
	current_state = State.IDLE
	cambio_vida.emit()
	set_exp.emit(current_exp, cap_level)
	
func _physics_process(delta):
	
	# Gravity
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	velocity.y += gravity * delta
	
	# Movement and State Transitionss
	if is_on_floor():
		# Horizontal movement with delta
		var movement_strength = (Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")) * 20.0
		velocity.x = movement_strength * SPEED * delta
		#print(velocity.x)
		# State transitions based on input
		if Input.is_action_just_pressed("ui_up"):
			velocity.y = JUMP_VELOCITY
			current_state = State.JUMP
		elif Input.is_action_just_pressed("attack"):
			current_state = State.ATTACK
	else:
		pass
	
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
	
	# Animation Control
	if current_state == State.JUMP:
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
	
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "attack":
		current_state = State.RUN  # Transition back to run after attack
	elif anim_name == "jump_down" and not is_on_floor():
		$Sprite2D/AnimationPlayer.seek(0.1)
	elif anim_name == "jump_down" and is_on_floor():
		current_state = State.RUN  # Transition back to run upon landing
	elif anim_name == "hit":
		if is_on_floor():
			current_state = State.RUN
		else:
			current_state = State.JUMP
func _on_hit_box_area_entered(area):
	#print("entro en contacto con" +str(area))
	var enemy = area.get_parent()
	if enemy.has_method("on_hit"):
		enemy.call("on_hit", sword_damage, self)

func on_hit(dmg):
	if not hitted and not invulnerable:
		#print("player on_hit")
		hitted = true
		invulnerable = true
		current_state = State.HIT
		hp -= dmg
		#Salto a la izquierda
		velocity.y = -200 #
		$Sprite2D/AnimationPlayer.play("hit")
		playerHurtBox.monitoring = false
		hitTimer.start()
		blinkTimer.start()
		cambio_vida.emit()

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

func get_exp(exp):
	current_exp += exp
	if current_exp > cap_level:
		level_up()
	set_exp.emit(current_exp, cap_level)
	
func level_up():
	level_player = level_player + 1 
	sword_damage = sword_damage + 3
	current_exp = current_exp - cap_level
	cap_level = int(cap_level * exp_increment_factor)  # Incrementa el cap_level exponencialmente
	label_level.text = str(level_player)
	label_basic_damage.text = str(sword_damage)
	
	
