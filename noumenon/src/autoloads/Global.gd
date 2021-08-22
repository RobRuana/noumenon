extends Node


var game
var player

var layers: = {}
var layer_names: = {}


func _init():
	pause_mode = PAUSE_MODE_PROCESS


func _ready():
	for i in range(20):
		var layer = ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(i + 1))
		if layer:
			var layer_bitmask: int = int(pow(2, i))
			layers[layer] = layer_bitmask
			layer_names[layer_bitmask] = layer


func get_focusable_controls(parent_node: Node) -> Array:
	var nodes: Array = []
	if parent_node is Control and parent_node.focus_mode != Control.FOCUS_NONE:
		nodes.append(parent_node)
	for node in parent_node.get_children():
		nodes.append_array(get_focusable_controls(node))
	return nodes


func get_screen_center(node: Node) -> Vector2:
	var transform: Transform2D = node.get_viewport_transform()
	var scale: Vector2 = transform.get_scale()
	return -(transform.origin / scale) + ((node.get_viewport_rect().size / scale) * 0.5)


func set_node_disabled(node: Node, disabled: bool):
	if disabled:
		node.set_process(false)
		node.set_process_input(false)
		node.set_process_unhandled_input(false)
		node.set_process_unhandled_key_input(false)
		node.set_physics_process(false)
	else:
		if node.has_method("_process"):
			node.set_process(true)
		if node.has_method("_input"):
			node.set_process_input(true)
		if node.has_method("_unhandled_input"):
			node.set_process_unhandled_input(true)
		if node.has_method("_unhandled_key_input"):
			node.set_process_unhandled_key_input(true)
		if node.has_method("_physics_process"):
			node.set_physics_process(true)


func time_scale(scale: float = 1.0, duration: float = 1.0, delay: float = 0.0):
	if delay > 0.0:
		yield(get_tree().create_timer(Engine.time_scale * delay), "timeout")
	Engine.time_scale *= scale

	yield(get_tree().create_timer(Engine.time_scale * duration), "timeout")

	var reverted_scale: float = Engine.time_scale / scale
	if is_equal_approx(reverted_scale, 1.0):
		Engine.time_scale = 1.0
	else:
		Engine.time_scale = reverted_scale
