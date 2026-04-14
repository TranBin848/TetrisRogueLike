class_name PerkButton extends Control

const MIN_MARGIN: int = 4
const GOLDEN_PERK_COLOR: Color = Color("ffeb57")

signal pressed()

var perk: GameData.Perks = GameData.Perks.NONE:
	set(value):
		perk = value

		if value == GameData.Perks.NONE:
			visible = false
			return

		visible = true
		var perk_name: String = GameData.get_perk_name(perk)
		var current_level: int = GameManager.get_perk_level(perk)


		var next_level: int = 1
		if perk in GameManager.LEVELED_PERKS:
			if current_level > 0:
				next_level = current_level + 1


		var description_key: String = perk_name + "_DESCRIPTION"
		if perk in GameManager.LEVELED_PERKS:
			description_key = perk_name + "_DESCRIPTION_" + str(next_level)

		var description_unformatted: String = tr(description_key)
		var icon_texture: CompressedTexture2D = load("res://images/perks/%s.png" % perk_name.to_lower())

		if next_level == 5:
			icon_texture = load("res://images/perks/%s_golden.png" % perk_name.to_lower())

		icon_1.texture = icon_texture
		icon_2.texture = icon_texture


		var display_name: String = tr(perk_name.to_upper())
		if perk in GameManager.LEVELED_PERKS and next_level > 1:
			if next_level == 2:
				display_name += " II"
			elif next_level == 3:
				display_name += " III"
			elif next_level == 4:
				display_name += " IV"
			elif next_level == 5:
				display_name += " V"

		title_label.text = display_name


		if perk in GameManager.LEVELED_PERKS and next_level == 5:
			title_label.font_color = GOLDEN_PERK_COLOR
		else:
			title_label.font_color = Color.WHITE

		description_label.text = GameManager.replace_tags(description_unformatted)

		await get_tree().process_frame

		custom_minimum_size = Vector2(200, 54).max(vbox_container.get_combined_minimum_size() + Vector2(0, MIN_MARGIN * 2))


var disabled: bool = false:
	set(value):
		disabled = value
		button.disabled = value


var shortcut: String = "1"


@onready var title_label: LabelShadowed = $VBoxContainer/TitleContainer/TitleLabel
@onready var icon_1: TextureRect = $VBoxContainer/TitleContainer/Icon_1
@onready var icon_2: TextureRect = $VBoxContainer/TitleContainer/Icon_2
@onready var vbox_container: VBoxContainer = $VBoxContainer
@onready var description_label: RichTextLabelShadowed = $VBoxContainer/DescriptionLabel
@onready var button: BouncyButton = $Button


func _ready() -> void :
	button.pressed.connect( func() -> void :
		pressed.emit()
	)


func _notification(what: int) -> void :
	if not is_instance_valid(title_label) or not is_instance_valid(description_label):
		return

	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if perk != GameData.Perks.NONE:
			var perk_name: String = GameData.get_perk_name(perk)
			var current_level: int = GameManager.get_perk_level(perk)
			var display_name: String = tr(perk_name.to_upper())
			var next_level: int = 1
			if perk in GameManager.LEVELED_PERKS:
				if current_level > 0:
					next_level = current_level + 1


			if perk in GameManager.LEVELED_PERKS and next_level > 1:
				if next_level == 2:
					display_name += " II"
				elif next_level == 3:
					display_name += " III"
				elif next_level == 4:
					display_name += " IV"
				elif next_level == 5:
					display_name += " V"

			title_label.text = display_name


			if perk in GameManager.LEVELED_PERKS and next_level == 5:
				title_label.font_color = GOLDEN_PERK_COLOR
			else:
				title_label.font_color = Color.WHITE


			var description_key: String = perk_name + "_DESCRIPTION"
			if perk in GameManager.LEVELED_PERKS:
				description_key = perk_name + "_DESCRIPTION_" + str(next_level)

			description_label.text = GameManager.replace_tags(tr(description_key))
