class_name BackButton
extends Button

export var screen: NodePath


func _ready():
	connect("button_up", self, "_on_button_up")


func _input(event: InputEvent):
	if event.is_action_released("ui_cancel"):
		var screen_node: = get_screen_node()
		if screen_node and screen_node.visible:
			screen_node.emit_signal("pop_screen", screen_node)


func _on_button_up():
	var screen_node: = get_screen_node()
	screen_node.emit_signal("pop_screen", screen_node)


func get_screen_node() -> Node:
	if screen:
		return get_node(screen)
	var parent = get_parent()
	while parent and not parent is UIScreen:
		parent = parent.get_parent()
	return parent
