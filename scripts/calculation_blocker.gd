class_name CalculationBlocker extends Node


static var active_count: int = 0


func activate() -> void :
	CalculationBlocker.active_count += 1


func deactivate() -> void :
	CalculationBlocker.active_count = max(CalculationBlocker.active_count - 1, 0)

	if CalculationBlocker.active_count == 0:
		GameManager.calculation_blocker_finished.emit()
