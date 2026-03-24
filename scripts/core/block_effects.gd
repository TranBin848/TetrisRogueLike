class_name BlockEffects extends RefCounted

## Default delay between chain reaction events (seconds)
const DEFAULT_DELAY: float = 0.09

# =============================================================================
# LINE CLEAR - COMMON DESTROY
# =============================================================================

## Called for each block when a line is cleared
## Blocks are destroyed right-to-left with sequential delay
static func common_destroy(block: PlacedBlock, cleared_lines_count: int = 1) -> float:
	if not is_instance_valid(block) or block.destroy_animation_requested:
		return 0.0

	block.destroy()

	# Bonus for rightmost column (like Balatro)
	if block.grid_position.x == 9:
		GameManager.add_multiplier(4)

	return DEFAULT_DELAY
