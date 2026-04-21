extends Node

const DIZZY_ROTATION_INTERVAL: int = 4

enum Perks{
	NONE, 
	SPEED_RUN, 
	STACK_MASTER, 
	LAST_BREATH, 
	AUTOMAGIC, 
	CHAIN_REACTION, 
	SHORTCUT, 
	POINT_RUSH, 
	ACCEPTANCE, 
	SACRIFICE, 
	FULL_CLEAR, 
	PAUPER, 
	PERFECTION, 
	MOMENTUM, 
	FORGIVEN,
	
	RETRIGGER_BLOCK,
	# INFINITE_ENGINE,
	MULT_REACTOR,
	BUILDER,
	COMBO_ENGINE,
	SACRIFICE_ROW,
	PROJECTILE_HIT,
	PROJECTILE_MULT,
	ACCELERATOR,
	DREAM
}

enum DeckTypes{
	NORMAL, 
	MOAI, 
	X
}


const BLOCK_TYPES: Dictionary = {

	"NORMAL": "normal", 
	"MOAI": "moai", 
	"X": "x", 

	"GOLD": "special/common/gold", 
	"BLUE_C": "special/common/bluec", 
	"RED_C": "special/common/redc", 
	"SAND": "special/common/sand", 
	"RAINBOW": "special/common/rainbow", 

	"STONE": "stone", 
	"GRANITE": "granite", 
	"BRICK": "brick", 
	"OBSIDIAN": "obsidian", 


	"RED_DICE": "red_dice", 
	"BLUE_DICE": "blue_dice", 
	"MIXED_DICE": "mixed_dice", 
	"JACKPOT": "jackpot", 


	"BRONZE": "bronze", 
	"IRON": "iron", 
	"DIAMOND": "diamond", 


	"RADIOACTIVE": "radioactive", 
	"URANIUM": "uranium", 
	"NUKE": "nuke", 
	"REACTOR": "reactor", 


	"TNT": "tnt", 
	"BOMB": "bomb", 
	"CFOUR": "cfour", 
	"DETONATOR": "detonator", 


	"WORKER_BEE": "worker_bee", 
	"QUEEN_BEE": "queen_bee", 
	"HONEY": "honey", 
	"HIVE": "hive", 

	"HONEY_BOMB": "honey_bomb", 
	"HONEY_DICE": "honey_dice", 


	"MIMIC": "mimic", 
	"FIRE_MAGE": "fire_mage", 
	"BOOKSHELF": "bookshelf", 
	"ARCANIST": "arcanist", 


	"PIANO": "piano", 
	"ACOUSTIC_GUITAR": "acoustic_guitar", 
	"ELECTRIC_GUITAR": "electric_guitar", 
	"SPEAKERS": "speakers", 


	"SLIME": "slime", 
	"SKELETON": "skeleton", 

	"PIRATE_CAPTAIN": "pirate_captain", 
	"PIRATE_CANNONEER": "pirate_cannoneer", 
	"CANNON": "cannon", 

	"UNDEAD_PIRATE": "undead_pirate", 
	"TREASURE_CHEST": "treasure_chest", 
	"CURSED_CHEST": "cursed_chest"
}


const LEGACY_BLOCK_TYPE_MAP: Dictionary = {
	0: "normal", 
	1: "moai", 
	2: "x", 
	3: "stone", 
	4: "granite", 
	5: "brick", 
	6: "obsidian", 
	7: "red_dice", 
	8: "blue_dice", 
	9: "mixed_dice", 
	10: "jackpot", 
	11: "bronze", 
	12: "iron", 
	13: "diamond", 
	14: "radioactive", 
	15: "uranium", 
	16: "nuke", 
	17: "reactor", 
	18: "tnt", 
	19: "bomb", 
	20: "cfour", 
	21: "detonator", 
	22: "worker_bee", 
	23: "queen_bee", 
	24: "honey", 
	25: "hive", 
	26: "honey_bomb", 
	27: "honey_dice", 
	28: "mimic", 
	29: "fire_mage", 
	30: "bookshelf", 
	31: "arcanist", 
	32: "piano", 
	33: "acoustic_guitar", 
	34: "electric_guitar", 
	35: "speakers", 
	36: "slime", 
	37: "skeleton", 
	38: "pirate_captain", 
	39: "pirate_cannoneer", 
	40: "cannon", 
	41: "undead_pirate", 
	42: "treasure_chest", 
	43: "cursed_chest"
}

