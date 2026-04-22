class_name MainMenuScreen extends Node2D

const GAME_SCENE: String = "res://scenes/game.tscn"
const OPTIONS_MENU_SCENE: PackedScene = preload("res://scenes/options_menu.tscn")

@onready var new_game_button: BouncyButton = get_node_or_null("%NewGameButton")
@onready var options_button: BouncyButton = get_node_or_null("%OptionsButton")
@onready var quit_button: BouncyButton = get_node_or_null("%QuitButton")

@onready var deck_selector_screen: DeckSelectorScreen = $HudLayer/DeckSelectorScreen
@onready var ui_layer: CanvasLayer = $CanvasLayer


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

	# Connect options button
	if options_button:
		options_button.pressed.connect(_on_options_pressed)


func _on_new_game_pressed() -> void:
	Random.set_random_seed()
	deck_selector_screen.appear_animation()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_options_pressed() -> void:
	var options: OptionsMenu = OPTIONS_MENU_SCENE.instantiate()
	if ui_layer:
		ui_layer.add_child(options)
	else:
		add_child(options)
	options.focus_on_destroy = options_button
