extends Area2D

func _on_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy is CharacterBody2D and not enemy.is_in_group("player"):
		enemy.set_meta("killed_by_zone", true)
		enemy.queue_free()
