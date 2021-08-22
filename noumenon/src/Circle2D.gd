class_name Circle2D
extends Node2D


export var color: Color = Color.white
export var radius: float = 32.0
export var filled: bool = true
export var border_width: float = 2.0


func _draw():
	if filled:
		draw_circle(Vector2.ZERO, radius, color)
	else:
		draw_arc(Vector2.ZERO, radius, 0.0, Math.TWO_PI, 20, color, border_width, true)
