class_name BlockData extends RefCounted

## Block type groups for categorization
var groups: Array = []

## Base point value when destroyed
var point_value: int = 1

## Multiplier bonus when destroyed
var multiplier_value: int = 0

## Special behavior identifier (for custom effects)
var special_behavior: StringName = &""


func _init(
	groups_value: Array = [],
	point_value_value: int = 1,
	multiplier_value_value: int = 0,
	special_behavior_value: StringName = &""
) -> void:
	groups = groups_value
	point_value = point_value_value
	multiplier_value = multiplier_value_value
	special_behavior = special_behavior_value


func has_group(group: GameData.BlockGroups) -> bool:
	return groups.has(group)


func is_special() -> bool:
	return special_behavior != &""
