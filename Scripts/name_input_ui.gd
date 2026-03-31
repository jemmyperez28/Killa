extends CanvasLayer

signal name_submitted(player_name: String)

var line_edit: LineEdit = null
var title_label: Label = null
var hint_label: Label = null
var score: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Fondo oscuro
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Titulo
	title_label = Label.new()
	title_label.text = "GAME OVER"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(60, 60)
	title_label.size = Vector2(200, 20)
	title_label.add_theme_font_size_override("font_size", 8)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title_label.add_theme_constant_override("shadow_offset_x", 1)
	title_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(title_label)

	# Score
	var score_label = Label.new()
	score_label.text = "Score: " + str(score)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.position = Vector2(60, 80)
	score_label.size = Vector2(200, 15)
	score_label.add_theme_font_size_override("font_size", 5)
	score_label.add_theme_color_override("font_color", Color(1, 1, 1))
	score_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	score_label.add_theme_constant_override("shadow_offset_x", 1)
	score_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(score_label)

	# Instruccion
	hint_label = Label.new()
	hint_label.text = "Enter your name:"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.position = Vector2(0, 100)
	hint_label.size = Vector2(320, 15)
	hint_label.add_theme_font_size_override("font_size", 4)
	hint_label.add_theme_color_override("font_color", Color(1, 1, 1))
	hint_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	hint_label.add_theme_constant_override("shadow_offset_x", 1)
	hint_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(hint_label)

	# Campo de texto
	line_edit = LineEdit.new()
	line_edit.placeholder_text = "NAME"
	line_edit.max_length = 12
	line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	line_edit.position = Vector2(90, 118)
	line_edit.size = Vector2(140, 18)
	line_edit.add_theme_font_size_override("font_size", 5)
	add_child(line_edit)

	line_edit.text_submitted.connect(_on_name_entered)
	line_edit.grab_focus()

func set_title(text: String) -> void:
	if title_label:
		title_label.text = text

func _on_name_entered(text: String) -> void:
	var player_name = text.strip_edges()
	if player_name == "":
		player_name = "UNKNOWN"

	hint_label.text = "Sending..."
	line_edit.editable = false

	RankingManager.submit_score(player_name, score)
	RankingManager.score_submitted.connect(_on_score_sent, CONNECT_ONE_SHOT)

func _on_score_sent(success: bool) -> void:
	if success:
		hint_label.text = "Score saved!"
	else:
		hint_label.text = "NO INTERNET CONNECTION"
		hint_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

	await get_tree().create_timer(2.0).timeout
	name_submitted.emit(line_edit.text.strip_edges())
	queue_free()
