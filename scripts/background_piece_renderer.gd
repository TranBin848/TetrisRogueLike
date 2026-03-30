class_name BackgroundPieceRenderer extends Node2D


var rotation_speed: float = randf_range(0.5, 1.5)
var movement_direction: Vector2 = Vector2(1.0, 0.8)


@onready var sprite: Sprite2D = $Sprite2D

var screen_size: Vector2 = Vector2(480, 270)
var wrap_margin: float = 12.0


func _ready() -> void :
	sprite.scale = randf_range(0.8, 3.0) * Vector2.ONE

	var scaled_size: Vector2 = sprite.texture.get_size() * sprite.scale
	wrap_margin = max(scaled_size.x, scaled_size.y) * 0.5


func _process(delta: float) -> void :
	rotation += rotation_speed * delta

	position.x += (10.0 * rotation_speed * movement_direction.x) * delta
	position.y += (8.0 * rotation_speed * movement_direction.y) * delta


	var camera_pos: Vector2 = Camera.get_world_position()
	var half_screen: Vector2 = screen_size / 2
	var left_bound: float = camera_pos.x - half_screen.x - wrap_margin
	var right_bound: float = camera_pos.x + half_screen.x + wrap_margin
	var top_bound: float = camera_pos.y - half_screen.y - wrap_margin
	var bottom_bound: float = camera_pos.y + half_screen.y + wrap_margin

	if position.x > right_bound:
		position.x = left_bound
	elif position.x < left_bound:
		position.x = right_bound

	if position.y > bottom_bound:
		position.y = top_bound
	elif position.y < top_bound:
		position.y = bottom_bound
