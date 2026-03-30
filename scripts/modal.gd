class_name ModalRect extends ColorRect


const GROUP_NAME: StringName = &"modals"


@export var focus_on_destroy: Control


static func destroy_all_modals() -> void :
	var modals: Array[ModalRect] = []
	modals.assign(GameManager.get_tree().get_nodes_in_group(GROUP_NAME))

	for modal in modals:
		if is_instance_valid(modal):
			modal.queue_free()


func _ready() -> void :
	add_to_group(GROUP_NAME)

	visibility_changed.connect( func():
		if is_visible_in_tree():
			GameManager.current_modal = self
		else:
			if GameManager.current_modal == self:
				GameManager.current_modal = null

		if not is_visible_in_tree() and is_instance_valid(focus_on_destroy):
			focus_on_destroy.grab_focus()
	)


func _exit_tree() -> void :
	if is_instance_valid(focus_on_destroy):
		focus_on_destroy.grab_focus()
