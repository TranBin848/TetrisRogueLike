class_name GameScreen extends Node2D


static var _instance: GameScreen

@onready var current_score_panel: ScoreBackgroundPanel = $HUD/MainMarginContainer/MainHBoxContainer/LeftContainer/ScoreBackgroundPanel
@onready var game_over_screen: GameOverScreen = $HUD/GameOverScreen
@onready var victory_screen: VictoryScreen = $HUD/VictoryScreen
#@onready var demo_warning: DemoWarning = %DemoWarning


func _ready() -> void :
	_instance = self
	
	# Enable GameCamera for game scene
	GameCamera.enable()

	if GameManager.is_perk_active(GameData.Perks.SHORTCUT):
		await get_tree().create_timer(1.5).timeout
		GameManager.trigger_perk(GameData.Perks.SHORTCUT)

	if GameManager.settings != null and GameManager.current_round == 1:
		var tutorial_scene = load("res://scenes/tutorial.tscn")
		var tutorial_instance = tutorial_scene.instantiate()
		$HUD.add_child(tutorial_instance)


static func next_action() -> void :
	if not is_instance_valid(_instance):
		return

	var current_frame: int = _instance.get_tree().get_frame()

	if current_frame <= GameManager.next_action_frame:
		print("Skipping next action due to frame check. Current frame: ", current_frame, ", Next action frame: ", GameManager.next_action_frame)
		return

	GameManager.next_action_frame = current_frame

	if GameManager.deathline or GameManager.time_out:
		GameManager.is_timer_active = false
		if is_instance_valid(_instance.game_over_screen):
			_instance.game_over_screen.appear_animation()
		return

	if GameManager.score.is_greater_than_or_equal_to(GameManager.target_score):
		if not GameManager.is_timer_active:
			return # Already processing victory
			
		GameManager.is_timer_active = false
		
		var target_f = GameManager.target_score.to_float()
		var overflow_f = max(0.0, GameManager.score.minus(GameManager.target_score).to_float())
		var overflow_bonus = 0
		if target_f > 0:
			overflow_bonus = min(20, int((overflow_f / target_f) * 20.0))
		
		var time_bonus_coins = int(GameManager.round_time_left / 5.0)
		var coins_awarded = 5 + (GameManager.current_round * 2) + overflow_bonus + time_bonus_coins
		GameManager.add_coins(coins_awarded)
		
		if is_instance_valid(_instance.current_score_panel):
			PointNotification.create_and_slide(_instance.current_score_panel.global_position + _instance.current_score_panel.size / 2, PointNotification.YELLOW, "+" + str(coins_awarded) + " COINS")
			
		if time_bonus_coins > 0:
			var timer_panels = _instance.find_children("*", "RoundTimerPanel", true, false)
			if timer_panels.size() > 0:
				var timer_panel = timer_panels[0]
				PointNotification.create_and_slide(timer_panel.global_position + timer_panel.size / 2, PointNotification.YELLOW, "+" + str(time_bonus_coins) + " TIME BONUS")

		await _instance.get_tree().create_timer(1.0 / GameManager.timescale).timeout

		if not is_instance_valid(_instance) or not is_instance_valid(_instance.current_score_panel):
			return

		_instance.current_score_panel.trigger_finish_animation()

		await _instance.current_score_panel.final_animation_finished
		await _instance.get_tree().create_timer(0.5 / GameManager.timescale).timeout

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

	if is_instance_valid(_instance) and is_instance_valid(_instance.current_score_panel):
		_instance.current_score_panel.trigger_finish_animation()
		await _instance.current_score_panel.final_animation_finished

	if is_instance_valid(_instance) and is_instance_valid(_instance.game_over_screen):
		_instance.game_over_screen.appear_animation()
