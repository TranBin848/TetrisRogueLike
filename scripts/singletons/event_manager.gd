extends Node


const DELAY_MULTIPLIER_DEFAULT: float = 1.0
const DELAY_MULTIPLIER_MINIMUM: float = 0.35
const DELAY_MULTIPLIER_DECREMENT: float = 0.02
const DELAY_MULTIPLIER_ACTIVATION: int = 10

signal queue_finished()
signal queue_started()


var events: Array[Callable] = []
var delay_multiplier_activation: int = 0
var delay_multiplier: float = DELAY_MULTIPLIER_DEFAULT
var is_executing: bool = false
var should_check_lines_after_queue: bool = false


func add_event(event: Callable) -> void :
	events.push_front(event)


func add_projectile_event(event: Callable) -> void :
	events.push_front(event)


	if not is_executing:
		execute_events()


func add_event_last(event: Callable) -> void :
	events.append(event)


func request_line_check_after_queue() -> void :
	should_check_lines_after_queue = true


func has_pending_events() -> bool:
	return events.size() > 0 or is_executing


func cancel_events() -> void :
	events.clear()
	is_executing = false
	should_check_lines_after_queue = false
	_reset_delay_multiplier()


func execute_events() -> void :
	if is_executing:
		push_warning("execute_events() called while already executing!")
		return

	is_executing = true
	queue_started.emit()


	while events.size() > 0:
		var event: Callable = events.pop_front()

		delay_multiplier_activation += 1

		if delay_multiplier_activation >= DELAY_MULTIPLIER_ACTIVATION:
			delay_multiplier = max(DELAY_MULTIPLIER_MINIMUM, delay_multiplier - DELAY_MULTIPLIER_DECREMENT)

		var delay: float = 0.0

		if event.is_valid():
			var bound_args: Array = event.get_bound_arguments()

			if bound_args.size() > 0:
				var block_instance = bound_args[0]

				if _is_block_destroyed(block_instance):
					continue

			delay = event.call()

		await get_tree().create_timer((delay * delay_multiplier) / GameManager.timescale).timeout

	events.clear()

	is_executing = false


	var board: Board = GameManager.get_board()

	if should_check_lines_after_queue:
		should_check_lines_after_queue = false
		if is_instance_valid(board):
			var lines_cleared: int = board.check_and_clear_lines(true, false)

			if lines_cleared == 0:
				_reset_delay_multiplier()
				queue_finished.emit()

				board.apply_gravity_changes()

			return

	_reset_delay_multiplier()
	queue_finished.emit()

	if is_instance_valid(board):
		board.apply_gravity_changes()

func _reset_delay_multiplier() -> void :
	delay_multiplier = DELAY_MULTIPLIER_DEFAULT
	delay_multiplier_activation = 0


func execute_queue_events(queue: Array[Callable]) -> void :
	var local_delay_multiplier: float = DELAY_MULTIPLIER_DEFAULT
	var local_delay_multiplier_activation: int = 0

	while queue.size() > 0:
		var event: Callable = queue.pop_front()

		local_delay_multiplier_activation += 1

		if local_delay_multiplier_activation >= DELAY_MULTIPLIER_ACTIVATION:
			local_delay_multiplier = max(DELAY_MULTIPLIER_MINIMUM, local_delay_multiplier - DELAY_MULTIPLIER_DECREMENT)

		var delay: float = 0.0

		if event.is_valid():
			var bound_args: Array = event.get_bound_arguments()

			if bound_args.size() > 0:
				var block_instance = bound_args[0]

				if _is_block_destroyed(block_instance):
					continue

			delay = event.call()

		await get_tree().create_timer((delay * local_delay_multiplier) / GameManager.timescale).timeout


func _is_block_destroyed(block: Variant) -> bool:
	if not is_instance_valid(block):
		return true

	if block.destroy_animation_requested:
		return true

	return false
