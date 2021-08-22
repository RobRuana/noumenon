class_name Game
extends Node2D


const BACKGROUND_MUSIC: AudioStream = preload("res://assets/audio/background_music.mp3")
const WIN_SUCCESS_AUDIO: AudioStream = preload("res://assets/audio/win_success_01.wav")

onready var player: Player = $PlayerContainer/Player

export var chapter_index: int = 0
export var level_index: int = 0
export var LEVEL_LETTERS: PoolStringArray = [
	"Growth",
	"Godot",
	"Wild",
	"Game Jam",
	"Uncontrollable",
	"Noumenon",
	"WIN!WIN!WIN!",
]

export var state: int = 0 setget set_state
var first_run: bool = true


func set_state(value: int):
	var old_value: int = state
	state = value
	if state != old_value:
		Events.emit_signal("game_state_changed", value, old_value)


func _ready():
	if OS.is_debug_build():
		seed(12345)
	else:
		randomize()

	Global.game = self

	$ScreenLayer/PauseController.disabled = true
	$ScreenLayer/PauseController.connect("continue_game", self, "_on_pause_continue_game")
	$ScreenLayer/PauseController.connect("quit_game", self, "_on_quit_button_up")

	$ScreenLayer/StartController.disabled = true
	$ScreenLayer/StartController.connect("continue_game", self, "_on_start_game")
	$ScreenLayer/StartController.connect("quit_game", self, "_on_quit_button_up")

	Events.connect("game_state_changed", self, "_on_game_state_changed")
	Events.connect("player_health_changed", self, "_on_player_health_changed")
	Events.connect("player_zoom_changed", self, "_on_player_zoom_changed")
	Events.connect("player_zoom_recovery", self, "_on_player_zoom_recovery")
	Events.connect("player_death", self, "_on_player_death")
	Events.connect("letter_inside_goal", self, "_on_letter_inside_goal")
	Events.connect("level_completed", self, "_on_level_completed")
	Events.connect("add_effects_node", self, "add_effects_node")

	show_controller($ScreenLayer/StartController)
	yield(GlobalOverlay.fade_to_transparent(1.0), "completed")


func add_effects_node(node: Node, autoremove: bool = false, autoremove_delay: float = 1.0, fade_duration: float = 0.0):
	add_child(node)
	if autoremove:
		if autoremove_delay > 0.0:
			yield(get_tree().create_timer(autoremove_delay), "timeout")
		if fade_duration > 0.0:
			yield($Fader.fade_to_transparent(node, fade_duration), "completed")
		Global.safe_queue_free_remove_child(self, node)


func _on_start_game():
	hide_controller($ScreenLayer/StartController)
	start()


func start():
	yield(reset(), "completed")
	Settings.once_loaded(self, "do_start")


func do_start():
	AudioPlayer.play_music(BACKGROUND_MUSIC)
	yield(GlobalOverlay.fade_to_transparent(1.0), "completed")
	intro()


func intro():
	$LevelContainer/Level.intro()
	yield($LevelContainer/Level, "intro_completed")
	$AnimationPlayer.play("intro")

	player.torso.set_deferred("disabled", false)
	player.tail.set_deferred("disabled", false)
	player.zoom_trail.set_deferred("disabled", false)

	if $AnimationPlayer.is_playing():
		yield($AnimationPlayer, "animation_finished")
	first_run = false


func reset():
	$IntroContainer/IntroPath/IntroPathFollow.unit_offset = 0.0
	player.teleport($IntroContainer/IntroPath/IntroPathFollow.global_position)
	player.reset()
	$LevelContainer/Level.reset()
	$AnimationPlayer.play("reset")
	$AnimationPlayer.advance(0)

	var letters: String = get_letters()
	$LevelContainer/Level.goal.position = get_goal_position()
	$LevelContainer/Level/LetterContainer.letter_aggro_speed = get_letter_aggro_speed()
	$LevelContainer/Level/LetterContainer.letters = letters
	$ScreenLayer/DeathScreen/LetterContainer.letters = letters
	$UILayer/UI/LetterContainer.letters = letters

	if $AnimationPlayer.is_playing():
		yield($AnimationPlayer, "animation_finished")
	yield(GlobalOverlay.fade_to_black(0.0), "completed")


