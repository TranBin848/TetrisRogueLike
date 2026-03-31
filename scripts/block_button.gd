class_name BlockButton extends Control

signal pressed()

const BLOCK_TYPE_PANEL_SCENE: PackedScene = preload("res://scenes/blockselection/block_type_panel.tscn")
const DEFAULT_MINIMUM_SIZE: Vector2 = Vector2(130, 170)

var awarded_piece_types: Array[GameData.ShapeType] = []
var current_piece_index: int = 0

var type: String = GameData.BLOCK_TYPES.NORMAL:
	set(value):
		type = value

		var key: String = GameData.get_block_name(value)

		title_label.text = "BLOCK_" + key
		description_label.text = GameManager.replace_tags(tr("BLOCK_" + key + "_DESCRIPTION"))

		var block_data: BlockData = GameData.blocks[type]
		var shapes_count: int = Random.randi_range(block_data.minimum_reward_count, block_data.maximum_reward_count)

		awarded_piece_types = get_balanced_shape_selection(shapes_count)

		count_label.text = "x" + str(shapes_count)

		for child in types_hbox_container.get_children():
			child.queue_free()

		for group in block_data.groups:
			var block_type_panel: BlockTypePanel = BLOCK_TYPE_PANEL_SCENE.instantiate()
			types_hbox_container.add_child(block_type_panel)
			block_type_panel.block_group = group


		current_piece_index = 0
		update_piece_display()


var disabled: bool = false:
	set(value):
		disabled = value
		button.disabled = value


@onready var button: BouncyButton = $Button
@onready var margin_container: MarginContainer = $MarginContainer
@onready var piece_container: Control = %PieceContainer
@onready var piece_renderer: PieceRenderer = %PieceRenderer
@onready var count_label: LabelShadowed = %CountLabel
@onready var title_label: LabelShadowed = %TitleLabel
@onready var description_label: RichTextLabelShadowed = %DescriptionLabel
@onready var piece_change_timer: Timer = $PieceChangeTimer
@onready var types_hbox_container: HBoxContainer = %TypesHBoxContainer


func center_piece(piece_type: GameData.ShapeType) -> void :
	var bounds: Rect2i = piece_renderer.get_piece_bounds(piece_type, 0)

	if bounds.size == Vector2i.ZERO:
		return

	var piece_pixel_width = bounds.size.x * PieceRenderer.PIECE_SIZE
	var piece_pixel_height = bounds.size.y * PieceRenderer.PIECE_SIZE

	var center_x = (piece_container.size.x - piece_pixel_width) / 2.0
	var center_y = (piece_container.size.y - piece_pixel_height) / 2.0

	var offset_x = center_x - (bounds.position.x * PieceRenderer.PIECE_SIZE)
	var offset_y = center_y - (bounds.position.y * PieceRenderer.PIECE_SIZE)

	piece_renderer.position = Vector2(offset_x, offset_y)



func update_piece_display() -> void :
	if awarded_piece_types.size() > 0:
		var piece_type = awarded_piece_types[current_piece_index]
		piece_renderer.set_piece(piece_type, 0, true, type)
		center_piece(piece_type)


func _ready() -> void :
	piece_renderer.set_piece(GameData.ShapeType.T, 0, false, type)
	center_piece(GameData.ShapeType.T)


	piece_change_timer.timeout.connect( func():
		if awarded_piece_types.size() > 1:
			current_piece_index = (current_piece_index + 1) % awarded_piece_types.size()
			update_piece_display()
	)

	button.pressed.connect( func() -> void :
		pressed.emit()

		for shape_type in awarded_piece_types:
			GameManager.add_piece_to_original_deck(type, shape_type)

		GameManager.save_game()

		await get_tree().create_timer(1.5).timeout
		GameManager.goto_level_selection()
	)


func _process(_delta: float) -> void :
	var margin_container_min_size: Vector2 = margin_container.get_combined_minimum_size()

	custom_minimum_size.x = max(DEFAULT_MINIMUM_SIZE.x, margin_container_min_size.x)
	custom_minimum_size.y = max(DEFAULT_MINIMUM_SIZE.y, margin_container_min_size.y)


func _notification(what: int) -> void :
	if not is_instance_valid(description_label):
		return

	if what == NOTIFICATION_TRANSLATION_CHANGED:
		var key: String = GameData.get_block_name(type)
		description_label.text = GameManager.replace_tags(tr("BLOCK_" + key + "_DESCRIPTION"))




func get_balanced_shape_selection(shapes_count: int) -> Array[GameData.ShapeType]:
	var selected_shapes: Array[GameData.ShapeType] = []
	var all_shapes: Array = GameData.ShapeType.values()


	var shape_counts: Dictionary = {}
	for shape_type in all_shapes:
		var count: int = 0
		if GameManager.original_pieces.has(shape_type):
			count = GameManager.original_pieces[shape_type].size()
		shape_counts[shape_type] = count


	var min_count: int = 999999
	for shape_type in all_shapes:
		if shape_counts[shape_type] < min_count:
			min_count = shape_counts[shape_type]


	var all_equal: bool = true
	for shape_type in all_shapes:
		if shape_counts[shape_type] != min_count:
			all_equal = false
			break


	var selection_pool: Array = []
	if all_equal:

		selection_pool = all_shapes.duplicate()
		Random.shuffle(selection_pool)
	else:

		var lowest_shapes: Array = []
		for shape_type in all_shapes:
			if shape_counts[shape_type] == min_count:
				lowest_shapes.append(shape_type)



		if lowest_shapes.size() < shapes_count:

			var sorted_shapes: Array = all_shapes.duplicate()
			sorted_shapes.sort_custom( func(a, b): return shape_counts[a] < shape_counts[b])


			for i in min(shapes_count, sorted_shapes.size()):
				if not selection_pool.has(sorted_shapes[i]):
					selection_pool.append(sorted_shapes[i])

			Random.shuffle(selection_pool)
		else:

			selection_pool = lowest_shapes.duplicate()
			Random.shuffle(selection_pool)


	for i in shapes_count:
		selected_shapes.append(selection_pool[i % selection_pool.size()])

	return selected_shapes
