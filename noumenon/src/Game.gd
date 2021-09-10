class_name Game
extends Node2D


const BACKGROUND_MUSIC: AudioStream = preload("res://assets/audio/background_music.mp3")
const WIN_SUCCESS_AUDIO: AudioStream = preload("res://assets/audio/win_success_01.wav")
const PAUSE_CONTROLLER: PackedScene = preload("res://src/ui/PauseController.tscn")

onready var player: Player = $PlayerContainer/Player

export var chapter_index: int = 0
export var level_index: int = 0

export var state: int = 0 setget set_state
var first_run: bool = true


func set_state(value: int):
	var old_value: int = state
	state = value
	if state != old_value:
		Events.emit_signal("game_state_changed", value, old_value)


func _ready():
	Global.game = self

	Events.connect("game_state_changed", self, "_on_game_state_changed")
	Events.connect("player_death", self, "_on_player_death")
	Events.connect("level_completed", self, "_on_level_completed")
	Events.connect("add_effects_node", self, "add_effects_node")

	Letters.once_initialized(self, "_on_letters_initialized")


func _on_letters_initialized():
	start()
	yield(GlobalOverlay.fade_to_transparent(1.0), "completed")


func add_effects_node(node: Node, autoremove: bool = false, autoremove_delay: float = 1.0, fade_duration: float = 0.0):
	add_child(node)
	if autoremove:
		if autoremove_delay > 0.0:
			yield(get_tree().create_timer(autoremove_delay), "timeout")
		if fade_duration > 0.0:
			yield($Fader.fade_to_transparent(node, fade_duration), "completed")
		Global.safe_queue_free_remove_child(self, node)


func start():
	yield(reset(), "completed")
	Settings.once_initialized(self, "do_start")


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
	$HUDLayer/HUD/LetterContainer.letters = letters

	if $AnimationPlayer.is_playing():
		yield($AnimationPlayer, "animation_finished")
	yield(GlobalOverlay.fade_to_black(0.0), "completed")


func get_letter_aggro_speed() -> float:
	"""
	level 0, speed == 100.0
	level 5, speed == 300.0
	Thereafter, speed asymptotically approaches player speed (450.0)
	"""
	var level: float = float((chapter_index * Letters.LEVEL_LETTERS.size()) + level_index)
	var letter_aggro_default: float = 300.0
	var speed_min: float = 100.0
	var speed_max: float = $PlayerContainer/Player.speed
	var V: float = (-5.0 * ((speed_max - speed_min) * (speed_max - letter_aggro_default))) / (speed_min - letter_aggro_default)
	var C: float = V / (speed_max - speed_min)
	var speed: = -(V / (level + C)) + speed_max
	return speed


func get_letters() -> String:
	var letters: String = Letters.LEVEL_LETTERS[level_index]
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


func _on_player_death(_player: Player):
	self.state = Const.GameState.DEATH
	level_index = 0
	yield(Global.time_scale(0.5, 1.0), "completed")
	AudioPlayer.fade_music()
	$AnimationPlayer.play("death")


func _on_level_completed(level):
	self.state = Const.GameState.WIN
	level_index += 1
	if level_index >= Letters.LEVEL_LETTERS.size():
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


func _unhandled_input(event: InputEvent):
	if not get_tree().paused and event.is_action_pressed("pause"):
		if state == Const.GameState.INTRO or state == Const.GameState.PLAYING:
			push_controller(PAUSE_CONTROLLER)


func push_controller(scene):
	get_tree().set_input_as_handled()
	get_tree().paused = true
	var controller: UIController = yield(SceneManager.push_controller(scene), "completed")
	controller.connect("pop_controller_completed", self, "_on_pop_controller_completed", [], CONNECT_ONESHOT)


func _on_pop_controller_completed(controller):
	if get_tree().paused:
		get_tree().paused = false
