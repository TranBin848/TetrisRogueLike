class_name GameScreen extends Node2D


static var _instance: GameScreen

#@onready var current_score_panel: ScoreBackgroundPanel = %ScoreBackgroundPanel
#@onready var game_over_screen: GameOverScreen = %GameOverScreen
#@onready var victory_screen: VictoryScreen = %VictoryScreen
#@onready var demo_warning: DemoWarning = %DemoWarning


func _ready() -> void :
	_instance = self
	
	# Enable GameCamera for game scene
	GameCamera.enable()

	if GameManager.is_perk_active(GameData.Perks.SHORTCUT):
		await get_tree().create_timer(1.5).timeout
		GameManager.trigger_perk(GameData.Perks.SHORTCUT)


static func next_action() -> void :
	if not is_instance_valid(_instance):
		return

	var current_frame: int = _instance.get_tree().get_frame()

	if current_frame <= GameManager.next_action_frame:
		print("Skipping next action due to frame check. Current frame: ", current_frame, ", Next action frame: ", GameManager.next_action_frame)
		return

	GameManager.next_action_frame = current_frame

	if GameManager.deathline:
		_instance.game_over_screen.appear_animation()
		return

	if GameManager.score.is_greater_than_or_equal_to(GameManager.target_score):
		await _instance.get_tree().create_timer(1.0 / GameManager.timescale).timeout

		if not is_instance_valid(_instance) or not is_instance_valid(_instance.current_score_panel):
			return

		_instance.current_score_panel.trigger_finish_animation()

		await _instance.current_score_panel.final_animation_finished
		await _instance.get_tree().create_timer(0.5 / GameManager.timescale).timeout

		if GameManager.is_demo_build and GameManager.current_round == GameManager.DEMO_LAST_ROUND:
			_instance.demo_warning.appear_animation()
			return

		_instance.victory_screen.appear_animation()
		return

	if not GameManager.next_piece_cache.is_empty():
		if not is_instance_valid(GameManager.current_moving_piece):
			GameManager.spawn_moving_piece()
		return

	print("Next Piece Cache is empty!")
	print("next_piece_cache: ", GameManager.next_piece_cache)
	print("frame: ", current_frame)

	if GameManager.is_perk_active(GameData.Perks.LAST_BREATH) and not GameManager.is_perk_used(GameData.Perks.LAST_BREATH):
		GameManager.trigger_perk(GameData.Perks.LAST_BREATH)

	if GameManager.points.is_greater_than(0):
		GameManager.is_calculating = true
		EventManager.execute_events()
		return


	await _instance.get_tree().create_timer(1.0 / GameManager.timescale).timeout

	if not is_instance_valid(_instance) or not is_instance_valid(_instance.current_score_panel):
		return

	_instance.current_score_panel.trigger_finish_animation()

	await _instance.current_score_panel.final_animation_finished
	await _instance.get_tree().create_timer(0.5 / GameManager.timescale).timeout

	_instance.game_over_screen.appear_animation()
