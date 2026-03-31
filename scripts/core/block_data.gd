class_name BlockData extends Object


var groups: Array[GameData.BlockGroups] = []
var minimum_reward_count: int = 1
var maximum_reward_count: int = 1

var requirements: Array[String] = []


func _init(groups_value: Array[GameData.BlockGroups], minimum_reward_count_value: int, maximum_reward_count_value: int, requirements_value: Array[String] = []) -> void :
	groups = groups_value
	minimum_reward_count = minimum_reward_count_value
	maximum_reward_count = maximum_reward_count_value
	requirements = requirements_value
