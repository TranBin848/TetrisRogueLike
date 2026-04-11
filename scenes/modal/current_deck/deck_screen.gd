class_name DeckScreen extends ModalRect


const DECK_PIECE_RENDERER_SCENE: PackedScene = preload("res://scenes/modal/current_deck/deck_piece_renderer.tscn")
const INVENTORY_PERK_SCENE: PackedScene = preload("res://scenes/inventory_perk_icon.tscn")


var tooltip_tween: Tween = null


@onready var close_button: BouncyButton = $CenterContainer/VBoxContainer/PanelContainer/VBoxContainer/CloseButton
@onready var deck_grid_container: GridContainer = $CenterContainer/VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer/RightMarginContainer/DeckGridContainer
@onready var panel_container: PanelContainer = $CenterContainer / VBoxContainer / PanelContainer
@onready var perk_grid_container: GridContainer = $CenterContainer/VBoxContainer/PanelContainer/PerksAnchorPoint/GridContainer

@onready var tooltip_description_panel: PanelContainer = $CenterContainer/VBoxContainer/TooltipDescription
@onready var tooltip_title_label: LabelShadowed = $CenterContainer/VBoxContainer/TooltipDescription/VBoxContainer/TooltipTitleLabel
@onready var tooltip_description_label: RichTextLabelShadowed = $CenterContainer/VBoxContainer/TooltipDescription/VBoxContainer/RichTextLabelShadowed


func _ready() -> void :
	GameManager.paused = true

	appear_animation()

	var piece_counts: Dictionary = {}
	var original_piece_counts: Dictionary = {}

	for shape_type: PieceRenderer.ShapeType in GameManager.original_pieces.keys():
		for block_type: String in GameManager.original_pieces[shape_type]:
			var key: String = str(shape_type) + "|" + str(block_type)
			if original_piece_counts.has(key):
				original_piece_counts[key] += 1
			else:
				original_piece_counts[key] = 1

	for shape_type: PieceRenderer.ShapeType in GameManager.pieces.keys():
		for block_type: String in GameManager.pieces[shape_type]:
			var key: String = str(shape_type) + "|" + str(block_type)
			if piece_counts.has(key):
				piece_counts[key] += 1
			else:
				piece_counts[key] = 1

	var sorted_pieces: Array = []
	for key: String in original_piece_counts.keys():
		var parts: PackedStringArray = key.split("|")
		var shape_type: PieceRenderer.ShapeType = int(parts[0]) as PieceRenderer.ShapeType
		var block_type: String = parts[1]
		var current_count: int = piece_counts.get(key, 0)
		var original: int = original_piece_counts[key]

		sorted_pieces.append({
			"shape": shape_type, 
			"type": block_type, 
			"count": current_count, 
			"original_count": original
		})


	sorted_pieces.sort_custom( func(a: Dictionary, b: Dictionary) -> bool:
		return a.count < b.count
	)


	for piece_data: Dictionary in sorted_pieces:
		var instance: DeckPieceRenderer = DECK_PIECE_RENDERER_SCENE.instantiate()
		deck_grid_container.add_child(instance)

		instance.shape = piece_data.shape
		instance.type = piece_data.type
		instance.count = piece_data.count
		instance.original_count = piece_data.original_count

		instance.focus_entered.connect( func() -> void :
			_update_tooltip(instance)
		)

	deck_grid_container.get_child(0).grab_focus()

	for perk_id in GameManager.perk_levels.keys():
		InventoryPerkIcon.create(perk_grid_container, perk_id)

	var equipped_count: int = GameManager.perk_levels.size()
	var empty_slots: Array[Node] = []
	for child in perk_grid_container.get_children():
		if child is TextureRect and child.name.begins_with("EmptySlot_"):
			empty_slots.append(child)

	for i in range(equipped_count):
		if i < empty_slots.size():
			perk_grid_container.remove_child(empty_slots[i])
			empty_slots[i].queue_free()

	var slot_index: int = 0
	for perk_id in GameManager.perk_levels.keys():
		for child in perk_grid_container.get_children():
			if child is InventoryPerkIcon and (child as InventoryPerkIcon).perk == perk_id:
				perk_grid_container.move_child(child, slot_index)
				slot_index += 1
				break


	if deck_grid_container.get_child_count() > 0:
		_update_tooltip(deck_grid_container.get_child(0) as DeckPieceRenderer)

	close_button.pressed.connect( func() -> void :
		_close()
	)

	super ()


func _process(_delta: float) -> void :
	if visible:
		panel_container.pivot_offset = panel_container.size / 2


func _unhandled_input(event: InputEvent) -> void :
	if event.is_action_pressed("pause") or event.is_action_pressed("user_show_deck") or event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void :
	GameManager.paused = false
	queue_free()


func _update_tooltip(piece: DeckPieceRenderer) -> void :
	#AudioManager.play(AudioManager.SoundEffects.BLOOP_HIGH, randf_range(0.9, 1.1))

	var tooltip_data: Dictionary = piece.get_tooltip_data()

	tooltip_description_panel.modulate.a = 1
	tooltip_title_label.text = tooltip_data.title
	tooltip_description_label.text = tooltip_data.description

	await get_tree().process_frame

	if tooltip_tween and tooltip_tween.is_running():
		tooltip_tween.kill()

	tooltip_description_panel.pivot_offset = tooltip_description_panel.size / 2
	tooltip_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tooltip_tween.parallel().tween_property(tooltip_description_panel, "scale", Vector2.ONE, 0.3).from(Vector2(1.1, 0.9))


func _clear_tooltip() -> void :
	tooltip_title_label.text = ""
	tooltip_description_label.text = ""
	tooltip_description_panel.modulate.a = 0.5


func appear_animation() -> void :
	visible = true

	panel_container.modulate.a = 0.0

	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	#tween.tween_callback( func():
		##AudioManager.play(AudioManager.SoundEffects.BLOOP_HIGH, 1.4)
	#)

	tween.tween_property(panel_container, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(panel_container, "scale", Vector2.ONE, 0.3).from(Vector2(1.1, 0.9))
