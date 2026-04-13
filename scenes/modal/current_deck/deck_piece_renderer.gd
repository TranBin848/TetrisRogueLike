class_name DeckPieceRenderer extends Control


var shape: PieceRenderer.ShapeType = PieceRenderer.ShapeType.I:
	set(value):
		shape = value
		piece_renderer.set_piece(shape, 0, false, type)
		_center_piece()


var type: String = GameData.BLOCK_TYPES.NORMAL:
	set(value):
		type = value
		piece_renderer.set_piece(shape, 0, false, type)
		_center_piece()

var count: int = 0:
	set(value):
		count = value

		if count <= 0:
			count_label.modulate.a = 0.3
			piece_renderer.modulate.a = 0.3
		else:
			count_label.modulate.a = 1
			piece_renderer.modulate.a = 1

		_update_count_label()

var original_count: int = 0:
	set(value):
		original_count = value
		_update_count_label()


@onready var piece_renderer: PieceRenderer = $BackgroundRect/PieceRenderer
@onready var count_label: LabelShadowed = $CountPanelContainer/CountLabel
@onready var background_rect: NinePatchRect = $BackgroundRect
@onready var focus_rect: NinePatchRect = $FocusRect


func _ready() -> void :
	focus_rect.visible = has_focus()

	mouse_entered.connect( func() -> void :
		modulate = Color(1.2, 1.2, 1.2)
	)

	mouse_exited.connect( func() -> void :
		modulate = Color(1, 1, 1)
	)

	focus_entered.connect( func() -> void :
		focus_rect.visible = true
	)

	focus_exited.connect( func() -> void :
		focus_rect.visible = false
	)


func get_tooltip_data() -> Dictionary:
	var block_name: String = GameData.get_block_name(type)
	var title: String = tr("BLOCK_" + block_name)
	var description: String = GameManager.replace_tags(tr("BLOCK_" + block_name + "_DESCRIPTION"))

	return {
		"title": title, 
		"description": description
	}


func _update_count_label() -> void :
	if count_label:
		count_label.text = str(count) + "/" + str(original_count)


func _center_piece() -> void :
	var bounds: Rect2i = piece_renderer.get_piece_bounds(shape, 0)

	if bounds.size == Vector2i.ZERO:
		return

	var piece_pixel_width = bounds.size.x * PieceRenderer.PIECE_SIZE * piece_renderer.scale.x
	var piece_pixel_height = bounds.size.y * PieceRenderer.PIECE_SIZE * piece_renderer.scale.y

	var center_x = (40 - piece_pixel_width) / 2.0
	var center_y = (40 - piece_pixel_height) / 2.0

	var offset_x = center_x - (bounds.position.x * PieceRenderer.PIECE_SIZE * piece_renderer.scale.x)
	var offset_y = center_y - (bounds.position.y * PieceRenderer.PIECE_SIZE * piece_renderer.scale.y)

	piece_renderer.position = Vector2(offset_x, offset_y)
