class_name UIController
extends Control


var screens: = []
var is_transitioning: bool = false
var disabled: bool setget set_disabled


func set_disabled(value: bool):
	disabled = value
	Global.set_node_disabled(self, disabled)
	Global.set_node_disabled(screens[-1], disabled)


func _ready():
	var screen_nodes: = $Screens.get_children()
	screens.push_back(screen_nodes[0])
	for screen_node in screen_nodes:
		if screen_node == screens[0]:
			screen_node.reset_focus()
		else:
			screen_node.disabled = true
			screen_node.hide()
		screen_node.connect("push_screen", self, "_on_push_screen")
		screen_node.connect("pop_screen", self, "_on_pop_screen")
	connect_audio(screen_nodes[0])


func connect_audio(node: Node):
	for control in Global.get_focusable_controls(node):
		control.connect("focus_entered", self, "_on_child_focus_entered", [control])
		if control is Button or control is TextureButton:
			control.connect("button_up", self, "_on_child_button_up", [control])


func disconnect_audio(node: Node):
	for control in Global.get_focusable_controls(node):
		control.disconnect("focus_entered", self, "_on_child_focus_entered")
		if control is Button or control is TextureButton:
			control.disconnect("button_up", self, "_on_child_button_up")


func _on_child_focus_entered(control: Control):
	if !disabled and !is_transitioning and visible and modulate.a > 0.0:
		play_focus_audio()


func play_focus_audio():
	if !$FocusAudio.playing:
		$FocusAudio.play()


func _on_child_button_up(control: Control):
	if !disabled and !is_transitioning and visible and modulate.a > 0.0:
		play_button_audio()


func play_button_audio():
	if !$ButtonAudio.playing:
		$ButtonAudio.play()


func did_hide_controller():
	pass


func will_hide_controller():
	pass


func did_show_controller():
	screens[-1].did_push_screen()


func will_show_controller():
	screens[-1].will_push_screen()


func _on_push_screen(screen: Node):
	if not screen:
		return

	if is_transitioning:
		return
	is_transitioning = true

	screen.will_push_screen()

	connect_audio(screen)

	if screens:
		screens[-1].disabled = true
		disconnect_audio(screens[-1])
		yield($Fader.fade_to_transparent(screens[-1]), "completed")

	screens.push_back(screen)

	$Fader.fade_to_opaque(screen)
	yield($Fader, "fade_started")
	# Call deferred to prevent FocusBox from visibly snapping into place
	screen.call_deferred("reset_focus", false, false)
	if $Fader.is_active:
		yield($Fader, "fade_all_completed")
	screen.disabled = false
	screen.grab_focus()

	screen.did_push_screen()

	is_transitioning = false


func _on_pop_screen(screen: Node = null):
	if not screens:
		return

	play_button_audio()

	if is_transitioning:
		return
	is_transitioning = true

	if not screen:
		screen = screens[-1]

	disconnect_audio(screen)
	screen.disabled = true
	yield($Fader.fade_to_transparent(screen), "completed")

	while screens.size() > 1:
		var popped_screen = screens.pop_back()
		popped_screen.will_pop_screen()
		popped_screen.did_pop_screen()
		if screen == popped_screen:
			break

	connect_audio(screens[-1])
	yield($Fader.fade_to_opaque(screens[-1]), "completed")
	screens[-1].disabled = false
	screens[-1].grab_focus()

	is_transitioning = false


func grab_focus():
	screens[-1].grab_focus()


func release_focus():
	screens[-1].release_focus()


func reset_focus():
	screens[-1].reset_focus()
