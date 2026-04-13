class_name ScoreBackgroundPanel extends PanelContainer


signal final_animation_finished()


const JUMP_ANIMATION_SCALE: float = 1.4
const JUMP_ANIMATION_DURATION: float = 0.4

const WAVE_ANIMATION_AMPLITUDE_MAXIMUM: float = 70.0
const WAVE_ANIMATION_MINIMUM_VALUE: float = 50.0
const WAVE_ANIMATION_MAXIMUM_VALUE: float = 1000.0


var points_tween: Tween
var multiplier_tween: Tween

var score_sound_pitch: float = 0.8
var score_sound_time_interval: float = 0.05
var score_sound_pitch_increment: float = 0.05

var score_label_tween: Tween
var score_label_value_tween: Tween

var target_score_label_tween: Tween
var target_score_label_value_tween: Tween

var default_target_score_y: float = 0.0

var score_label_value: float = 0.0:
	set(value):
		if score_label_value != value:
			if score_sound_time_interval <= 0.0:
				#AudioManager.play(AudioManager.SoundEffects.BLOOP_HIGH, score_sound_pitch)
				score_sound_pitch = clamp(score_sound_pitch + score_sound_pitch_increment, 0.8, 1.4)
				score_sound_time_interval = 0.05


			score_label.pivot_offset = score_label.size / 2

			if score_label_tween and score_label_tween.is_running():
				score_label_tween.stop()
				score_label_tween = null

			score_label_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel()
			score_label_tween.tween_property(score_label, "scale", Vector2.ONE, JUMP_ANIMATION_DURATION / GameManager.timescale).from(Vector2.ONE * JUMP_ANIMATION_SCALE)
			score_label_tween.tween_callback( func():
				score_sound_pitch = 0.8
			)

		score_label_value = value
		score_label.text = _format_number_display(value)


var target_score_label_value: float = 0.0:
	set(value):
		if target_score_label_value != value:
			if score_sound_time_interval <= 0.0:
				#AudioManager.play(AudioManager.SoundEffects.BLOOP_HIGH, score_sound_pitch)
				score_sound_pitch = clamp(score_sound_pitch + score_sound_pitch_increment, 0.8, 1.4)
				score_sound_time_interval = 0.05

		target_score_label_value = value

		target_score_label.text = _format_number_display(value)
		target_score_label.pivot_offset = target_score_label.size / 2

		if target_score_label_tween and target_score_label_tween.is_running():
			target_score_label_tween.stop()
			target_score_label_tween = null

		target_score_label_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel()
		target_score_label_tween.tween_property(target_score_label, "position:y", default_target_score_y, JUMP_ANIMATION_DURATION / GameManager.timescale).from(default_target_score_y - 8.0)
		target_score_label_tween.tween_callback( func():
			score_sound_pitch = 0.8
		)


@onready var score_label: LabelShadowed = $VBoxContainer/Score/VBoxContainer/ScoreValue
@onready var target_score_label: LabelShadowed = $VBoxContainer/TargetScore/VBoxContainer/TargetValue
@onready var points_label: RichTextLabelShadowed = $VBoxContainer/HBoxContainer/Points/VBoxContainer/PointValue
@onready var multiplier_label: RichTextLabelShadowed = $VBoxContainer/HBoxContainer/Multiplier/VBoxContainer/MulValue

func _ready() -> void :
	score_label.text = _format_big_number(GameManager.score)
	target_score_label.text = _format_big_number(GameManager.target_score)

	_update_points()
	_update_multiplier()

	await get_tree().process_frame
	default_target_score_y = target_score_label.position.y

	GameManager.score_changed.connect( func(score: Big):
		if score_label_value_tween and score_label_value_tween.is_running():
			score_label_value_tween.stop()
			score_label_value_tween = null

		score_label_value_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		score_label_value_tween.tween_property(self, "score_label_value", score.to_float(), 0.5 / GameManager.timescale)
	)

	GameManager.points_changed.connect( func(_points: Big):
		_update_points()
		points_label.pivot_offset = points_label.size / 2

		if points_tween and points_tween.is_running():
			points_tween.stop()
			points_tween = null

		points_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel()
		points_tween.tween_property(points_label, "scale", Vector2.ONE, JUMP_ANIMATION_DURATION / GameManager.timescale).from(Vector2.ONE * JUMP_ANIMATION_SCALE)
	)

	GameManager.multiplier_changed.connect( func(_multiplier: Big):
		_update_multiplier()
		multiplier_label.pivot_offset = multiplier_label.size / 2

		if multiplier_tween and multiplier_tween.is_running():
			multiplier_tween.stop()
			multiplier_tween = null

		multiplier_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel()
		multiplier_tween.tween_property(multiplier_label, "scale", Vector2.ONE, JUMP_ANIMATION_DURATION / GameManager.timescale).from(Vector2.ONE * JUMP_ANIMATION_SCALE)
	)


func _process(delta: float) -> void :
	score_sound_time_interval -= delta * GameManager.timescale


func _update_points() -> void :
	var wave_amplitude: float = 0.0
	var wave_tag: String = "[wave amp=%d freq=10]"

	var clamped_value: float = clamp(GameManager.points.to_float(), WAVE_ANIMATION_MINIMUM_VALUE, WAVE_ANIMATION_MAXIMUM_VALUE)
	var normalized_value: float = (clamped_value - WAVE_ANIMATION_MINIMUM_VALUE) / (WAVE_ANIMATION_MAXIMUM_VALUE - WAVE_ANIMATION_MINIMUM_VALUE)
	wave_amplitude = normalized_value * WAVE_ANIMATION_AMPLITUDE_MAXIMUM

	points_label.text = (wave_tag % wave_amplitude) + _format_big_number(GameManager.points)


func _update_multiplier() -> void :
	var wave_amplitude: float = 0.0
	var wave_tag: String = "[wave amp=%d freq=10]"

	var clamped_value: float = clamp(GameManager.multiplier.to_float(), WAVE_ANIMATION_MINIMUM_VALUE, WAVE_ANIMATION_MAXIMUM_VALUE)
	var normalized_value: float = (clamped_value - WAVE_ANIMATION_MINIMUM_VALUE) / (WAVE_ANIMATION_MAXIMUM_VALUE - WAVE_ANIMATION_MINIMUM_VALUE)
	wave_amplitude = normalized_value * WAVE_ANIMATION_AMPLITUDE_MAXIMUM

	multiplier_label.text = (wave_tag % wave_amplitude) + _format_big_number(GameManager.multiplier)


func trigger_finish_animation() -> void :
	if score_label_value_tween and score_label_value_tween.is_running():
		score_label_value_tween.stop()
		score_label_value_tween = null

	score_label_value_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	score_label_value_tween.tween_property(self, "score_label_value", max(0, GameManager.score.minus(GameManager.target_score).to_float()), 1.0 / GameManager.timescale)

	if target_score_label_value_tween and target_score_label_value_tween.is_running():
		target_score_label_value_tween.stop()
		target_score_label_value_tween = null

	target_score_label_value_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	target_score_label_value_tween.tween_property(self, "target_score_label_value", max(0, GameManager.target_score.minus(GameManager.score).to_float()), 1.0 / GameManager.timescale).from(GameManager.target_score.to_float())
	target_score_label_value_tween.tween_callback( func():
		final_animation_finished.emit()
	)





func _format_big_number(big_num: Big) -> String:
	return big_num.to_scientific(true)



func _format_number_display(value: float) -> String:
	return Big.new(value).to_scientific(true)
