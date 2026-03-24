extends Node2D

# =============================================================================
# NODES
# =============================================================================

@onready var board: Board = $Board
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var start_button: Button = $UI/StartButton

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Connect signal
	GameManager.game_over.connect(_on_game_over)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.target_score_changed.connect(_on_target_score_changed)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.lines_cleared_stopped.connect(_on_lines_cleared_stop);
	GameManager.stack_changed.connect(_on_stack_changed);
	GameManager.multiplier_changed.connect(_on_multiplier_changed);
	GameManager.money_changed.connect(_on_money_changed);
	# Initialize
	_on_score_changed(GameManager.score);
	_on_target_score_changed(GameManager.target_score);
	_on_money_changed(GameManager.money);

	start_button.pressed.connect(_on_start_pressed)

func _on_money_changed(money) -> void:
	%Money.text = str(money)

func _on_stack_changed(stack) -> void:
	%Stack.text = str(stack)

func _on_multiplier_changed(multiplier) -> void:
	%Flow.text = str(multiplier)

func _on_score_changed(new_score: int) -> void:
	# Update score display
	%Score.text = str(new_score)

func _on_target_score_changed(new_target: int) -> void:
	# Update target score display
	%TargetScore.text = str(new_target)

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.WIN:
			# Display win message
			game_over_label.text = "You Win!"
			game_over_label.visible = true
			start_button.visible = true
			const BLOCK_REMAINING = 24;
			GameManager.round += 1;
			GameManager.add_money(GameManager.BASE_LEVEL_REWARD + \
				roundi(float(BLOCK_REMAINING) / 4.0)); 

func _on_lines_cleared_stop() -> void:
	GameManager.add_stack_flow();
	await get_tree().create_timer(0.5).timeout
	GameManager.reset_stack_and_multiplier();
	if GameManager.score >= GameManager.target_score:
		GameManager.trigger_win();

func _on_start_pressed() -> void:
	start_button.visible = false
	game_over_label.visible = false
	GameManager.reset_game()
	board.initialize_board()
	board.spawn_next_piece()

# =============================================================================
# UI UPDATES
# =============================================================================



func _on_game_over() -> void:
	game_over_label.visible = true
	start_button.visible = true
