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
	GameManager.lines_cleared.connect(_on_lines_cleared)
	# Initialize
	_on_score_changed(GameManager.score);
	_on_target_score_changed(GameManager.target_score);

	start_button.pressed.connect(_on_start_pressed)

func _on_score_changed(new_score: int) -> void:
	# Update score display
	%Score.text = str(new_score)

func _on_target_score_changed(new_target: int) -> void:
	# Update target score display
	%TargetScore.text = str(new_target)

func _on_lines_cleared(count: int) -> void:
	if GameManager.score >= GameManager.target_score:
		print("Target score reached! You win!");
		_on_game_over()

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