enum BlockGroups{
	DEFAULT, 
	FORTRESS, 
	CASINO, 
	MINERALS, 
	COLONY, 
	EXPLOSIVES, 
	NUCLEAR, 
	ARCANE, 
	HARMONY, 
	MONSTER, 
	PIRATES,
	SPECIAL
}

enum BossTypes{
	NONE, 
	BLINDFOLDED, 
	REVERSED, # MIRROR
	FALL_UP, # DEFIANT
	DIZZY, # PUPEPT MASTER
	THIEF, 
	PERFECTIONIST, 
	ECLIPSE
}


var _is_block_on_group_cache: Dictionary = {}
var _texture_cache: Dictionary = {}

const GROUP_COLOR_MAP: Dictionary[GameData.BlockGroups, Dictionary] = {
	BlockGroups.NUCLEAR: {
		"font_color": Color("5ac54f"), 
		"font_shadow_color": Color("1e6f50"), 
		"background_color": Color("33984b")
	}, 
	BlockGroups.COLONY: {
		"font_color": Color("ffc825"), 
		"font_shadow_color": Color("ed7614"), 
		"background_color": Color("ffa214")
	}, 
	BlockGroups.CASINO: {
		"font_color": Color("00cdf9"), 
		"font_shadow_color": Color("0069aa"), 
		"background_color": Color("0098dc")
	}, 
	BlockGroups.FORTRESS: {
		"font_color": Color("92a1b9"), 
		"font_shadow_color": Color("424c6e"), 
		"background_color": Color("657392")
	}, 
	BlockGroups.MINERALS: {
		"font_color": Color("db3ffd"), 
		"font_shadow_color": Color("622461"), 
		"background_color": Color("93388f")
	}, 
	BlockGroups.EXPLOSIVES: {
		"font_color": Color("f68187"), 
		"font_shadow_color": Color("891e2b"), 
		"background_color": Color("ea323c")
	}, 
	BlockGroups.ARCANE: {
		"font_color": Color("0cf1ff"), 
		"font_shadow_color": Color("00396d"), 
		"background_color": Color("0069aa")
	}, 
	BlockGroups.HARMONY: {
		"font_color": Color("bf6f4a"), 
		"font_shadow_color": Color("8a4836"), 
		"background_color": Color("bf6f4a")
	}, 
	BlockGroups.MONSTER: {
		"font_color": Color("33984b"), 
		"font_shadow_color": Color("134c4c"), 
		"background_color": Color("1e6f50")
	}, 
	BlockGroups.PIRATES: {
		"font_color": Color("bf6f4a"), 
		"font_shadow_color": Color("8a4836"), 
		"background_color": Color("bf6f4a")
	},
	BlockGroups.SPECIAL: {
		"font_color": Color("f2cb05"), 
		"font_shadow_color": Color("b87b14"), 
		"background_color": Color("f2cb05")
	}
}


