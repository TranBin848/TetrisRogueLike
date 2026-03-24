extends Node
enum DeckTypes {
	NORMAL,
	MOAI,
	X
}

const BLOCK_TYPES: Dictionary = {
	"NORMAL": "normal",
	"MOAI":   "moai",
	"X":      "x",
}

var _texture_cache: Dictionary = {}

func get_block_texture_path(block_type: String) -> String:
	match block_type:
		"normal": return "res://sprite/blocks/default/red.png"
		"moai":   return "res://sprite/blocks/moai/orange.png"
		"x":      return "res://sprite/blocks/the_x/blue.png"
		_:        return "res://sprite/blocks/" + block_type + ".png"

func get_block_texture(block_type: String) -> CompressedTexture2D:
	if _texture_cache.has(block_type):
		return _texture_cache[block_type]
 
	var path: String = get_block_texture_path(block_type)
	var texture: CompressedTexture2D = load(path)
	_texture_cache[block_type] = texture
	return texture

func is_valid_block_type(block_type: String) -> bool:
	for key in BLOCK_TYPES:
		if BLOCK_TYPES[key] == block_type:
			return true
	return false
