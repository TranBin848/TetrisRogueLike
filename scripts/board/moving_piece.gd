class_name MovingPiece extends Node2D

# =============================================================================
# CONSTANTS
# =============================================================================

const CELL_SIZE: int = 32
const SPAWN_POSITION: Vector2i = Vector2i(3, 0)

## Lock delay - time before piece locks after touching ground
const LOCK_DELAY: float = 0.5

## Max lock delay resets (from rotation/movement while grounded)
const MAX_LOCK_RESETS: int = 15

## DAS (Delayed Auto Shift) settings
const DAS_DELAY: float = 0.15
const ARR_DELAY: float = 0.03

## Soft drop multiplier
const SOFT_DROP_MULTIPLIER: float = 20.0

## Fallback colors when textures don't exist
const BLOCK_COLORS: Dictionary = {
	"cyan": Color(0.0, 1.0, 1.0),
	"yellow": Color(1.0, 1.0, 0.0),
	"purple": Color(0.6, 0.0, 1.0),
	"green": Color(0.0, 1.0, 0.0),
	"red": Color(1.0, 0.0, 0.0),
	"blue": Color(0.0, 0.0, 1.0),
	"orange": Color(1.0, 0.5, 0.0),
}

# =============================================================================
# STATE
# =============================================================================

var current_shape: GameData.ShapeType
var current_special_type: String = ""
var current_rotation: int = 0
var grid_position: Vector2i = Vector2i.ZERO
var is_active: bool = false

## Lock delay state
var is_grounded: bool = false
var lock_timer: float = 0.0
var lock_resets: int = 0

## Gravity
var gravity_timer: float = 0.0

## DAS state
var das_direction: int = 0  # -1 left, 0 none, 1 right
var das_timer: float = 0.0
var arr_timer: float = 0.0

# =============================================================================
# NODES
# =============================================================================

@onready var board: Board = get_parent()
@onready var block_sprites: Node2D = $BlockSprites
@onready var ghost_sprites: Node2D = $GhostSprites

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	visible = false