func get_letter_aggro_speed() -> float:
	"""
	level 0, speed == 100.0
	level 5, speed == 300.0
	Thereafter, speed asymptotically approaches player speed (450.0)
	"""
	var level: float = float((chapter_index * LEVEL_LETTERS.size()) + level_index)
	var letter_aggro_default: float = 300.0
	var speed_min: float = 100.0
	var speed_max: float = $PlayerContainer/Player.speed
	var V: float = (-5.0 * ((speed_max - speed_min) * (speed_max - letter_aggro_default))) / (speed_min - letter_aggro_default)
	var C: float = V / (speed_max - speed_min)
	var speed: = -(V / (level + C)) + speed_max
	return speed


func get_letters() -> String:
	var letters: String = LEVEL_LETTERS[level_index]
	if chapter_index > 0:
		letters += "+".repeat(chapter_index)
	return letters


func get_goal_position() -> Vector2:
	if level_index == 0:
		return Vector2(1600.0, 496.0)
	var top: float = 300.0
	var center: float = 450.0
	var goal_position: = Vector2(rand_range(0.0, 1920.0), rand_range(0.0, 1080.0 - top - center))
	if goal_position.y > top:
		goal_position.y += center
	return goal_position


func _on_game_state_changed(value: int, old_value: int):
	$IntroCamera.current = value == Const.GameState.INTRO
	$PlayerContainer/Player/PlayerCamera.current = value != Const.GameState.INTRO


func _on_player_health_changed(_player: Player, value: int, old_value: int):
	$UILayer/UI/HealthMeter.health = value


func _on_player_zoom_changed(_player: Player, value: float, old_value: float):
	$UILayer/UI/ZoomMargin/ZoomPanel/ZoomMeter.value = value
	if is_equal_approx(value, 100.0) and not Input.is_action_pressed("zoom"):
		$Fader.fade_to_transparent($UILayer/UI/ZoomMargin, 0.25)
	elif is_equal_approx(old_value, 100.0):
		$Fader.fade_to_opaque($UILayer/UI/ZoomMargin, 0.25)


func _on_player_zoom_recovery(_player: Player, value: bool):
	if value:
		$UILayer/UI/ZoomMargin/ZoomPanel/ZoomMeter.modulate = Color(0.8, 0.2, 0.2, 1.0)
	else:
		$Tween.remove($UILayer/UI/ZoomMargin/ZoomPanel/ZoomMeter)
		$Tween.interpolate_property($UILayer/UI/ZoomMargin/ZoomPanel/ZoomMeter, "modulate", null, Color.black, 0.25, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		$Tween.start()


func _on_letter_inside_goal(letter: LetterSprite):
	var child = $UILayer/UI/LetterContainer.get_letter(letter.character_index)
	child.modulate = Color(0.0, 0.8, 0.0, 1.0)


func _on_player_death(_player: Player):
	self.state = Const.GameState.DEATH
	level_index = 0
	yield(Global.time_scale(0.5, 1.0), "completed")
	AudioPlayer.fade_music()
	$AnimationPlayer.play("death")


func _on_level_completed(level):
	self.state = Const.GameState.WIN
	level_index += 1
	if level_index >= LEVEL_LETTERS.size():
		level_index = 0
		chapter_index += 1
	$AnimationPlayer.play("win")


func _on_quit_button_up():
	get_tree().quit()


func _on_retry_button_up():
	$ScreenLayer/DeathScreen/Buttons/RetryButton.disabled = true
	yield(GlobalOverlay.fade_to_black(0.2), "completed")
	start()


func _on_next_level_button_up():
	AudioPlayer.play_effect(WIN_SUCCESS_AUDIO)
	$ScreenLayer/WinScreen/Buttons/NextLevelButton.disabled = true
	yield(GlobalOverlay.fade_to_black(0.2), "completed")
	start()


func _on_pause_continue_game():
	hide_controller($ScreenLayer/PauseController)


func _unhandled_input(event: InputEvent):
	if not get_tree().paused and event.is_action_pressed("pause"):
		if state == Const.GameState.INTRO or state == Const.GameState.PLAYING:
			show_controller($ScreenLayer/PauseController)


func show_controller(controller):
	get_tree().set_input_as_handled()
	get_tree().paused = true
	controller.will_show_controller()
	controller.reset_focus()
	yield($Fader.fade_to_opaque(controller), "completed")
	controller.disabled = false
	controller.did_show_controller()


func hide_controller(controller):
	if get_tree().paused:
		controller.disabled = true
		controller.will_hide_controller()
		yield($Fader.fade_to_transparent(controller), "completed")
		get_tree().paused = false
		controller.did_hide_controller()
