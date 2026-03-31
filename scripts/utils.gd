class_name Utils

#const XBOX_A_TEXTURE: CompressedTexture2D = preload("res://images/xbox_a.png")
#const XBOX_B_TEXTURE: CompressedTexture2D = preload("res://images/xbox_b.png")
#const XBOX_X_TEXTURE: CompressedTexture2D = preload("res://images/xbox_x.png")
#const XBOX_Y_TEXTURE: CompressedTexture2D = preload("res://images/xbox_y.png")
#
#const PLAYSTATION_CROSS_TEXTURE: CompressedTexture2D = preload("res://images/playstation_x.png")
#const PLAYSTATION_SQUARE_TEXTURE: CompressedTexture2D = preload("res://images/playstation_square.png")
#const PLAYSTATION_CIRCLE_TEXTURE: CompressedTexture2D = preload("res://images/playstation_circle.png")
#const PLAYSTATION_TRIANGLE_TEXTURE: CompressedTexture2D = preload("res://images/playstation_triangle.png")
#
#const SWITCH_B_TEXTURE: CompressedTexture2D = preload("res://images/switch_b.png")
#const SWITCH_A_TEXTURE: CompressedTexture2D = preload("res://images/switch_a.png")
#const SWITCH_Y_TEXTURE: CompressedTexture2D = preload("res://images/switch_y.png")
#const SWITCH_X_TEXTURE: CompressedTexture2D = preload("res://images/switch_x.png")
#
#const UNKNOWN_BUTTON_TEXTURE: CompressedTexture2D = preload("res://images/unknown_controller_button.png")

#const JOY_BUTTON_TEXTURE_MAP: Dictionary[String, Dictionary] = {
	#"xbox": {
		#JOY_BUTTON_A: XBOX_A_TEXTURE, 
		#JOY_BUTTON_X: XBOX_X_TEXTURE, 
		#JOY_BUTTON_Y: XBOX_Y_TEXTURE, 
		#JOY_BUTTON_B: XBOX_B_TEXTURE, 
		#JOY_BUTTON_DPAD_RIGHT: preload("res://images/dpad_right.png"), 
		#JOY_BUTTON_DPAD_LEFT: preload("res://images/dpad_left.png"), 
		#JOY_BUTTON_DPAD_UP: preload("res://images/dpad_up.png"), 
		#JOY_BUTTON_DPAD_DOWN: preload("res://images/dpad_down.png"), 
		#JOY_BUTTON_RIGHT_SHOULDER: preload("res://images/xbox_right_shoulder.png"), 
		#JOY_BUTTON_LEFT_SHOULDER: preload("res://images/xbox_left_shoulder.png"), 
	#}, 
	#"playstation": {
		#JOY_BUTTON_A: PLAYSTATION_CROSS_TEXTURE, 
		#JOY_BUTTON_X: PLAYSTATION_SQUARE_TEXTURE, 
		#JOY_BUTTON_Y: PLAYSTATION_TRIANGLE_TEXTURE, 
		#JOY_BUTTON_B: PLAYSTATION_CIRCLE_TEXTURE, 
		#JOY_BUTTON_RIGHT_SHOULDER: preload("res://images/playstation_right_shoulder.png"), 
		#JOY_BUTTON_LEFT_SHOULDER: preload("res://images/playstation_left_shoulder.png"), 
	#}, 
	#"switch": {
		#JOY_BUTTON_A: SWITCH_B_TEXTURE, 
		#JOY_BUTTON_X: SWITCH_Y_TEXTURE, 
		#JOY_BUTTON_Y: SWITCH_X_TEXTURE, 
		#JOY_BUTTON_B: SWITCH_A_TEXTURE, 
		#JOY_BUTTON_RIGHT_SHOULDER: preload("res://images/switch_right_shoulder.png"), 
		#JOY_BUTTON_LEFT_SHOULDER: preload("res://images/switch_left_shoulder.png"), 
	#}
#}


#static func get_button_texture_based_on_controller(button: JoyButton) -> CompressedTexture2D:
	#var connected_joypads: = Input.get_connected_joypads()
#
	#if connected_joypads.size() > 0:
		#var joypad_name: String = Input.get_joy_name(connected_joypads[0]).to_lower()
#
		#if joypad_name.contains("xbox"):
			#return JOY_BUTTON_TEXTURE_MAP["xbox"].get(button, UNKNOWN_BUTTON_TEXTURE)
#
		#elif joypad_name.contains("playstation") or joypad_name.contains("dualshock") or joypad_name.contains("sony"):
			#return JOY_BUTTON_TEXTURE_MAP["playstation"].get(button, UNKNOWN_BUTTON_TEXTURE)
#
		#elif joypad_name.contains("switch"):
			#return JOY_BUTTON_TEXTURE_MAP["switch"].get(button, UNKNOWN_BUTTON_TEXTURE)
#
	#return JOY_BUTTON_TEXTURE_MAP["xbox"].get(button, UNKNOWN_BUTTON_TEXTURE)


static func add_commas_to_number(number: Variant) -> String:
	var number_string: String = str(number)
	var is_negative: bool = number_string.begins_with("-")

	if is_negative:
		number_string = number_string.substr(1)

	var result: String = ""
	var count: int = 0

	for i in range(number_string.length() - 1, -1, -1):
		result = number_string[i] + result
		count += 1

		if count % 3 == 0 and i != 0:
			result = "," + result

	if is_negative:
		result = "-" + result

	return result
