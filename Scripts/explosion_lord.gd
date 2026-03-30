extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var damage: float = 10.0

func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	animation_player.play("explosion")

func _on_area_entered(area: Area2D) -> void:
	var target = area.get_parent()
	if target.is_in_group("player") and target.has_method("on_hit") and not target.hitted and not target.invulnerable:
		target.call("on_hit", damage)
	elif target.has_method("on_hit") and not target.is_in_group("player"):
		target.call("on_hit", damage, null, false)

func _on_animation_player_animation_finished(anim_name: String) -> void:
	if anim_name == "explosion":
		queue_free()
