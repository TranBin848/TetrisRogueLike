class_name RoundInformationPanel extends PanelContainer


@onready var round_title_label: LabelShadowed = %RoundTitleLabel
@onready var round_reward_container: HBoxContainer = %RoundRewardContainer
@onready var reward_label: LabelShadowed = %RoundRewardValueLabel
@onready var score_container: HBoxContainer = %ScoreContainer
@onready var score_label: LabelShadowed = %ScoreValueLabel
@onready var play_button: BouncyButton = %PlayButton


func _ready() -> void :
	visible = false

	round_title_label.text = tr("ROUND") + " " + str(GameManager.current_round)
	var round_score: Big = GameManager.calculate_round_score(GameManager.current_round)
	score_label.text = round_score.to_scientific(true)

	if GameManager.current_round % 3 == 0 and GameManager.can_select_another_perk():
		reward_label.text = tr("REWARD_PERK")
	else:
		reward_label.text = tr("REWARD_BLOCK")

	play_button.pressed.connect( func():
		GameManager.goto_board()
	)


func _notification(what: int) -> void :
	if not is_instance_valid(round_title_label) or not is_instance_valid(score_label) or not is_instance_valid(reward_label):
		return

	if what == NOTIFICATION_TRANSLATION_CHANGED:
		round_title_label.text = tr("ROUND") + " " + str(GameManager.current_round)
		var round_score: Big = GameManager.calculate_round_score(GameManager.current_round)
		score_label.text = round_score.to_scientific(true)

		if GameManager.current_round % 3 == 0 and GameManager.can_select_another_perk():
			reward_label.text = tr("REWARD_PERK")
		else:
			reward_label.text = tr("REWARD_BLOCK")


func appear_animation() -> void :
	visible = true
	pivot_offset = size / 2

	modulate.a = 0.0
	score_container.modulate.a = 0.0
	round_reward_container.modulate.a = 0.0
	play_button.modulate.a = 0.0

	score_container.pivot_offset = score_container.size / 2
	round_reward_container.pivot_offset = round_reward_container.size / 2

	await get_tree().process_frame

	var speed: float = GameManager.timescale
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate:a", 1.0, 0.2 / speed).from(0.0)

	tween.set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.4 / speed).from(Vector2(0.9, 1.1))

	tween.tween_property(round_reward_container, "position:y", round_reward_container.position.y, 0.2 / speed).from(round_reward_container.position.y - 4)
	tween.parallel().tween_property(round_reward_container, "modulate:a", 1.0, 0.01 / speed).from(0.0)

	tween.tween_property(score_container, "position:y", score_container.position.y, 0.2 / speed).from(score_container.position.y - 4)
	tween.parallel().tween_property(score_container, "modulate:a", 1.0, 0.01 / speed).from(0.0)

	tween.tween_property(play_button, "position:y", play_button.position.y, 0.3 / speed).from(play_button.position.y - 4)
	tween.parallel().tween_property(play_button, "modulate:a", 1.0, 0.01 / speed).from(0.0)

	play_button.grab_focus()
	( %PauseMenu as PauseMenu).focus_on_destroy = play_button
