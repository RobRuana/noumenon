extends Node

const move_threshold_low: float = 0.15
const move_threshold_low_squared: float = move_threshold_low * move_threshold_low
const move_threshold_high: float = 0.65
const move_threshold_high_squared: float = move_threshold_high * move_threshold_high
const move_threshold_range: float = move_threshold_high - move_threshold_low
const move_threshold_range_inverse: float = 1.0 / move_threshold_range


# =============================================================
# Move Functions
# =============================================================

func get_move() -> Vector2:
	var direction: = get_move_raw()
	var length_squared: = direction.length_squared()
	if length_squared < move_threshold_low_squared:
		return Vector2.ZERO
	elif length_squared >= move_threshold_high_squared:
		return direction.normalized()
	return direction.normalized() * (sqrt(length_squared) - move_threshold_low) * move_threshold_range_inverse


func get_move_raw() -> Vector2:
	return Vector2(get_move_x_raw(), get_move_y_raw())


func has_move() -> bool:
	return get_move_raw().length_squared() >= move_threshold_low_squared


func get_move_x() -> float:
	return get_move().x


func get_move_x_raw() -> float:
	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")


func has_move_x() -> bool:
	var direction: Vector2 = get_move_raw()
	return direction.x != 0.0 and direction.length_squared() >= move_threshold_low_squared


func get_move_y() -> float:
	return get_move().y


func get_move_y_raw() -> float:
	return Input.get_action_strength("move_down") - Input.get_action_strength("move_up")


func has_move_y() -> bool:
	var direction: Vector2 = get_move_raw()
	return direction.x != 0.0 and direction.length_squared() >= move_threshold_low_squared
