class_name BlockTypePanel extends PanelContainer


var block_group: GameData.BlockGroups = GameData.BlockGroups.DEFAULT:
	set(value):
		block_group = value
		_apply_block_group_visuals()


func _apply_block_group_visuals() -> void:
	if not is_instance_valid(label):
		return

	label.text = tr("BLOCK_GROUP_" + GameData.get_block_group_name(block_group))

	if not GameData.GROUP_COLOR_MAP.has(block_group):
		self_modulate = Color.WHITE
		return

	var group_color: Dictionary = GameData.GROUP_COLOR_MAP[block_group]

	self_modulate = group_color["background_color"]
	label.outline_color = group_color["font_shadow_color"]


@onready var label: LabelShadowed = $ShadowedLabel


func _ready() -> void:
	_apply_block_group_visuals()


func _notification(what: int) -> void :
	if not is_instance_valid(label):
		return

	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_apply_block_group_visuals()
