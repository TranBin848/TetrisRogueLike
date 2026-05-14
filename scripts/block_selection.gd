class_name BlockSelectionScreen extends Node2D

const FIRST_APPEAR_DELAY: float = 1.5
const BLOCK_BUTTON_ANIMATION_DELAY: float = 0.2
const DECK_SCREEN_SCENE: PackedScene = preload("res://scenes/modal/current_deck/deck_screen.tscn")

var previously_shown_blocks: Array[String] = []


@onready var block_button_container: HBoxContainer = $CanvasLayer/MarginContainer/BlockButtonContainer
@onready var reward_label: RichTextLabelShadowed = $CanvasLayer/MarginContainer/TopTitleContainer/PickYourRewardLabel
@onready var reward_description_label: LabelShadowed = $CanvasLayer/MarginContainer/TopTitleContainer/PickYourRewardDescriptionLabel
@onready var roll_button: BouncyButton = $CanvasLayer/MarginContainer/BottomContainer/RerollButton
@onready var skip_button: BouncyButton = $CanvasLayer/MarginContainer/BottomContainer/SkipButton
@onready var inventory_button: BouncyButton = $CanvasLayer/MarginContainer/BottomContainer/InventoryButton
@onready var overlay_hud: CanvasLayer = $OverlayHUD
@onready var bottom_container: HBoxContainer = $CanvasLayer/MarginContainer/BottomContainer


@onready var block_button_1: BlockButton = $CanvasLayer/MarginContainer/BlockButtonContainer/BlockButton_1
@onready var block_button_2: BlockButton = $CanvasLayer/MarginContainer/BlockButtonContainer/BlockButton_2
@onready var block_button_3: BlockButton = $CanvasLayer/MarginContainer/BlockButtonContainer/BlockButton_3


func _ready() -> void :
	reward_label.text = "[wave]" + tr("BLOCK_REWARD")


	GameManager.rolls_changed.connect(_update_roll_button_text)
	_update_roll_button_text(GameManager.rolls_left)


	skip_button.text = tr("BUTTON_SKIP") + "(+2)"

	for i in block_button_container.get_child_count():
		var block_button: BlockButton = block_button_container.get_child(i) as BlockButton
		if is_instance_valid(block_button):
			block_button.modulate.a = 0
			block_button.pivot_offset = block_button.size / 2


	_setup_focus_navigation()

	for i in block_button_container.get_child_count():
		var block_button: BlockButton = block_button_container.get_child(i) as BlockButton

		if not is_instance_valid(block_button):
			continue

		block_button.pressed.connect( func() -> void :
			for button: BlockButton in block_button_container.get_children():
				if button != block_button:
					button.modulate.a = 0.2

				button.disabled = true

			skip_button.disabled = true
			roll_button.disabled = true
			inventory_button.disabled = true
		)

	roll_button.pressed.connect( func() -> void :
		if not GameManager.can_roll():
			return
		GameManager.use_roll()
		randomize_blocks()

		if not GameManager.can_roll():
			roll_button.disabled = true
	)

	skip_button.pressed.connect( func() -> void :
		skip_button.disabled = true

		GameManager.add_rolls(2)
		GameManager.increment_blocks_skipped()
		GameManager.goto_level_selection()
	)

	inventory_button.pressed.connect( func() -> void :
		var deck_screen: DeckScreen = DECK_SCREEN_SCENE.instantiate() as DeckScreen
		overlay_hud.add_child(deck_screen)
		deck_screen.focus_on_destroy = inventory_button
	)

	bottom_container.modulate.a = 0

	await get_tree().create_timer(FIRST_APPEAR_DELAY).timeout
	randomize_blocks()

	await get_tree().create_timer(BLOCK_BUTTON_ANIMATION_DELAY * 3).timeout


	var buttons_tween: Tween = create_tween().set_ease(Tween.EASE_OUT)
	buttons_tween.set_trans(Tween.TRANS_LINEAR).tween_property(bottom_container, "modulate:a", 1.0, 0.1).from(0.0)
	buttons_tween.set_trans(Tween.TRANS_BACK).parallel().tween_property(bottom_container, "global_position:y", bottom_container.global_position.y, 0.3).from(bottom_container.global_position.y - 6)


