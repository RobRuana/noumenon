extends UIScreen

signal continue_game

export var controls_screen: NodePath
export var audio_screen: NodePath
export var credits_screen: NodePath
export var confirm_quit_screen: NodePath

func _input(event):
	if event.is_action_released("ui_cancel"):
		$Margin/VBox/ContinueButton.emit_signal("button_up")

func _on_controls_button_up():
	emit_signal("push_screen", get_node(controls_screen))

func _on_audio_button_up():
	emit_signal("push_screen", get_node(audio_screen))

func _on_credits_button_up():
	emit_signal("push_screen", get_node(credits_screen))

func _on_continue_button_up():
	emit_signal("continue_game")

func _on_quit_button_up():
	emit_signal("push_screen", get_node(confirm_quit_screen))
