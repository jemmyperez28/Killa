extends Control

@onready var title = $Title
@onready var options = [$Play, $Controls, $Ranking, $Exit]

var current_index: int = 0
var color_normal = Color(1, 1, 1)
var color_selected = Color(1, 0.85, 0.2)
var ranking_overlay: CanvasLayer = null
var showing_ranking: bool = false

func _ready() -> void:
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)

	for label in options:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)

	update_selection()

func _process(_delta: float) -> void:
	if showing_ranking:
		if Input.is_action_just_pressed("ui_cancel") or (Input.is_action_just_pressed("ui_accept") and showing_ranking):
			close_ranking()
		return

	if Input.is_action_just_pressed("ui_down"):
		current_index = (current_index + 1) % options.size()
		update_selection()
	elif Input.is_action_just_pressed("ui_up"):
		current_index = (current_index - 1 + options.size()) % options.size()
		update_selection()
	elif Input.is_action_just_pressed("ui_accept"):
		select_option()

func update_selection() -> void:
	for i in range(options.size()):
		if i == current_index:
			options[i].add_theme_color_override("font_color", color_selected)
		else:
			options[i].add_theme_color_override("font_color", color_normal)

func select_option() -> void:
	match current_index:
		0: # Play
			get_tree().change_scene_to_file("res://Scenes/level_1.tscn")
		1: # Controls
			get_tree().change_scene_to_file("res://Scenes/ControlsMenu.tscn")
		2: # Ranking
			show_ranking()
		3: # Exit
			get_tree().quit()

func show_ranking() -> void:
	showing_ranking = true
	ranking_overlay = CanvasLayer.new()

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ranking_overlay.add_child(bg)

	var title_label = Label.new()
	title_label.text = "TOP 10 RANKING"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(0, 20)
	title_label.size = Vector2(320, 20)
	title_label.add_theme_font_size_override("font_size", 7)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title_label.add_theme_constant_override("shadow_offset_x", 1)
	title_label.add_theme_constant_override("shadow_offset_y", 1)
	ranking_overlay.add_child(title_label)

	var loading_label = Label.new()
	loading_label.name = "RankingList"
	loading_label.text = "Loading..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.position = Vector2(0, 45)
	loading_label.size = Vector2(320, 150)
	loading_label.add_theme_font_size_override("font_size", 4)
	loading_label.add_theme_color_override("font_color", Color(1, 1, 1))
	loading_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	loading_label.add_theme_constant_override("shadow_offset_x", 1)
	loading_label.add_theme_constant_override("shadow_offset_y", 1)
	ranking_overlay.add_child(loading_label)

	var back_label = Label.new()
	back_label.text = "ESC or SELECT to go back"
	back_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_label.position = Vector2(0, 210)
	back_label.size = Vector2(320, 15)
	back_label.add_theme_font_size_override("font_size", 3)
	back_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	back_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	back_label.add_theme_constant_override("shadow_offset_x", 1)
	back_label.add_theme_constant_override("shadow_offset_y", 1)
	ranking_overlay.add_child(back_label)

	add_child(ranking_overlay)

	RankingManager.ranking_loaded.connect(_on_ranking_loaded, CONNECT_ONE_SHOT)
	RankingManager.fetch_ranking()

	# Timeout de 8 segundos
	await get_tree().create_timer(8.0).timeout
	if ranking_overlay != null:
		var list_label = ranking_overlay.get_node("RankingList")
		if list_label.text == "Loading...":
			list_label.text = "NO INTERNET CONNECTION"
			list_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

func _on_ranking_loaded(data: Array) -> void:
	if ranking_overlay == null:
		return
	var list_label = ranking_overlay.get_node("RankingList")
	if data.size() == 0:
		list_label.text = "No scores yet"
		return

	var text = ""
	for i in range(min(data.size(), 10)):
		var entry = data[i]
		text += str(i + 1) + ". " + str(entry["nombre"]) + " - " + str(int(entry["puntaje"])) + "\n"
	list_label.text = text

func close_ranking() -> void:
	showing_ranking = false
	if ranking_overlay != null:
		ranking_overlay.queue_free()
		ranking_overlay = null
