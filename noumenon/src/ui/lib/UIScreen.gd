class_name UIScreen
extends Control


signal focus_entered_control(control)
signal focus_exited_control(control)
signal mouse_entered_control(control)
signal mouse_exited_control(control)
signal focusable_control_added(control)
signal focusable_control_removed(control)

var transition setget set_transition
var transitioning: bool = false
var focused_control: Control


func set_transition(value):
	if transition:
		remove_child(transition)
		transition.queue_free()

	transition = value
	if transition:
		if transition.get_parent():
			transition.get_parent().remove_child(transition)
		add_child(transition)


func grab_focus():
	if not focused_control:
		var controls = Global.get_focusable_controls(self)
		if controls:
			focused_control = controls[0]

	if focused_control:
		focused_control.grab_focus()


func release_focus():
	var control = get_focus_owner()
	if control and is_a_parent_of(control):
		control.release_focus()


func reset_focus(grab_focus: bool = true, animated: bool = false):
	release_focus()
	grab_focus()


func wrap_focus_neighbours(controls: Array):
	if controls.size() > 1:
		if not controls[0].focus_neighbour_top:
			controls[0].focus_neighbour_top = controls[-1].get_path()
		if not controls[0].focus_previous:
			controls[0].focus_previous = controls[-1].get_path()
		if not controls[-1].focus_neighbour_bottom:
			controls[-1].focus_neighbour_bottom = controls[0].get_path()
		if not controls[-1].focus_next:
			controls[-1].focus_next = controls[0].get_path()


func did_push_screen():
	pass


func will_push_screen():
	get_tree().connect("node_added", self, "_on_node_added")
	get_tree().connect("node_removed", self, "_on_node_removed")
	var controls = Global.get_focusable_controls(self)
	for control in controls:
		bind_control(control)
	wrap_focus_neighbours(controls)


func did_pop_screen():
	get_tree().disconnect("node_added", self, "_on_node_added")
	get_tree().disconnect("node_removed", self, "_on_node_removed")
	var controls = Global.get_focusable_controls(self)
	for control in controls:
		unbind_control(control)


func will_pop_screen():
	pass


func _on_node_added(node: Node):
	if Global.is_focusable(node) and is_a_parent_of(node):
		bind_control(node)


func _on_node_removed(node: Node):
	if Global.is_focusable(node) and is_a_parent_of(node):
		unbind_control(node)


func bind_control(control: Control):
	emit_signal("focusable_control_added", control)
	for signal_name in ["focus_entered", "focus_exited", "mouse_entered", "mouse_exited"]:
		var method_name: String = "_on_%s" % signal_name
		if not control.is_connected(signal_name, self, method_name):
			control.connect(signal_name, self, method_name, [control])


func unbind_control(control: Control):
	emit_signal("focusable_control_removed", control)
	for signal_name in ["focus_entered", "focus_exited", "mouse_entered", "mouse_exited"]:
		var method_name: String = "_on_%s" % signal_name
		if control.is_connected(signal_name, self, method_name):
			control.disconnect(signal_name, self, method_name)


func _on_focus_entered(control: Control):
	focused_control = control
	emit_signal("focus_entered_control", control)


func _on_focus_exited(control: Control):
	emit_signal("focus_exited_control", control)


func _on_mouse_entered(control: Control):
	emit_signal("mouse_entered_control", control)


func _on_mouse_exited(control: Control):
	emit_signal("mouse_exited_control", control)
