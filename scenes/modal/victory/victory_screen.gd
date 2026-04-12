class_name VictoryScreen extends ColorRect


var clicked: bool = false


@onready var title_label: RichTextLabelShadowed = $CenterContainer/PanelContainer/VBoxContainer/TitleContainer/TitleLabel
@onready var phrase_label: LabelShadowed = $CenterContainer/PanelContainer/VBoxContainer/TitleContainer/PhraseLabel

@onready var pieces_played_label: LabelShadowed = $CenterContainer/PanelContainer/VBoxContainer/VBoxContainer/PiecesPlayedContainer/ValueLabel
@onready var total_score_label: LabelShadowed = $CenterContainer/PanelContainer/VBoxContainer/VBoxContainer/TotalScoreContainer/ValueLabel

@onready var best_score_label: LabelShadowed = $CenterContainer/PanelContainer/VBoxContainer/LastLevelContainer/BestScoreContainer/ValueLabel
@onready var blocks_rolled_label: LabelShadowed = $CenterContainer/PanelContainer/VBoxContainer/LastLevelContainer/BlocksScrollContainer/ValueLabel
@onready var blocks_skipped_label: LabelShadowed = $CenterContainer/PanelContainer/VBoxContainer/LastLevelContainer/BlocksSkippedContainer/ValueLabel
@onready var seed_label: LabelShadowed =$CenterContainer/PanelContainer/VBoxContainer/LastLevelContainer/SeedContainer/ValueLabel

@onready var continue_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/ContinueButton
@onready var menu_button: BouncyButton = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/MenuButton
@onready var panel_container: PanelContainer = $CenterContainer / PanelContainer

@onready var last_level_container: VBoxContainer = $CenterContainer/PanelContainer/VBoxContainer/LastLevelContainer
@onready var separator_color_rect: ColorRect = $CenterContainer/PanelContainer/VBoxContainer/SeparatorColorRect


static func is_active() -> bool:
	var victory_instance: VictoryScreen = GameManager.get_unique_node("VictoryScreen")

	if is_instance_valid(victory_instance):
		return victory_instance.visible

	return false


func _ready() -> void :
	title_label.text = "[wave]%s![/wave]" % tr("STAGE_CLEAR")

	continue_button.pressed.connect( func():
		if clicked:
			return

		clicked = true

		SpeedrunTimerLayer.resume_timer()

		var target_scene: Transition.Scene = Transition.Scene.BLOCK_SELECTION

		if GameManager.current_round % 3 == 0 and GameManager.can_select_another_perk() and Transition.scenes.has(Transition.Scene.PERK_SELECTION):
			target_scene = Transition.Scene.PERK_SELECTION
		elif Transition.scenes.has(Transition.Scene.BLOCK_SELECTION):
			target_scene = Transition.Scene.BLOCK_SELECTION
		else:
			target_scene = Transition.Scene.LEVEL_SELECTION

		Transition.goto(target_scene, func():
			GameManager.current_round += 1
			GameManager.save_game()
			GameManager.pieces_played = 0

			GameManager.score = Big.new(0)
			GameManager.target_score = Big.new(GameManager.calculate_round_score(GameManager.current_round))
			GameManager.rotated_piece_on_current_round = false

			GameManager.points = Big.new(0)
			GameManager.multiplier = Big.new(1)

			GameManager.perks_used.clear()

			#AudioManager.set_music_filter_enabled(true)
			GameManager.reset_pieces_to_original()
		)
	)

	menu_button.pressed.connect( func():
		if clicked:
			return

		clicked = true

		Transition.goto(Transition.Scene.MAIN_MENU, func():
			GameManager.delete_save_file()
			GameManager.reset_variables()
		)
	)


func _notification(what: int) -> void :
	if not is_instance_valid(title_label):
		return

	if what == NOTIFICATION_TRANSLATION_CHANGED:
		title_label.text = "[wave]%s![/wave]" % tr("STAGE_CLEAR")


func _process(_delta: float) -> void :
	if visible:
		panel_container.pivot_offset = panel_container.size / 2


func appear_animation() -> void :
	visible = true

	SpeedrunTimerLayer.pause_timer()


	if GameManager.score.is_greater_than(GameManager.best_score):
		GameManager.best_score = GameManager.score.duplicate()


	ModalRect.destroy_all_modals()

	panel_container.modulate.a = 0.0


	var is_final_level: bool = GameManager.current_round == 21


	if is_final_level:
		title_label.text = "[wave]%s[/wave]" % tr("VICTORY")
		phrase_label.text = tr("PHRASE_VICTORY_" + str(randi_range(1, 3)))
	else:
		title_label.text = "[wave]%s![/wave]" % tr("STAGE_CLEAR")


	menu_button.visible = is_final_level
	last_level_container.visible = is_final_level
	separator_color_rect.visible = is_final_level
	phrase_label.visible = is_final_level

	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	#tween.tween_callback( func():
		#AudioManager.play(AudioManager.SoundEffects.BLOOP_HIGH, 1.6)
		#AudioManager.play(AudioManager.SoundEffects.POSITIVE_NOTIFICATION, 1.0)
	#)

	tween.tween_property(panel_container, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(panel_container, "scale", Vector2.ONE, 0.3).from(Vector2(1.1, 0.9))

	pieces_played_label.text = Utils.add_commas_to_number(GameManager.pieces_played)
	total_score_label.text = GameManager.score.to_scientific(true)


	if is_final_level:
		best_score_label.text = GameManager.best_score.to_scientific(true)
		blocks_rolled_label.text = Utils.add_commas_to_number(GameManager.blocks_rolled_count)
		blocks_skipped_label.text = Utils.add_commas_to_number(GameManager.blocks_skipped_count)
		seed_label.text = str(Random.get_current_seed_string())


	continue_button.grab_focus()

#Achievement Reference
	#if not GameManager.rotated_piece_on_current_round:
		#AchievementManager.unlock(AchievementManager.AchievementId.THE_MOAI)
#
	#if GameManager.current_round == 10:
		#AchievementManager.unlock(AchievementManager.AchievementId.BEAT_LEVEL_10)
#
	#elif GameManager.current_round == 20:
		#AchievementManager.unlock(AchievementManager.AchievementId.BEAT_LEVEL_20)
#
	#elif GameManager.current_round == 21:
		#AchievementManager.unlock(AchievementManager.AchievementId.WIN_FIRST_RUN)
