class_name Background extends Node2D

const BACKGROUND_PIECE_RENDERER_SCENE: PackedScene = preload("res://scenes/background_piece_renderer.tscn")

const SCREEN_SIZE = Vector2(480, 270)

@export var quantity: int = 20
@export var movement_direction_degrees: float = 38.7


func _ready() -> void :
	modulate.a = 0.02
	create_background_pieces()


func create_background_pieces() -> void :
	for i in quantity:
		var piece_renderer: BackgroundPieceRenderer = BACKGROUND_PIECE_RENDERER_SCENE.instantiate()
		add_child(piece_renderer)

		var direction_radians = deg_to_rad(movement_direction_degrees)
		piece_renderer.movement_direction = Vector2(cos(direction_radians), sin(direction_radians))

		var random_x = randi_range(-100, 580)
		var random_y = randi_range(-100, 370)
		piece_renderer.position = Vector2(random_x, random_y)
