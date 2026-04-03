class_name DeckSelectorScreen extends ModalRect

#const SEED_BUTTON_ICON_TEXTURE_UP: CompressedTexture2D = preload("uid://cuasc663m6k6b")
#const SEED_BUTTON_ICON_TEXTURE_DOWN: CompressedTexture2D = preload("uid://bumlyta1rki3p")
const SEED_DISABLED_ALPHA: float = 0.35


@onready var panel_container: PanelContainer = $CenterContainer / PanelContainer
@onready var previous_button: BouncyButton = %PreviousButton
@onready var next_button: BouncyButton = %NextButton
@onready var deck_preview_texture: TextureRect = %DeckPreviewTexture
@onready var title_label: LabelShadowed = %TitleLabel
@onready var description_label: RichTextLabelShadowed = %DescriptionLabel
@onready var play_button: BouncyButton = %PlayButton
@onready var close_button: BouncyButton = %CloseButton

@onready var seed_toggle_button: PixelToggleButton = %CustomSeedToggleButton
@onready var seed_line_edit: LineEdit = %SeedLineEdit

var current_deck_index: int = 0
var available_decks: Array[GameData.DeckTypes] = []


const DECK_FOLDER_NAMES: Dictionary = {
	GameData.DeckTypes.NORMAL: "default", 
	GameData.DeckTypes.MOAI: "moai", 
	GameData.DeckTypes.X: "the_x"
}


const DECK_LOCALIZATION_KEYS: Dictionary = {
	GameData.DeckTypes.NORMAL: "NORMAL", 
	GameData.DeckTypes.MOAI: "MOAI", 
	GameData.DeckTypes.X: "THE_X"
}


const DECK_ACHIEVEMENT_MAP: Dictionary = {
	GameData.DeckTypes.NORMAL: - 1, 
	#GameData.DeckTypes.MOAI: AchievementManager.AchievementId.THE_MOAI, 
	#GameData.DeckTypes.X: AchievementManager.AchievementId.THE_X
}


func _ready() -> void :

	visible = false

	_populate_available_decks()
	_setup_buttons()
	_update_display()

	close_button.pressed.connect( func() -> void :
		visible = false
	)

	seed_line_edit.modulate.a = SEED_DISABLED_ALPHA
	seed_line_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE

	seed_toggle_button.toggled.connect( func(value: bool) -> void :
		seed_line_edit.mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE
		seed_line_edit.modulate.a = 1.0 if value else SEED_DISABLED_ALPHA

		if value:
			seed_line_edit.grab_focus()
	)

	super ()


func _unhandled_input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_cancel"):
		visible = false



func _populate_available_decks() -> void :
	available_decks.clear()

	for deck_type: GameData.DeckTypes in GameData.DeckTypes.values():
		available_decks.append(deck_type)


	current_deck_index = 0



func _setup_buttons() -> void :
	previous_button.pressed.connect(_on_previous_pressed)
	next_button.pressed.connect(_on_next_pressed)
	play_button.pressed.connect(_on_play_pressed)



func _update_display() -> void :
	var current_deck: GameData.DeckTypes = available_decks[current_deck_index]
	var is_unlocked: bool = _is_deck_unlocked(current_deck)


	var folder_name: String = DECK_FOLDER_NAMES[current_deck]
	var preview_path: String = "res://images/blocks/%s/preview.png" % folder_name
	var preview_texture: Texture2D = load(preview_path)

	deck_preview_texture.texture = preview_texture



	if not is_unlocked:
		title_label.text = tr("LOCKED")
	else:
		var localization_key: String = DECK_LOCALIZATION_KEYS[current_deck]
		var title_key: String = "DECK_%s" % localization_key
		title_label.text = tr(title_key)


	#if not is_unlocked:
		#var achievement_id: int = DECK_ACHIEVEMENT_MAP[current_deck]
		##var achievement_localization_key: String = _get_achievement_localization_key(achievement_id)
		#var condition_key: String = "ACHIEVEMENT_%s_DESCRIPTION" % achievement_localization_key
		#var raw_condition: String = tr(condition_key)
		#var parsed_condition: String = GameManager.replace_tags(raw_condition)
#
		#description_label.text = parsed_condition
	#else:
		#var localization_key: String = DECK_LOCALIZATION_KEYS[current_deck]
		#var description_key: String = "DECK_%s_DESCRIPTION" % localization_key
		#var raw_description: String = tr(description_key)
		#var parsed_description: String = GameManager.replace_tags(raw_description)
#
		#description_label.text = parsed_description


	play_button.text = tr("BUTTON_PLAY")
	play_button.disabled = not is_unlocked

	if GameManager.is_demo_build and current_deck_index != 0:
		title_label.text = tr("LOCKED")
		description_label.text = tr("DEMO_LOCKED_DESCRIPTION")
		play_button.disabled = true

	await get_tree().process_frame
	deck_preview_texture.pivot_offset = deck_preview_texture.size / 2

	var deck_bounce_tween: Tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	deck_bounce_tween.tween_property(deck_preview_texture, "scale", Vector2(1, 1), 0.5).from(Vector2(1.2, 1.2))



func _is_deck_unlocked(deck_type: GameData.DeckTypes) -> bool:
	var achievement_id: int = DECK_ACHIEVEMENT_MAP.get(deck_type, -1)


	if achievement_id == -1:
		return true
	
	return false
	
	#return AchievementManager.is_unlocked(achievement_id)



#func _get_achievement_localization_key(achievement_id: int) -> String:
	#if achievement_id == AchievementManager.AchievementId.THE_MOAI:
		#return "THE_MOAI"
	#elif achievement_id == AchievementManager.AchievementId.THE_X:
		#return "THE_X"
#
	#return ""



func _on_previous_pressed() -> void :
	current_deck_index -= 1


	if current_deck_index < 0:
		current_deck_index = available_decks.size() - 1

	_update_display()



func _on_next_pressed() -> void :
	current_deck_index += 1


	if current_deck_index >= available_decks.size():
		current_deck_index = 0

	_update_display()



func _on_play_pressed() -> void :
	var selected_deck: GameData.DeckTypes = available_decks[current_deck_index]

	if seed_toggle_button.pressed:
		Random.set_custom_seed(seed_line_edit.text)
	else:
		Random.set_random_seed()

	GameManager.reset_variables()

	GameManager.current_deck = selected_deck
	GameManager.generate_piece_queue()
	GameManager.goto_level_selection()


func appear_animation() -> void :
	visible = true

	seed_line_edit.text = Random.get_current_seed_string()

	play_button.grab_focus()
	panel_container.pivot_offset = panel_container.size / 2

	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	#AudioManager.play(AudioManager.SoundEffects.BLOOP_HIGH, 1.4)

	tween.parallel().tween_property(panel_container, "scale", Vector2.ONE, 0.3).from(Vector2(1.1, 0.9))


func _notification(what: int) -> void :
	if not is_node_ready():
		return

	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_display()
