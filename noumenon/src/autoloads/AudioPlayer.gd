extends Node2D

onready var tween: = $Tween
onready var music_players: = [$MusicPlayer0, $MusicPlayer1]
var music_player_index: = 0
var music_player_next_index: int setget, get_music_player_next_index
var music_player: AudioStreamPlayer setget, get_music_player
var music_player_next: AudioStreamPlayer setget, get_music_player_next
var spectrum: AudioEffectSpectrumAnalyzerInstance

const VU_COUNT: float = 200.0
const FREQ_MIN: float = 0.0
const FREQ_MAX: float = 1000.0

const MIN_DB: float = 60.0


func _ready():
	spectrum = AudioServer.get_bus_effect_instance(1, 0)
	$MusicPlayer0.volume_db = 0.0
	$MusicPlayer1.volume_db = -80.0
	Settings.once_loaded(self, "_on_settings_loaded")
	Settings.connect("setting_changed", self, "_on_setting_changed")


func get_music_player_next_index() -> int:
	return posmod(music_player_index + 1, music_players.size())


func get_music_player() -> AudioStreamPlayer:
	return music_players[self.music_player_index]


func get_music_player_next() -> AudioStreamPlayer:
	return music_players[self.music_player_next_index]


func play_autotune_effect(stream: AudioStream, volume_db: float = 0.0):
	var pitch_scale: float = 1.0
	if self.music_player.playing:
		var max_energy = 0
		var max_hz: float = -1.0
		var prev_hz: float = FREQ_MIN
		for i in range(1, VU_COUNT + 1):
			var hz: float = FREQ_MIN + (float(i) * (FREQ_MAX - FREQ_MIN) / VU_COUNT)
			var f = spectrum.get_magnitude_for_frequency_range(prev_hz, hz)
			var energy = clamp((MIN_DB + linear2db(f.length())) / MIN_DB, 0.0, 1.0)
			if energy > max_energy:
				max_energy = energy
				max_hz = hz
			prev_hz = hz
		var max_hz_db: = linear2db(max_hz)
		pitch_scale = clamp(max_hz_db / 42.5, 0.75, 1.25)  # magic
	play_effect(stream, volume_db, pitch_scale)


func play_effect(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0, delay: float = 0.0):
	if not stream:
		return

	var audio_player: = AudioStreamPlayer.new()
	audio_player.stream = stream
	audio_player.volume_db = volume_db
	audio_player.pitch_scale = pitch_scale
	audio_player.bus = "Effects"
	if delay > 0.0:
		yield(get_tree().create_timer(delay), "timeout")
	add_child(audio_player)
	audio_player.connect("finished", audio_player, "queue_free", [], CONNECT_ONESHOT)
	audio_player.play()


func play_music(stream: AudioStream, cross_fade: float = 1.0, fade_out: float = 2.0, fade_in: float = 0.0):
	if self.music_player.playing and self.music_player.stream == stream:
		# already playing requested stream
		return

	if self.music_player.playing and (cross_fade > 0.0 or fade_in > 0.0 or fade_out > 0.0):
		self.music_player_next.stop()
		self.music_player_next.volume_db = -80.0
		self.music_player_next.stream = stream

		var fade_out_delay: float = max(cross_fade - fade_out, 0.0)
		var fade_in_delay: float = max(fade_out - cross_fade, 0.0)

		tween.remove_all()
		tween.interpolate_property(
			self.music_player,
			"volume_db",
			null,
			-80.0,
			fade_out,
			Tween.TRANS_SINE,
			Tween.EASE_IN_OUT,
			fade_out_delay
		)
		tween.interpolate_callback(self.music_player, fade_out + fade_out_delay, "stop")

		tween.interpolate_property(
			self.music_player_next,
			"volume_db",
			null,
			0.0,
			fade_in,
			Tween.TRANS_SINE,
			Tween.EASE_IN_OUT,
			fade_in_delay
		)
		tween.interpolate_callback(self.music_player_next, fade_in_delay, "play")

		tween.start()
		self.music_player_index = self.music_player_next_index
	else:
		self.music_player.stream = stream
		self.music_player.volume_db = 0.0
		self.music_player.play()


func fade_music(fade_out: float = 2.0):
	if not self.music_player.playing:
		# already playing requested stream
		return

	if fade_out > 0.0:
		tween.remove_all()
		tween.interpolate_property(
			self.music_player,
			"volume_db",
			null,
			-80.0,
			fade_out,
			Tween.TRANS_SINE,
			Tween.EASE_IN_OUT
		)
		tween.interpolate_callback(self.music_player, fade_out, "stop")
		tween.start()
	else:
		self.music_player.stop()


func _on_settings_loaded():
	for key in Settings.get_section_keys("audio_volume"):
		_on_setting_changed("audio_volume", key, Settings.get_value("audio_volume", key))


func _on_setting_changed(section, key, value, old_value = null):
	if section == "audio_volume":
		var audio_bus_index: = AudioServer.get_bus_index(key)
		if audio_bus_index >= 0:
			var volume: = max(linear2db(value / 100.0), -80.0)
#			print(audio_bus_index, " volume: ", value, " (", volume, " db)")
			AudioServer.set_bus_volume_db(audio_bus_index, volume)
			# To do the reverse:
			# var volume: = AudioServer.get_bus_volume_db(audio_bus_index)
			# var value: = round(min(db2linear(volume) * 100.0, 100.0))
