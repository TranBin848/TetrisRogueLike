class_name BossInformationPanel extends PanelContainer


@onready var boss_title_label: LabelShadowed = %BossTitleLabel
@onready var title_container: HBoxContainer = %TitleContainer
@onready var description_label: RichTextLabelShadowed = %DescriptionLabel
@onready var boss_icon_1: TextureRect = %BossIcon_1
@onready var boss_icon_2: TextureRect = %BossIcon_2


func _ready() -> void :
	visible = false


func _update_content() -> void :
	var boss_type: GameData.BossTypes = GameManager.current_boss

	if boss_type == GameData.BossTypes.NONE:
		return

	var boss_name: String = GameData.get_boss_name(boss_type)
	var title_key: String = "BOSS_" + boss_name
	var description_key: String = "BOSS_" + boss_name + "_DESCRIPTION"

	boss_title_label.text = tr(title_key)
	description_label.text = GameManager.replace_tags(tr(description_key))


	var boss_icon: CompressedTexture2D = load("res://images/bosses/" + boss_name.to_lower() + ".png")

	boss_icon_1.texture = boss_icon
	boss_icon_2.texture = boss_icon


func _notification(what: int) -> void :
	if not is_instance_valid(boss_title_label) or not is_instance_valid(description_label):
		return

	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_content()


func _process(_delta: float) -> void :
	size = get_combined_minimum_size()
	position.x = - size.x / 2
	position.y = - size.y - 31


func appear_animation() -> void :
	_update_content()

	visible = true
	pivot_offset = size / 2

	modulate.a = 0.0
	title_container.modulate.a = 0.0
	description_label.modulate.a = 0.0

	title_container.pivot_offset = title_container.size / 2
	description_label.pivot_offset = description_label.size / 2

	await get_tree().process_frame
	await get_tree().create_timer(1.0 / GameManager.timescale).timeout

	var speed: float = GameManager.timescale
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate:a", 1.0, 0.2 / speed).from(0.0)

	tween.set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3 / speed).from(Vector2(0.9, 1.1))

	tween.parallel().tween_property(title_container, "position:y", title_container.position.y, 0.3 / speed).from(title_container.position.y - 4)
	tween.parallel().tween_property(title_container, "modulate:a", 1.0, 0.01 / speed).from(0.0)

	tween.tween_property(description_label, "position:y", description_label.position.y, 0.3 / speed).from(description_label.position.y - 4)
	tween.parallel().tween_property(description_label, "modulate:a", 1.0, 0.01 / speed).from(0.0)