var blocks: Dictionary = {
	BLOCK_TYPES.NORMAL: BlockData.new([BlockGroups.DEFAULT], 3, 5), 
	BLOCK_TYPES.MOAI: BlockData.new([BlockGroups.DEFAULT], 3, 5), 
	BLOCK_TYPES.X: BlockData.new([BlockGroups.DEFAULT], 3, 5), 

	BLOCK_TYPES.GOLD: BlockData.new([BlockGroups.SPECIAL], 1, 2), 
	BLOCK_TYPES.BLUE_C: BlockData.new([BlockGroups.SPECIAL], 1, 2), 
	BLOCK_TYPES.RED_C: BlockData.new([BlockGroups.SPECIAL], 1, 2), 
	BLOCK_TYPES.SAND: BlockData.new([BlockGroups.SPECIAL], 1, 2), 
	BLOCK_TYPES.RAINBOW: BlockData.new([BlockGroups.SPECIAL], 1, 2), 

	BLOCK_TYPES.STONE: BlockData.new([BlockGroups.FORTRESS], 3, 5), 
	BLOCK_TYPES.BRICK: BlockData.new([BlockGroups.FORTRESS], 2, 3), 
	BLOCK_TYPES.GRANITE: BlockData.new([BlockGroups.FORTRESS], 1, 2), 
	BLOCK_TYPES.OBSIDIAN: BlockData.new([BlockGroups.FORTRESS], 2, 3, [BLOCK_TYPES.BRICK, BLOCK_TYPES.STONE, BLOCK_TYPES.GRANITE]), 


	BLOCK_TYPES.RED_DICE: BlockData.new([BlockGroups.CASINO], 3, 5), 
	BLOCK_TYPES.BLUE_DICE: BlockData.new([BlockGroups.CASINO], 3, 5), 
	BLOCK_TYPES.MIXED_DICE: BlockData.new([BlockGroups.CASINO], 3, 5), 
	BLOCK_TYPES.JACKPOT: BlockData.new([BlockGroups.CASINO], 1, 2, [BLOCK_TYPES.RED_DICE, BLOCK_TYPES.BLUE_DICE, BLOCK_TYPES.MIXED_DICE]), 


	BLOCK_TYPES.BRONZE: BlockData.new([BlockGroups.MINERALS], 2, 3), 
	BLOCK_TYPES.IRON: BlockData.new([BlockGroups.MINERALS], 3, 5), 
	BLOCK_TYPES.DIAMOND: BlockData.new([BlockGroups.MINERALS], 2, 3, [BLOCK_TYPES.IRON, BLOCK_TYPES.BRONZE]), 


	BLOCK_TYPES.TNT: BlockData.new([BlockGroups.EXPLOSIVES], 3, 5), 
	BLOCK_TYPES.BOMB: BlockData.new([BlockGroups.EXPLOSIVES], 2, 3), 
	BLOCK_TYPES.CFOUR: BlockData.new([BlockGroups.EXPLOSIVES], 2, 3), 
	BLOCK_TYPES.DETONATOR: BlockData.new([BlockGroups.EXPLOSIVES], 1, 1, [BLOCK_TYPES.TNT, BLOCK_TYPES.BOMB, BLOCK_TYPES.CFOUR]), 


	BLOCK_TYPES.RADIOACTIVE: BlockData.new([BlockGroups.NUCLEAR], 3, 5), 
	BLOCK_TYPES.URANIUM: BlockData.new([BlockGroups.NUCLEAR], 3, 5), 
	BLOCK_TYPES.NUKE: BlockData.new([BlockGroups.NUCLEAR, BlockGroups.EXPLOSIVES], 3, 5), 
	BLOCK_TYPES.REACTOR: BlockData.new([BlockGroups.NUCLEAR], 1, 2, [BLOCK_TYPES.URANIUM, BLOCK_TYPES.RADIOACTIVE]), 


	BLOCK_TYPES.QUEEN_BEE: BlockData.new([BlockGroups.COLONY], 2, 3), 
	BLOCK_TYPES.WORKER_BEE: BlockData.new([BlockGroups.COLONY], 2, 3), 
	BLOCK_TYPES.HONEY: BlockData.new([BlockGroups.COLONY], 2, 3, [BLOCK_TYPES.QUEEN_BEE, BLOCK_TYPES.WORKER_BEE]), 
	BLOCK_TYPES.HIVE: BlockData.new([BlockGroups.COLONY], 1, 2, [BLOCK_TYPES.QUEEN_BEE, BLOCK_TYPES.WORKER_BEE]), 

	BLOCK_TYPES.HONEY_BOMB: BlockData.new([BlockGroups.COLONY, BlockGroups.EXPLOSIVES], 2, 3), 
	BLOCK_TYPES.HONEY_DICE: BlockData.new([BlockGroups.COLONY, BlockGroups.CASINO], 2, 3), 


	BLOCK_TYPES.MIMIC: BlockData.new([BlockGroups.ARCANE, BlockGroups.MONSTER], 2, 3), 
	BLOCK_TYPES.FIRE_MAGE: BlockData.new([BlockGroups.ARCANE], 2, 3), 
	BLOCK_TYPES.BOOKSHELF: BlockData.new([BlockGroups.ARCANE], 2, 3), 
	BLOCK_TYPES.ARCANIST: BlockData.new([BlockGroups.ARCANE], 1, 2, [BLOCK_TYPES.MIMIC, BLOCK_TYPES.SLIME, BLOCK_TYPES.BOOKSHELF]), 


	BLOCK_TYPES.PIANO: BlockData.new([BlockGroups.HARMONY], 3, 5), 
	BLOCK_TYPES.ACOUSTIC_GUITAR: BlockData.new([BlockGroups.HARMONY], 3, 5), 
	BLOCK_TYPES.ELECTRIC_GUITAR: BlockData.new([BlockGroups.HARMONY], 3, 5), 
	BLOCK_TYPES.SPEAKERS: BlockData.new([BlockGroups.HARMONY], 1, 2, [BLOCK_TYPES.PIANO, BLOCK_TYPES.ACOUSTIC_GUITAR, BLOCK_TYPES.ELECTRIC_GUITAR]), 


	BLOCK_TYPES.SLIME: BlockData.new([BlockGroups.MONSTER], 2, 3), 
	BLOCK_TYPES.SKELETON: BlockData.new([BlockGroups.MONSTER], 3, 5), 


	BLOCK_TYPES.PIRATE_CAPTAIN: BlockData.new([BlockGroups.PIRATES], 2, 3), 
	BLOCK_TYPES.PIRATE_CANNONEER: BlockData.new([BlockGroups.PIRATES], 2, 3, [BLOCK_TYPES.PIRATE_CAPTAIN]), 
	BLOCK_TYPES.CANNON: BlockData.new([BlockGroups.PIRATES], 1, 2, [BLOCK_TYPES.PIRATE_CAPTAIN]), 
	BLOCK_TYPES.UNDEAD_PIRATE: BlockData.new([BlockGroups.PIRATES, BlockGroups.MONSTER], 2, 3), 

	BLOCK_TYPES.TREASURE_CHEST: BlockData.new([BlockGroups.PIRATES, BlockGroups.CASINO], 2, 3), 
	BLOCK_TYPES.CURSED_CHEST: BlockData.new([BlockGroups.PIRATES, BlockGroups.CASINO], 1, 2),
	
	"indestructible": BlockData.new([], 0, 0)
}


