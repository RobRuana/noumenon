class_name AudioButton
extends Button


func _ready():
	connect("button_up", self, "_on_audio_button_up")


func _on_audio_button_up():
	$Audio.play()
