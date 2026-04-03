class_name MainMenuScreen extends Node2D

const GAME_SCENE: String = "res://scenes/game.tscn"

@onready var new_game_button: BouncyButton = get_node_or_null("%NewGameButton")
@onready var quit_button: BouncyButton = get_node_or_null("%QuitButton")

@onready var deck_selector_screen: DeckSelectorScreen = $HudLayer/DeckSelectorScreen


func _ready() -> void:
	# Disable GameCamera autoload for main menu
	GameCamera.disable()
	
	# Connect new game button
	if new_game_button:
		new_game_button.grab_focus()
		new_game_button.pressed.connect(_on_new_game_pressed)
	
	# Connect quit button
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


func _on_new_game_pressed() -> void:
	Random.set_random_seed()
	deck_selector_screen.appear_animation()


func _on_quit_pressed() -> void:
	get_tree().quit()