func randomize_blocks() -> void :
	var block_types_available: Array[String] = []


	var sorted_block_types: Array = GameData.blocks.keys()
	sorted_block_types.remove_at(sorted_block_types.size() - 1); # Indestructibles block
	sorted_block_types.sort()
	print(sorted_block_types.size());

	for block_type: String in sorted_block_types:

		if block_type in [GameData.BLOCK_TYPES.NORMAL]:
			continue


		var block_data: BlockData = GameData.blocks[block_type]
		if not block_data.requirements.is_empty():

			var requirements_met: bool = false
			for required_block_type: String in block_data.requirements:
				if GameManager.has_block_type_in_original_deck(required_block_type):
					requirements_met = true
					break

			if not requirements_met:
				print("[Block Selection] Skipping %s - requirements not met: %s" % [
					GameData.get_block_name(block_type), 
					str(block_data.requirements.map( func(req): return GameData.get_block_name(req)))
				])
				continue

		if block_type not in previously_shown_blocks:
			block_types_available.append(block_type)


	var active_groups: Array[GameData.BlockGroups] = GameManager.get_active_groups_in_deck()


	var block_weights: Dictionary = {}

	for block_type: String in block_types_available:
		var weight: float = 1.0


		var block_data: BlockData = GameData.blocks[block_type]
		for group in block_data.groups:
			if group in active_groups:
				weight = 1.15
				break

		block_weights[block_type] = weight


	previously_shown_blocks.clear()

	for i in block_button_container.get_child_count():
		var block_button: BlockButton = block_button_container.get_child(i) as BlockButton

		if not is_instance_valid(block_button):
			continue

		if block_weights.is_empty():

			var all_block_types: Array = GameData.get_all_block_types()
			all_block_types.erase(GameData.BLOCK_TYPES.NORMAL)
			all_block_types.erase(GameData.BLOCK_TYPES.MOAI)
			all_block_types.erase(GameData.BLOCK_TYPES.X)
			Random.shuffle(all_block_types)
			block_button.type = all_block_types[i % all_block_types.size()]
		else:

			var selected_block_type: String = _weighted_random_selection(block_weights)


			block_weights.erase(selected_block_type)

			block_button.type = selected_block_type
			previously_shown_blocks.append(selected_block_type)

		block_button.disabled = false
		block_button.modulate.a = 0
		block_button.scale = Vector2(1.1, 0.8)

	animate_block_buttons()



func _weighted_random_selection(weights: Dictionary) -> String:
	var total_weight: float = 0.0


	var sorted_keys: Array = weights.keys()
	sorted_keys.sort()


	for block_type in sorted_keys:
		total_weight += weights[block_type]


	var random_value: float = Random.randf() * total_weight


	var cumulative_weight: float = 0.0
	for block_type in sorted_keys:
		cumulative_weight += weights[block_type]
		if random_value <= cumulative_weight:
			return block_type


	return sorted_keys[0]


func animate_block_buttons() -> void :
	var pop_sound_pitch: float = 1.0 + randf_range(-0.1, 0.1)

	for block_button: BlockButton in block_button_container.get_children():
		if not is_instance_valid(block_button):
			continue

		var tween: = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(block_button, "scale", Vector2.ONE, 0.3).from(Vector2(1.1, 0.8))

		block_button.modulate.a = 1

		#AudioManager.play(AudioManager.SoundEffects.POP, pop_sound_pitch)
		#AudioManager.play(AudioManager.SoundEffects.BLOOP_HIGH, pop_sound_pitch)

		pop_sound_pitch += 0.1

		await get_tree().create_timer(BLOCK_BUTTON_ANIMATION_DELAY).timeout

	var first_block_button: BlockButton = block_button_container.get_child(0) as BlockButton

	first_block_button.button.grab_focus()
	($OverlayHUD/PauseMenu as PauseMenu).focus_on_destroy = first_block_button.button


func _update_roll_button_text(rolls: int) -> void :
	roll_button.text = tr("BUTTON_ROLL") + "(%d)" % rolls
	roll_button.disabled = not GameManager.can_roll()


func _setup_focus_navigation() -> void :
	block_button_1.button.focus_neighbor_right = block_button_2.button.get_path()
	block_button_1.button.focus_neighbor_left = block_button_3.button.get_path()

	block_button_2.button.focus_neighbor_left = block_button_1.button.get_path()
	block_button_2.button.focus_neighbor_right = block_button_3.button.get_path()

	block_button_3.button.focus_neighbor_left = block_button_2.button.get_path()
	block_button_3.button.focus_neighbor_right = block_button_1.button.get_path()


	skip_button.focus_neighbor_left = roll_button.get_path()
	roll_button.focus_neighbor_right = skip_button.get_path()


func _notification(what: int) -> void :
	if not is_instance_valid(reward_label):
		return

	if what == NOTIFICATION_TRANSLATION_CHANGED:
		reward_label.text = "[wave]" + tr("BLOCK_REWARD")
		_update_roll_button_text(GameManager.rolls_left)
		skip_button.text = tr("BUTTON_SKIP") + "(+2)"
