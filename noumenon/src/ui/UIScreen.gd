class_name UIScreen
extends Control

signal pop_screen
signal push_screen

var disabled: bool setget set_disabled

func set_disabled(value: bool):
	disabled = value
	release_focus()
	Global.set_node_disabled(self, disabled)

func grab_focus():
	var controls = Global.get_focusable_controls(self)
	if controls:
		controls[0].grab_focus()

func release_focus():
	var control = get_focus_owner()
	if control and is_a_parent_of(control):
		control.release_focus()

func reset_focus(grab_focus: bool = true, animated: bool = false):
	release_focus()
	grab_focus()

func did_push_screen():
	pass

func will_push_screen():
	pass

func did_pop_screen():
	pass

func will_pop_screen():
	pass
