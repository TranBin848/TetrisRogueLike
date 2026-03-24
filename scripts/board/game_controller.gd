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
	
	start_button.pressed.connect(_on_start_pressed)



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
