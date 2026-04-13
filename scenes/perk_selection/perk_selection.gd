class_name PerkSelectionScreen extends Node2D


const FIRST_APPEAR_DELAY: float = 1.5
const PERK_BUTTON_ANIMATION_DELAY: float = 0.2

const DECK_SCREEN_SCENE: PackedScene = preload("res://scenes/modal/current_deck/deck_screen.tscn")

var previously_shown_perks: Array[GameData.Perks] = []

@onready var reward_label: RichTextLabelShadowed = $CanvasLayer/MarginContainer/VBoxContainer/PickYourRewardLabel
@onready var perks_container: VBoxContainer = $CanvasLayer/MarginContainer/PerkContainer
@onready var roll_button: BouncyButton = $CanvasLayer/MarginContainer/BottomContainer/RollButton
@onready var skip_button: BouncyButton = $CanvasLayer/MarginContainer/BottomContainer/SkipButton
@onready var inventory_button: BouncyButton = $CanvasLayer/MarginContainer/BottomContainer/InventoryButton
@onready var overlay_hud: CanvasLayer = $OverlayHUD
@onready var bottom_container: HBoxContainer = $CanvasLayer/MarginContainer/BottomContainer


func _ready() -> void :
	reward_label.text = "[wave]" + tr("REWARD")


	GameManager.rolls_changed.connect(_update_roll_button_text)
	_update_roll_button_text(GameManager.rolls_left)


	skip_button.text = tr("BUTTON_SKIP") + "(+2)"

	roll_button.pressed.connect( func() -> void :
		if not GameManager.can_roll():
			return

		GameManager.use_roll()
		randomize_perks()

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

	for perk_button: PerkButton in perks_container.get_children():
		perk_button.modulate.a = 0
		perk_button.pivot_offset = perk_button.size / 2

		if perk_button.perk == GameData.Perks.NONE:
			perk_button.visible = false

		perk_button.pressed.connect( func() -> void :
			if perk_button.perk == GameData.Perks.NONE:
				return

			for button: PerkButton in perks_container.get_children():
				if button != perk_button:
					button.modulate.a = 0.2

				button.disabled = true

			skip_button.disabled = true
			roll_button.disabled = true
			inventory_button.disabled = true

			#AudioManager.play(AudioManager.SoundEffects.PERK, randf_range(0.9, 1.1))


			if not GameManager.add_or_upgrade_perk(perk_button.perk):
				return

			GameManager.save_game()

			await get_tree().create_timer(1.5).timeout
			GameManager.goto_level_selection()

			print("Selected perk: %s" % GameData.get_perk_name(perk_button.perk))
		)

	bottom_container.modulate.a = 0

	(perks_container.get_children().back() as PerkButton).button.focus_neighbor_bottom = roll_button.get_path()


	await get_tree().create_timer(FIRST_APPEAR_DELAY).timeout
	randomize_perks()

	await get_tree().create_timer(PERK_BUTTON_ANIMATION_DELAY * 3).timeout

	var buttons_tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_parallel()
	buttons_tween.set_trans(Tween.TRANS_LINEAR).tween_property(bottom_container, "modulate:a", 1.0, 0.1).from(0.0)
	buttons_tween.set_trans(Tween.TRANS_BACK).tween_property(bottom_container, "global_position:y", bottom_container.global_position.y, 0.3).from(bottom_container.global_position.y - 6)


func randomize_perks() -> void :
	var new_perks: Array[GameData.Perks] = []
	var upgradable_perks: Array[GameData.Perks] = []
	var unique_perk_count: int = GameManager.get_unique_perk_count()

	for perk: GameData.Perks in GameData.Perks.values():
		if perk == GameData.Perks.NONE:
			continue

		if perk == GameData.Perks.CHAIN_REACTION and unique_perk_count == 0:
			continue

		if perk in previously_shown_perks:
			continue

		var current_level: int = GameManager.get_perk_level(perk)


		if unique_perk_count >= GameManager.MAX_PERK_SLOTS:
			if current_level > 0 and GameManager.can_upgrade_perk(perk):
				upgradable_perks.append(perk)
		else:

			if current_level == 0:

				new_perks.append(perk)
			elif GameManager.can_upgrade_perk(perk):

				upgradable_perks.append(perk)


	var perks_available: Array[GameData.Perks] = []
	var perks_to_select: int = 3


	if unique_perk_count >= GameManager.MAX_PERK_SLOTS:

		Random.shuffle(upgradable_perks)
		for i in min(perks_to_select, upgradable_perks.size()):
			perks_available.append(upgradable_perks[i])
	else:

		for i in perks_to_select:
			var use_upgradable: bool = false


			if not upgradable_perks.is_empty():

				var new_perks_selected: int = 0
				var upgradable_perks_selected: int = 0
				for selected_perk in perks_available:
					if GameManager.get_perk_level(selected_perk) > 0:
						upgradable_perks_selected += 1
					else:
						new_perks_selected += 1


				var upgradable_chance: float = 0.3
				if upgradable_perks_selected == 0 and new_perks_selected >= 2:
					upgradable_chance = 0.5
				elif upgradable_perks_selected >= 2:
					upgradable_chance = 0.1

				use_upgradable = Random.randf() < upgradable_chance


			if use_upgradable and not upgradable_perks.is_empty():
				var selected_perk: GameData.Perks = Random.pick_random(upgradable_perks)
				perks_available.append(selected_perk)
				upgradable_perks.erase(selected_perk)
			elif not new_perks.is_empty():
				var selected_perk: GameData.Perks = Random.pick_random(new_perks)
				perks_available.append(selected_perk)
				new_perks.erase(selected_perk)
			elif not upgradable_perks.is_empty():

				var selected_perk: GameData.Perks = Random.pick_random(upgradable_perks)
				perks_available.append(selected_perk)
				upgradable_perks.erase(selected_perk)


	previously_shown_perks.clear()

	for perk_button: PerkButton in perks_container.get_children():
		if perks_available.is_empty():
			perk_button.perk = GameData.Perks.NONE
			perk_button.visible = false
		else:
			var selected_perk: GameData.Perks = perks_available.pop_back()

			perk_button.perk = selected_perk
			perk_button.visible = true
			previously_shown_perks.append(selected_perk)


			perk_button.modulate.a = 0.0
			perk_button.scale = Vector2(1.1, 0.8)

	animate_perk_buttons()


func animate_perk_buttons() -> void :
	var pop_sound_pitch: float = 1.0 + randf_range(-0.1, 0.1)

	for perk_button: PerkButton in perks_container.get_children():
		if not perk_button.visible:
			continue

		var tween: = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(perk_button, "scale", Vector2.ONE, 0.3).from(Vector2(1.1, 0.8))

		perk_button.modulate.a = 1

		#AudioManager.play(AudioManager.SoundEffects.POP, pop_sound_pitch)
		#AudioManager.play(AudioManager.SoundEffects.BLOOP_HIGH, pop_sound_pitch)

		pop_sound_pitch += 0.1

		await get_tree().create_timer(PERK_BUTTON_ANIMATION_DELAY).timeout

	var first_perk_button: PerkButton = perks_container.get_child(0)

	first_perk_button.button.grab_focus()
	( %PauseMenu as PauseMenu).focus_on_destroy = first_perk_button.button


func _update_roll_button_text(rolls: int) -> void :
	roll_button.text = tr("BUTTON_ROLL") + "(%d)" % rolls
	roll_button.disabled = not GameManager.can_roll()


func _notification(what: int) -> void :
	if not is_instance_valid(reward_label):
		return

	if what == NOTIFICATION_TRANSLATION_CHANGED:
		reward_label.text = "[wave]" + tr("REWARD")
		if is_instance_valid(roll_button):
			_update_roll_button_text(GameManager.rolls_left)
		if is_instance_valid(skip_button):
			skip_button.text = tr("BUTTON_SKIP") + "(+2)"
