class_name InGamePerksContainer extends GridContainer

const SPAWN_MARGIN: Vector2 = Vector2(1, 1)


static var _self: InGamePerksContainer

var perk_icons: Dictionary[GameData.Perks, InventoryPerkIcon] = {}

static func spawn_point_notification(perk: GameData.Perks, type: int, value: Variant, angle: float = - PI / 2) -> void :
	if not is_instance_valid(_self):
		return
	if _self.perk_icons[perk] == null:
		return;
	var perk_icon: InventoryPerkIcon = _self.perk_icons[perk]
	var point_notification: PointNotification = PointNotification.create(perk_icon.global_position + perk_icon.size / 2 - SPAWN_MARGIN, type, value, randf_range(0.8, 1.2))

	point_notification.slide_animation(angle)

	if is_instance_valid(perk_icon):
		perk_icon.pulse_animation()


static func pulse_perk_icon(perk: GameData.Perks) -> void :
	if not is_instance_valid(_self):
		return

	var perk_icon: InventoryPerkIcon = _self.perk_icons[perk]

	if is_instance_valid(perk_icon):
		perk_icon.pulse_animation()


func _enter_tree() -> void :
	InGamePerksContainer._self = self


func _exit_tree() -> void :
	if InGamePerksContainer._self == self:
		InGamePerksContainer._self = null


func _ready() -> void :
	# Get Perks
	for perk in GameManager.perk_levels.keys():
		add_perk_icon(perk)

	# Get texture Slots
	var equipped_count: int = perk_icons.size()
	var empty_slots: Array[Node] = []
	for child in get_children():
		if child is TextureRect and child.name.begins_with("EmptySlot_"):
			empty_slots.append(child)

	# What?
	for i in range(equipped_count):
		if i < empty_slots.size():
			remove_child(empty_slots[i])
			empty_slots[i].queue_free()

	# Reorder
	var slot_index: int = 0
	for perk in GameManager.perk_levels.keys():
		var icon: InventoryPerkIcon = perk_icons[perk]
		if is_instance_valid(icon):
			move_child(icon, slot_index)
			slot_index += 1


func add_perk_icon(perk: GameData.Perks) -> void :
	if perk_icons.has(perk):
		return

	var perk_name: String = GameData.get_perk_name(perk)
	var perk_icon: InventoryPerkIcon = InventoryPerkIcon.create(self, perk)
	perk_icon.name = perk_name
	perk_icon.focus_mode = Control.FOCUS_NONE
	perk_icons[perk] = perk_icon
