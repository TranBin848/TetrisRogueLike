class_name GameOverScreen extends ColorRect


@onready var title_label: RichTextLabelShadowed = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var pieces_placed_label: LabelShadowed = $CenterContainer/PanelContainer/VBoxContainer/VBoxContainer/PiecesPlayedContainer/ValueLabel
@onready var round_label: LabelShadowed = $CenterContainer/PanelContainer/VBoxContainer/VBoxContainer/RoundContainer/ValueLabel
@onready var items_collected: LabelShadowed = $CenterContainer/PanelContainer/VBoxContainer/VBoxContainer/ItemCollectedContainer/ValueLabel
@onready var new_game_button: BouncyButton = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/NewGameButton
@onready var menu_button: BouncyButton = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/MenuButton
@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer


static func is_active() -> bool:
	var game_over_instance: GameOverScreen = GameManager.get_unique_node("GameOverScreen")

	if is_instance_valid(game_over_instance):
		return game_over_instance.visible

	return false


func _ready() -> void :
	title_label.text = "[wave]%s![/wave]" % tr("GAME_OVER")

	new_game_button.pressed.connect( func():
		GameManager.restart()
	)

	menu_button.pressed.connect( func():
		GameManager.paused = false
		Transition.goto(Transition.Scene.MAIN_MENU, func():
			GameManager.reset_variables()
		)
	)


func _notification(what: int) -> void :
	if not is_instance_valid(title_label):
		return

	if what == NOTIFICATION_TRANSLATION_CHANGED:
		title_label.text = "[wave]]%s![/wave]" % tr("GAME_OVER")


func _process(_delta: float) -> void :
	if visible:
		panel_container.pivot_offset = panel_container.size / 2


func appear_animation() -> void :
	GameManager.delete_save_file()
	SpeedrunTimerLayer.pause_timer()




	visible = true
	ModalRect.destroy_all_modals()


	panel_container.modulate.a = 0.0

	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	#tween.tween_callback( func():
		#AudioManager.play(AudioManager.SoundEffects.BLOOP_HIGH, 1.6)
	#)

	tween.tween_property(panel_container, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(panel_container, "scale", Vector2.ONE, 0.3).from(Vector2(1.1, 0.9))

	#AudioManager.set_music_filter_enabled(true)

	round_label.text = str(GameManager.current_round)
	pieces_placed_label.text = str(GameManager.pieces_played)
	items_collected.text = str(GameManager.get_unique_perk_count())

	new_game_button.grab_focus()
