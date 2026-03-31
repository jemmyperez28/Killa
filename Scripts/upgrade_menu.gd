extends CanvasLayer

signal upgrade_selected

var player: CharacterBody2D = null
var labels: Array[Label] = []
var current_index: int = 0

enum UpgradeType { ATK_PHYSICAL, ATK_MAGIC, HP_MAX, MP_MAX }

var all_upgrades = [
	{ "type": UpgradeType.ATK_PHYSICAL, "name": "ATK +5", "desc": "Physical damage +5" },
	{ "type": UpgradeType.ATK_MAGIC, "name": "MAGIC +5", "desc": "Magic power +5" },
	{ "type": UpgradeType.HP_MAX, "name": "HP +15", "desc": "Max HP +15 & full heal" },
	{ "type": UpgradeType.MP_MAX, "name": "MP +10", "desc": "Max MP +10 & full restore" },
]

var color_normal = Color(1, 1, 1)
var color_selected = Color(1, 0.85, 0.2)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	create_ui()
	update_selection()

func create_ui() -> void:
	var title = Label.new()
	title.text = "CHOOSE UPGRADE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.position = Vector2(100, 70)
	title.size = Vector2(200, 15)
	title.add_theme_font_size_override("font_size", 7)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	add_child(title)

	for i in range(all_upgrades.size()):
		var label = Label.new()
		label.text = all_upgrades[i]["name"] + " - " + all_upgrades[i]["desc"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.position = Vector2(100, 82 + i * 10)
		label.size = Vector2(200, 10)
		label.add_theme_font_size_override("font_size", 5)
		label.add_theme_color_override("font_color", color_normal)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		add_child(label)
		labels.append(label)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_down"):
		current_index = (current_index + 1) % all_upgrades.size()
		update_selection()
	elif Input.is_action_just_pressed("ui_up"):
		current_index = (current_index - 1 + all_upgrades.size()) % all_upgrades.size()
		update_selection()
	elif Input.is_action_just_pressed("ui_accept"):
		select_upgrade()

func update_selection() -> void:
	for i in range(labels.size()):
		if i == current_index:
			labels[i].add_theme_color_override("font_color", color_selected)
			labels[i].text = "> " + all_upgrades[i]["name"] + " - " + all_upgrades[i]["desc"] + " <"
		else:
			labels[i].add_theme_color_override("font_color", color_normal)
			labels[i].text = all_upgrades[i]["name"] + " - " + all_upgrades[i]["desc"]

func select_upgrade() -> void:
	var upgrade = all_upgrades[current_index]
	apply_upgrade(upgrade["type"])
	upgrade_selected.emit()
	queue_free()

func apply_upgrade(type: UpgradeType) -> void:
	if player == null:
		return

	match type:
		UpgradeType.ATK_PHYSICAL:
			player.base_damage += 5
			player.label_basic_damage.text = str(player.base_damage)
		UpgradeType.ATK_MAGIC:
			player.magic_power += 5
			player.label_magic_atack.text = str(player.magic_power)
		UpgradeType.HP_MAX:
			player.maxHealth += 15
			player.hp = player.maxHealth
			player.cambio_vida.emit()
		UpgradeType.MP_MAX:
			player.maxMP += 10
			player.mp = player.maxMP
			player.cambio_mana.emit()
