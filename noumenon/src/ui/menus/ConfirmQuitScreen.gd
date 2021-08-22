extends UIScreen

signal quit_game

func _on_quit_button_up():
	emit_signal("quit_game")
