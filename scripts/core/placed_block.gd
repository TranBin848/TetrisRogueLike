class_name PlacedBlock extends Node2D

## Emitted when this block is destroyed
signal destroyed()

# =============================================================================
# CONSTANTS
# =============================================================================

const GROUP_NAME: String = "PlacedBlocks"
const DESTROY_ANIMATION_DURATION: float = 0.3
const CELL_SIZE: int = 32

## Shadow settings
const SHADOW_OFFSET: Vector2 = Vector2(2, 2)
const SHADOW_COLOR: Color = Color("2f2f2f")
const OUTLINE_COLOR: Color = Color("2f2f2f")

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
# EXPORTED
# =============================================================================

@export var type: String = "cyan":
	set(value):
		type = value
		_update_texture()

# =============================================================================
# STATE
# =============================================================================

var grid_position: Vector2i = Vector2i.ZERO
var destroy_animation_requested: bool = false
var custom_variables: Dictionary = {}

# =============================================================================
# NODES
# =============================================================================

@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var outline_sprite: Sprite2D = $OutlineSprite
@onready var sprite: Sprite2D = $Sprite
@onready var flash_sprite: Sprite2D = $FlashSprite

## White texture for shadow/outline
var _white_texture: Texture2D = null

# =============================================================================
# STATIC - Sound pitch escalation during chain reactions
# =============================================================================

static var destroy_base_pitch: float = 0.4

static func reset_destroy_pitch() -> void:
	destroy_base_pitch = 0.4

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	add_to_group(GROUP_NAME)
	flash_sprite.visible = false
	_create_white_texture()
	_update_texture()


func _create_white_texture() -> void:
	var img: Image = Image.create(CELL_SIZE, CELL_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_white_texture = ImageTexture.create_from_image(img)


func _update_texture() -> void:
	if not is_inside_tree():
		return
	var texture_path: String = GameData.get_block_texture_path(type)
	if texture_path != "" and ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
		flash_sprite.texture = sprite.texture
	else:
		# Use colored fallback texture
		_create_colored_texture()

	# Update shadow and outline
	_update_shadow_outline()


func _create_colored_texture() -> void:
	var color: Color = BLOCK_COLORS.get(type, Color.WHITE)
	var img: Image = Image.create(CELL_SIZE - 2, CELL_SIZE - 2, false, Image.FORMAT_RGBA8)
	img.fill(color)
	# Add border
	for x in range(img.get_width()):
		img.set_pixel(x, 0, color.darkened(0.3))
		img.set_pixel(x, img.get_height() - 1, color.darkened(0.5))
	for y in range(img.get_height()):
		img.set_pixel(0, y, color.lightened(0.2))
		img.set_pixel(img.get_width() - 1, y, color.darkened(0.3))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	sprite.texture = tex
	flash_sprite.texture = tex


func _update_shadow_outline() -> void:
	if _white_texture == null:
		return

	# Shadow sprite (offset, dark color)
	shadow_sprite.texture = _white_texture
	shadow_sprite.modulate = SHADOW_COLOR

	# Outline sprite (same position as main, dark color, slightly larger)
	outline_sprite.texture = _white_texture
	outline_sprite.modulate = OUTLINE_COLOR
	outline_sprite.scale = Vector2(1.06, 1.06)  # Slightly larger for outline effect

# =============================================================================
# POSITION
# =============================================================================

func set_grid_position(pos: Vector2i) -> void:
	grid_position = pos
	position = Vector2(pos.x * CELL_SIZE, pos.y * CELL_SIZE)


func get_center_position() -> Vector2:
	return global_position + Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)


func animate_fall_to(target_y: float, duration: float = 0.15) -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", target_y, duration)

# =============================================================================
# ADJACENCY
# =============================================================================

func get_adjacent_blocks() -> Array[PlacedBlock]:
	var adjacent: Array[PlacedBlock] = []
	var offsets: Array[Vector2i] = [
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(0, -1), Vector2i(0, 1)
	]

	for block: Node in get_tree().get_nodes_in_group(GROUP_NAME):
		if block == self or not is_instance_valid(block):
			continue
		var placed_block: PlacedBlock = block as PlacedBlock
		if placed_block:
			for offset in offsets:
				if placed_block.grid_position == grid_position + offset:
					adjacent.append(placed_block)
					break

	return adjacent


func get_blocks_in_range(range_val: int) -> Array[PlacedBlock]:
	var blocks: Array[PlacedBlock] = []

	for block: Node in get_tree().get_nodes_in_group(GROUP_NAME):
		if block == self or not is_instance_valid(block):
			continue
		var placed_block: PlacedBlock = block as PlacedBlock
		if placed_block:
			var dist: int = abs(placed_block.grid_position.x - grid_position.x) + abs(placed_block.grid_position.y - grid_position.y)
			if dist <= range_val:
				blocks.append(placed_block)

	return blocks

# =============================================================================
# DESTRUCTION
# =============================================================================

func is_destroyed() -> bool:
	return destroy_animation_requested


func destroy() -> void:
	if destroy_animation_requested:
		return

	destroy_animation_requested = true
	destroyed.emit()
	remove_from_group(GROUP_NAME)

	GameManager.block_destroyed.emit(self)

	# Flash effect
	flash_sprite.visible = true
	flash_sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)

	# Sound with escalating pitch
	# TODO: AudioManager.play(AudioManager.SoundEffects.BLOCK_DESTROY, destroy_base_pitch)
	destroy_base_pitch = minf(destroy_base_pitch + 0.05, 1.8)

	# Squash animation
	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.2, 0), DESTROY_ANIMATION_DURATION)
	tween.parallel().tween_property(flash_sprite, "scale", Vector2(1.2, 0), DESTROY_ANIMATION_DURATION)
	tween.parallel().tween_property(flash_sprite, "modulate:a", 0.0, DESTROY_ANIMATION_DURATION)
	tween.parallel().tween_property(shadow_sprite, "scale", Vector2(1.2, 0), DESTROY_ANIMATION_DURATION)
	tween.parallel().tween_property(outline_sprite, "scale", Vector2(1.2, 0), DESTROY_ANIMATION_DURATION)

	tween.tween_callback(func():
		queue_free()
	)

	# Execute type-specific effects
	execute_destroy_effect()


func execute_destroy_effect() -> void:
	# Normal blocks give base points and show floating text
	GameManager.add_score(1)
	_spawn_floating_text("+1")

# =============================================================================
# FLOATING TEXT
# =============================================================================

func _spawn_floating_text(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Style the label
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)

	# Position at center of block
	label.global_position = global_position + Vector2(CELL_SIZE / 2.0 - 10, CELL_SIZE / 2.0 - 8)
	label.z_index = 100

	# Add to scene tree
	get_tree().current_scene.add_child(label)

	# Animate: float up and fade out
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)

# =============================================================================
# PULSE ANIMATION (for activation feedback)
# =============================================================================

func pulse_animation(flash: bool = true) -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.5).from(Vector2.ONE * 1.5)
	tween.parallel().tween_property(shadow_sprite, "scale", Vector2.ONE, 0.5).from(Vector2.ONE * 1.5)
	tween.parallel().tween_property(outline_sprite, "scale", Vector2(1.06, 1.06), 0.5).from(Vector2.ONE * 1.5)

	if flash:
		tween.parallel().tween_property(
			sprite, "modulate",
			Color.WHITE, 0.4
		).from(Color(1.5, 1.5, 1.5, 1.0))