func _process(delta: float) -> void:
	if not is_active or not GameManager.can_move():
		return

	_handle_das_input(delta)
	_handle_gravity(delta)
	_handle_lock_delay(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not is_active or not GameManager.can_move():
		return

	if event.is_action_pressed("rotate_cw"):
		rotate_piece(1)
	elif event.is_action_pressed("rotate_ccw"):
		rotate_piece(-1)
	elif event.is_action_pressed("hard_drop"):
		hard_drop()
	elif event.is_action_pressed("hold"):
		hold_piece()

# =============================================================================
# INPUT HANDLING
# =============================================================================

func _handle_das_input(delta: float) -> void:
	var left_pressed: bool = Input.is_action_pressed("move_left")
	var right_pressed: bool = Input.is_action_pressed("move_right")

	# Determine direction
	var new_direction: int = 0
	if left_pressed and not right_pressed:
		new_direction = -1
	elif right_pressed and not left_pressed:
		new_direction = 1

	# Direction changed - reset DAS
	if new_direction != das_direction:
		das_direction = new_direction
		das_timer = 0.0
		arr_timer = 0.0
		if das_direction != 0:
			move_horizontal(das_direction)

	# DAS active
	elif das_direction != 0:
		das_timer += delta
		if das_timer >= DAS_DELAY:
			arr_timer += delta
			if arr_timer >= ARR_DELAY:
				arr_timer = 0.0
				move_horizontal(das_direction)


func _handle_gravity(delta: float) -> void:
	var fall_speed: float = GameManager.get_fall_speed()

	# Soft drop
	if Input.is_action_pressed("soft_drop"):
		fall_speed /= SOFT_DROP_MULTIPLIER

	gravity_timer += delta
	if gravity_timer >= fall_speed:
		gravity_timer = 0.0
		move_down()


func _handle_lock_delay(delta: float) -> void:
	if is_grounded:
		lock_timer += delta
		if lock_timer >= LOCK_DELAY:
			lock_piece()

# =============================================================================
# SPAWNING
# =============================================================================

func spawn(shape: GameData.ShapeType, special_type: String = "") -> void:
	current_shape = shape
	if special_type.is_empty():
		current_special_type = GameData.get_shape_block_type(shape)
	else:
		current_special_type = special_type
	current_rotation = 0
	grid_position = SPAWN_POSITION
	is_active = true
	is_grounded = false
	lock_timer = 0.0
	lock_resets = 0
	gravity_timer = 0.0
	das_direction = 0
	das_timer = 0.0
	arr_timer = 0.0

	visible = true
	_update_visuals()
	_update_ghost()
	_check_grounded()


func is_spawn_valid() -> bool:
	var blocks: Array = GameData.get_shape_blocks(current_shape, current_rotation)
	for offset: Vector2i in blocks:
		var pos: Vector2i = grid_position + offset
		if board.is_position_occupied(pos):
			return false
	return true

# =============================================================================
# MOVEMENT
# =============================================================================

func move_horizontal(direction: int) -> bool:
	var new_pos: Vector2i = grid_position + Vector2i(direction, 0)
	if _is_valid_position(new_pos, current_rotation):
		grid_position = new_pos
		_update_visuals()
		_update_ghost()
		_reset_lock_delay()
		return true
	return false


func move_down() -> bool:
	var new_pos: Vector2i = grid_position + Vector2i(0, 1)
	if _is_valid_position(new_pos, current_rotation):
		grid_position = new_pos
		is_grounded = false
		_update_visuals()
		_update_ghost()
		return true
	else:
		_check_grounded()
		return false


func hard_drop() -> void:
	var drop_distance: int = 0
	while _is_valid_position(grid_position + Vector2i(0, 1), current_rotation):
		grid_position.y += 1
		drop_distance += 1

	_update_visuals()

	# Camera punch for feedback
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("punch"):
		camera.punch(Vector2.DOWN, 3.0)

	# Score for hard drop
	GameManager.add_score(drop_distance * 2)

	lock_piece()


func _check_grounded() -> void:
	var below_pos: Vector2i = grid_position + Vector2i(0, 1)
	is_grounded = not _is_valid_position(below_pos, current_rotation)
	if is_grounded and lock_timer == 0.0:
		lock_timer = 0.0

# =============================================================================
# ROTATION WITH WALL KICKS
# =============================================================================

func rotate_piece(direction: int) -> bool:
	if current_shape == GameData.ShapeType.O:
		return false  # O doesn't rotate

	var new_rotation: int = (current_rotation + direction + 4) % 4

	# Get wall kick offsets
	var kicks: Array = GameData.get_wall_kicks(current_shape, current_rotation, new_rotation)

	for kick: Vector2i in kicks:
		var test_pos: Vector2i = grid_position + kick
		if _is_valid_position(test_pos, new_rotation):
			grid_position = test_pos
			current_rotation = new_rotation
			_update_visuals()
			_update_ghost()
			_reset_lock_delay()
			return true

	return false

# =============================================================================
# HOLD
# =============================================================================

func hold_piece() -> void:
	var new_piece: Dictionary = GameManager.try_hold_piece({"shape": current_shape, "type": current_special_type})
	if not new_piece.is_empty():
		spawn(new_piece.shape, new_piece.type)

# =============================================================================
# LOCKING
# =============================================================================

func lock_piece() -> void:
	is_active = false
	visible = false

	# Place blocks on board
	var block_type: String = current_special_type
	var blocks: Array = GameData.get_shape_blocks(current_shape, current_rotation)

	var sorted_blocks = blocks.duplicate()
	sorted_blocks.sort_custom(func(a, b): return a.y > b.y)

	for offset: Vector2i in sorted_blocks:
		var pos: Vector2i = grid_position + offset
		if block_type == "water":
			pos = board.get_lowest_water_fall_position(pos)
		board.place_block(pos, block_type)

	# Check for line clears
	board.check_and_clear_lines()


func _reset_lock_delay() -> void:
	if is_grounded and lock_resets < MAX_LOCK_RESETS:
		lock_timer = 0.0
		lock_resets += 1
		_check_grounded()

# =============================================================================
# VALIDATION
# =============================================================================

func _is_valid_position(pos: Vector2i, rotation: int) -> bool:
	var blocks: Array = GameData.get_shape_blocks(current_shape, rotation)
	for offset: Vector2i in blocks:
		var cell_pos: Vector2i = pos + offset
		if not board.is_position_free(cell_pos):
			return false
	return true

# =============================================================================
# VISUALS
# =============================================================================

func _update_visuals() -> void:
	position = Vector2(grid_position.x * CELL_SIZE, grid_position.y * CELL_SIZE)

	# Clear existing sprites
	for child in block_sprites.get_children():
		child.queue_free()

	# Create block sprites with shadow
	var blocks: Array = GameData.get_shape_blocks(current_shape, current_rotation)
	var block_type: String = current_special_type
	var texture_path: String = GameData.get_block_texture_path(block_type)

	for offset: Vector2i in blocks:
		var shadowed: ShadowedSprite = ShadowedSprite.new()
		var tex: Texture2D
		if texture_path != "" and ResourceLoader.exists(texture_path):
			tex = load(texture_path)
		else:
			tex = _create_colored_texture(block_type)
		shadowed.setup(tex, Vector2(CELL_SIZE, CELL_SIZE))
		shadowed.position = Vector2(offset.x * CELL_SIZE, offset.y * CELL_SIZE)
		block_sprites.add_child(shadowed)


func _update_ghost() -> void:
	# Clear existing ghost sprites
	for child in ghost_sprites.get_children():
		child.queue_free()

	# Find drop position
	var ghost_pos: Vector2i = grid_position
	while _is_valid_position(ghost_pos + Vector2i(0, 1), current_rotation):
		ghost_pos.y += 1

	if ghost_pos == grid_position:
		return  # No ghost needed if already at bottom

	# Calculate offset from current position to ghost position
	var ghost_offset: Vector2i = ghost_pos - grid_position

	# Create ghost sprites
	var blocks: Array = GameData.get_shape_blocks(current_shape, current_rotation)
	var block_type: String = current_special_type
	var texture_path: String = GameData.get_block_texture_path(block_type)

	for offset: Vector2i in blocks:
		var sprite: Sprite2D = Sprite2D.new()
		if texture_path != "" and ResourceLoader.exists(texture_path):
			sprite.texture = load(texture_path)
		else:
			sprite.texture = _create_colored_texture(block_type)
		sprite.modulate = Color(1, 1, 1, 0.3)
		# Position relative to moving piece (ghost_offset + block offset)
		sprite.position = Vector2(
			(offset.x + ghost_offset.x) * CELL_SIZE + CELL_SIZE / 2,
			(offset.y + ghost_offset.y) * CELL_SIZE + CELL_SIZE / 2
		)
		ghost_sprites.add_child(sprite)


func _create_colored_texture(block_type: String) -> ImageTexture:
	var color: Color = BLOCK_COLORS.get(block_type, Color.WHITE)
	var img: Image = Image.create(CELL_SIZE - 2, CELL_SIZE - 2, false, Image.FORMAT_RGBA8)
	img.fill(color)
	# Add border
	for x in range(img.get_width()):
		img.set_pixel(x, 0, color.darkened(0.3))
		img.set_pixel(x, img.get_height() - 1, color.darkened(0.5))
	for y in range(img.get_height()):
		img.set_pixel(0, y, color.lightened(0.2))
		img.set_pixel(img.get_width() - 1, y, color.darkened(0.3))
	return ImageTexture.create_from_image(img)
