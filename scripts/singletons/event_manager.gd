extends Node

## Emitted when event queue finishes processing
signal queue_finished()

## Emitted when event queue starts processing
signal queue_started()

# =============================================================================
# DELAY MULTIPLIER SETTINGS
# =============================================================================

## Default delay multiplier (1.0 = normal speed)
const DELAY_MULTIPLIER_DEFAULT: float = 1.0

## Minimum delay multiplier for long chains
const DELAY_MULTIPLIER_MINIMUM: float = 0.35

## How much to decrease multiplier per activation
const DELAY_MULTIPLIER_DECREMENT: float = 0.02

## How many events before delay starts decreasing
const DELAY_MULTIPLIER_ACTIVATION_THRESHOLD: int = 10

# =============================================================================
# STATE
# =============================================================================

var events: Array[Callable] = []
var delay_multiplier: float = DELAY_MULTIPLIER_DEFAULT
var delay_multiplier_activation: int = 0
var is_executing: bool = false
var should_check_lines_after_queue: bool = false

# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Add event to front of queue (processed first)
func add_event(event: Callable) -> void:
	events.push_front(event)


## Add event to end of queue (processed last)
func add_event_last(event: Callable) -> void:
	events.append(event)


## Request line check after current queue finishes
func request_line_check_after_queue() -> void:
	should_check_lines_after_queue = true


## Check if there are pending events or execution in progress
func has_pending_events() -> bool:
	return events.size() > 0 or is_executing


## Cancel all pending events
func cancel_events() -> void:
	events.clear()
	is_executing = false
	should_check_lines_after_queue = false
	_reset_delay_multiplier()


## Execute all queued events sequentially
func execute_events() -> void:
	if is_executing:
		return

	is_executing = true
	queue_started.emit()

	while events.size() > 0:
		var event: Callable = events.pop_front()

		# Acceleration for long chains
		delay_multiplier_activation += 1
		if delay_multiplier_activation >= DELAY_MULTIPLIER_ACTIVATION_THRESHOLD:
			delay_multiplier = max(
				DELAY_MULTIPLIER_MINIMUM,
				delay_multiplier - DELAY_MULTIPLIER_DECREMENT
			)

		# Execute event and get delay
		var delay: float = 0.0
		if event.is_valid():
			# Check if bound block argument is still valid
			var bound_args: Array = event.get_bound_arguments()
			if bound_args.size() > 0:
				var block = bound_args[0]
				if _is_block_destroyed(block):
					continue
			delay = event.call()

		# Wait before next event
		if delay > 0:
			await get_tree().create_timer(delay * delay_multiplier).timeout

	events.clear()
	is_executing = false

	# Check for cascading line clears
	if should_check_lines_after_queue:
		should_check_lines_after_queue = false
		var board = GameManager.get_board()
		if is_instance_valid(board):
			var lines_cleared: int = board.check_and_clear_lines(true, false)
			if lines_cleared == 0:
				_reset_delay_multiplier()
				queue_finished.emit()
				board.apply_gravity_changes()
			return

	_reset_delay_multiplier()
	queue_finished.emit()

	# Apply gravity after all events done
	var board = GameManager.get_board()
	if is_instance_valid(board):
		board.apply_gravity_changes()

# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _reset_delay_multiplier() -> void:
	delay_multiplier = DELAY_MULTIPLIER_DEFAULT
	delay_multiplier_activation = 0


func _is_block_destroyed(block: Variant) -> bool:
	if not is_instance_valid(block):
		return true
	if block.has_method("is_destroyed"):
		return block.is_destroyed()
	if "destroy_animation_requested" in block:
		return block.destroy_animation_requested
	return false
