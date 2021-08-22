class_name Fader
extends Node

signal fade_started
signal fade_all_completed

export var fade_duration: = 0.25

onready var tween: = $Tween
var is_active: bool = false

func _ready():
	tween.connect("tween_all_completed", self, "_on_tween_all_completed")

func fade_to_opaque(node: Node, duration: float = -1.0, delay: float = -1.0, light = null):
	tween.remove(node)
	if light:
		tween.remove(light)

	is_active = true
	var start_color: Color = node.modulate
	var finish_color: Color = start_color
	finish_color.a = 1.0
	if not node.visible:
		start_color.a = 0.0

	if is_zero_approx(duration):
		node.modulate = finish_color
		if light:
			light.energy = 1.0
		node.show()
		yield(get_tree().create_timer(0.0), "timeout")
		_on_tween_all_completed()
	else:
		node.modulate = start_color
		node.show()
		tween.interpolate_property(
			node,
			"modulate",
			start_color,
			finish_color,
			(duration if duration > 0.0 else fade_duration) * Engine.time_scale,
			Tween.TRANS_SINE,
			Tween.EASE_IN_OUT,
			(delay * Engine.time_scale if delay > 0.0 else 0.0)
		)

		if light:
			tween.interpolate_property(
				light,
				"energy",
				null,
				1.0,
				(duration if duration > 0.0 else fade_duration) * Engine.time_scale,
				Tween.TRANS_SINE,
				Tween.EASE_IN_OUT,
				(delay * Engine.time_scale if delay > 0.0 else 0.0)
			)

		tween.start()
		call_deferred("emit_signal", "fade_started")
		yield(tween, "tween_completed")

func fade_to_transparent(node: Node, duration: float = -1.0, delay: float = -1.0, light = null):
	tween.remove(node)
	if light:
		tween.remove(light)

	is_active = true
	var start_color: Color = node.modulate
	var finish_color: Color = Color(
		min(start_color.r, 1.0),
		min(start_color.g, 1.0),
		min(start_color.b, 1.0),
		0.0
	)

	var scaled_duration: = (duration if duration > 0.0 else fade_duration) # * Engine.time_scale
	var scaled_delay: = (delay if delay > 0.0 else 0.0) # * Engine.time_scale

	if is_zero_approx(duration):
		node.modulate = finish_color
		if light:
			light.energy = 0.0
		yield(get_tree().create_timer(0.0), "timeout")
		_on_tween_all_completed()
	else:

		node.modulate = start_color
		tween.interpolate_property(
			node,
			"modulate",
			start_color,
			finish_color,
			scaled_duration,
			Tween.TRANS_SINE,
			Tween.EASE_IN_OUT,
			scaled_delay
		)
		tween.interpolate_callback(node, scaled_delay + scaled_duration, "hide")

		if light:
			tween.interpolate_property(
				light,
				"energy",
				null,
				0.0,
				scaled_duration,
				Tween.TRANS_SINE,
				Tween.EASE_IN_OUT,
				scaled_delay
			)

		tween.start()
		call_deferred("emit_signal", "fade_started")

	yield(get_tree().create_timer(scaled_delay + scaled_duration), "timeout")

func _on_tween_all_completed():
	is_active = false
	emit_signal("fade_all_completed")