func get_perk_name(perk: Perks) -> String:
	return Perks.keys()[perk]


func get_all_block_types() -> Array[String]:
	var result: Array[String] = []
	for key in BLOCK_TYPES:
		result.append(BLOCK_TYPES[key])
	return result


func get_block_type_display_name(block_type: String) -> String:
	for key in BLOCK_TYPES:
		if BLOCK_TYPES[key] == block_type:
			return key
	return block_type


func is_valid_block_type(block_type: String) -> bool:
	return blocks.has(block_type)


func get_block_name(block_type: String) -> String:
	return get_block_type_display_name(block_type)


func get_block_group_name(block_group: BlockGroups) -> String:
	return BlockGroups.keys()[block_group]


func get_boss_name(boss_type: BossTypes) -> String:
	return BossTypes.keys()[boss_type]


func is_block_on_group(block_type: String, block_group: BlockGroups) -> bool:
	var key: String = block_type + ":" + str(block_group)

	if _is_block_on_group_cache.has(key):
		return _is_block_on_group_cache[key]

	var result: bool = blocks.has(block_type) and block_group in blocks[block_type].groups
	_is_block_on_group_cache[key] = result

	return result


func migrate_block_type_from_int(old_id: int) -> String:
	if LEGACY_BLOCK_TYPE_MAP.has(old_id):
		return LEGACY_BLOCK_TYPE_MAP[old_id]
	return BLOCK_TYPES.NORMAL


func get_block_texture(block_type: String) -> CompressedTexture2D:
	var cache_key: String = "block_" + block_type

	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var texture_path: String = get_block_texture_path(block_type)

	if block_type == BLOCK_TYPES.NORMAL:
		texture_path = "res://images/blocks/default/red.png"
	elif block_type == BLOCK_TYPES.MOAI:
		texture_path = "res://images/blocks/moai/orange.png"
	elif block_type == BLOCK_TYPES.X:
		texture_path = "res://images/blocks/the_x/blue.png"

	var texture: CompressedTexture2D = load(texture_path)

	_texture_cache[cache_key] = texture

	return texture


func get_block_texture_path(block_type: String) -> String:
	return "res://images/blocks/" + block_type + ".png"


func get_boss_texture(boss_type: BossTypes) -> CompressedTexture2D:
	var cache_key: String = "boss_" + str(boss_type)

	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var texture_path: String = "res://images/bosses/" + get_boss_name(boss_type).to_lower() + ".png"
	var texture: CompressedTexture2D = load(texture_path)

	_texture_cache[cache_key] = texture

	return texture


func get_perk_texture(perk: Perks) -> CompressedTexture2D:
	var cache_key: String = "perk_" + str(perk)

	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var texture_path: String = "res://images/perks/" + get_perk_name(perk).to_lower() + ".png"
	var texture: CompressedTexture2D = load(texture_path)

	_texture_cache[cache_key] = texture

	return texture
