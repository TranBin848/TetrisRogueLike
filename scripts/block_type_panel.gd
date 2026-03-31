class_name BlockTypePanel extends PanelContainer


var block_group: GameData.BlockGroups = GameData.BlockGroups.DEFAULT:
	set(value):
		block_group = value
		label.text = tr("BLOCK_GROUP_" + GameData.get_block_group_name(block_group))

		var group_color: Dictionary = GameData.GROUP_COLOR_MAP[block_group]

		self_modulate = group_color["background_color"]
		label.outline_color = group_color["font_shadow_color"]


@onready var label: LabelShadowed = $Label


func _notification(what: int) -> void :
	if not is_instance_valid(label):
		return

	if what == NOTIFICATION_TRANSLATION_CHANGED:
		label.text = tr("BLOCK_GROUP_" + GameData.get_block_group_name(block_group))
