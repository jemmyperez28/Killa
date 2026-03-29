extends Node

func display_number(value:int , position: Vector2, is_critical:bool=false):
	var number = Label.new()
	number.global_position = position
	number.text = str(value)
	number.z_index = 5
	number.label_settings = LabelSettings.new() 
	
	var color = "#FFF"
	if is_critical:
		color = "#B22"
	if value == 0:
		color = "#FFF8"
	
	number.label_settings.font_color = color
	number.label_settings.font_size = 6
	number.label_settings.outline_color = "#000"
	number.label_settings.outline_size = 1
	
	call_deferred("add_child", number)		
	
	await number.resized
	number.pivot_offset = Vector2(number.size / 2)
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		number, "position:y", number.position.y - 24, 0.25
	).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		number, "position:y" , number.position.y,0.5
	).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.tween_property(
		number, "scale" , Vector2.ZERO,0.25
	).set_ease(Tween.EASE_IN).set_delay(0.5)
	
	await tween.finished
	number.queue_free()
	
func display_text(text_value:String, position: Vector2, color:String="#4CC9FF"):
	var label = Label.new()
	label.global_position = position
	label.text = text_value
	label.z_index = 5
	label.label_settings = LabelSettings.new()

	label.label_settings.font_color = color
	label.label_settings.font_size = 6
	label.label_settings.outline_color = "#000"
	label.label_settings.outline_size = 1

	call_deferred("add_child", label)

	await label.resized
	label.pivot_offset = label.size / 2

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		label, "position:y", label.position.y - 20, 0.35
	).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		label, "modulate:a", 0.0, 0.35
	).set_ease(Tween.EASE_IN)

	await tween.finished
	label.queue_free()
	
