class_name InventoryPerkIcon extends PanelContainer

const GOLDEN_PERK_COLOR: Color = Color("ffeb57")


var perk: GameData.Perks


@onready var texture: TextureRect = $TextureRect
@onready var focus_rect: NinePatchRect = $FocusAnchorPoint / FocusRect
@onready var count_panel_container: CountPanelContainer = $CountAnchorPoint / CountPanelContainer
@onready var level_label: LabelShadowed = $TextureRect / LevelLabel


static func create(parent: Node, perk_value: GameData.Perks) -> InventoryPerkIcon:
	var scene: PackedScene = preload("res://scenes/inventory_perk_icon.tscn")
	var icon: InventoryPerkIcon = scene.instantiate()

	parent.add_child(icon)

	icon.perk = perk_value

	if GameManager.get_perk_level(perk_value) == 5:
		icon.level_label.font_color = GOLDEN_PERK_COLOR
		icon.texture.texture = load("res://images/perks/%s_golden.png" % GameData.get_perk_name(perk_value).to_lower())
	else:
		icon.level_label.font_color = Color.WHITE
		icon.texture.texture = load("res://images/perks/%s.png" % GameData.get_perk_name(perk_value).to_lower())

	if perk_value == GameData.Perks.AUTOMAGIC or perk_value == GameData.Perks.PAUPER or perk_value == GameData.Perks.PERFECTION or perk_value == GameData.Perks.MOMENTUM:
		icon.count_panel_container.visible = true
	else:
		icon.count_panel_container.visible = false

	return icon


func _ready() -> void :
	mouse_entered.connect( func() -> void :
		_show_tooltip()
	)

	focus_entered.connect( func() -> void :
		focus_rect.visible = true
		_show_tooltip()
	)

	focus_exited.connect( func() -> void :
		focus_rect.visible = false
		Tooltip.disappear_animation(self)
	)

	mouse_exited.connect( func() -> void :
		Tooltip.disappear_animation(self)
	)


func _process(_delta: float) -> void :
	var perk_level: int = GameManager.get_perk_level(perk)

	if perk_level == 1:
		level_label.visible = false
	else:
		level_label.visible = true

	if perk_level == 2:
		level_label.text = "II"
	elif perk_level == 3:
		level_label.text = "III"
	elif perk_level == 4:
		level_label.text = "IV"
	elif perk_level == 5:

		level_label.text = "V"


	if perk == GameData.Perks.AUTOMAGIC:
		if is_instance_valid(GameManager.current_moving_piece):
			var time_remaining: int = ceili(3.0 - GameManager.current_moving_piece.time_since_spawn)
			count_panel_container.text = str(max(0, time_remaining))

	elif perk == GameData.Perks.PAUPER:
		var stack_count: int = GameManager.cumulative_perks.get(perk, 0)
		count_panel_container.text = "x" + str(stack_count)

	elif perk == GameData.Perks.PERFECTION:
		var stack_count: int = GameManager.cumulative_perks.get(perk, 0)
		count_panel_container.text = "x" + str(stack_count)

	elif perk == GameData.Perks.MOMENTUM:
		var board: Board = GameManager.get_board()
		count_panel_container.text = str(floori(max(0, board.momentum_perk_time_left)))


func _show_tooltip() -> void :
	var perk_key: String = GameData.get_perk_name(perk).to_upper()
	var perk_title: String = tr(perk_key)
	var perk_level: int = GameManager.get_perk_level(perk)


	if perk in GameManager.LEVELED_PERKS and perk_level > 1:
		if perk_level == 1:
			perk_title += " I"
		elif perk_level == 2:
			perk_title += " II"
		elif perk_level == 3:
			perk_title += " III"
		elif perk_level == 4:
			perk_title += " IV"
		elif perk_level == 5:
			perk_title += " V"


	var description_key: String = perk_key + "_DESCRIPTION"
	if perk in GameManager.LEVELED_PERKS and perk_level > 0:
		description_key = perk_key + "_DESCRIPTION_" + str(perk_level)

	var perk_description: String = tr(description_key)

	Tooltip.appear_animation(self, global_position + size / 2, perk_title, perk_description, Tooltip.AnchorMode.HORIZONTAL, Tooltip.MARGIN_DEFAULT, GOLDEN_PERK_COLOR if perk_level == 5 else Color.WHITE)


func pulse_animation() -> void :
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, 0.5).from(Vector2.ONE * 1.3)
	tween.tween_property(self, "modulate", Color.WHITE, 0.5).from(Color(1.5, 1.5, 1.5, 1.0))
	
