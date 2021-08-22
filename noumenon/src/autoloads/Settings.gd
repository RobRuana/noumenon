extends Node

const SETTINGS_PATH: = "user://settings.cfg"
const DEFAULT_SETTINGS: = """
[audio_volume]
Master=100.0
Music=70.0
Effects=70.0
Interface=50.0
"""

signal setting_changed
signal settings_loaded

var default_settings: ConfigFile = ConfigFile.new()
var settings: ConfigFile = ConfigFile.new()
var is_loaded: bool = false

func _init():
	default_settings.parse(DEFAULT_SETTINGS)

	var file: = File.new()
	if file.file_exists(SETTINGS_PATH):
		settings.load(SETTINGS_PATH)
	else:
		settings.parse(DEFAULT_SETTINGS)
		settings.save(SETTINGS_PATH)

	is_loaded = true
	emit_signal("settings_loaded")
#	dump()

func once_loaded(target: Object, method: String):
	if is_loaded:
		target.call_deferred(method)
	else:
		connect("settings_loaded", target, method, [], CONNECT_ONESHOT)

func to_string(section: String = "") -> String:
	var lines = PoolStringArray()
	if section:
		lines.push_back("[%s]" % section)
		for key in get_section_keys(section):
			var value = get_value(section, key)
			lines.push_back("%s=%s" % [key, value])
		lines.push_back("")
	else:
		for section in get_sections():
			lines.push_back(to_string(section))
	return lines.join("\n")

func dump():
	print(to_string())

func dump_section(section: String):
	print(to_string(section))

func get_sections() -> PoolStringArray:
	return settings.get_sections()

func get_section_keys(section: String) -> PoolStringArray:
	if settings.has_section(section):
		return settings.get_section_keys(section)
	return PoolStringArray()

func get_value(section: String, key: String, default_value = null):
	if settings.has_section_key(section, key):
		return settings.get_value(section, key, default_value)
	return default_value

func set_value(section: String, key: String, value):
	var old_value = settings.get_value(section, key) if settings.has_section_key(section, key) else null
	settings.set_value(section, key, value)
	if value != old_value:
		emit_signal("setting_changed", section, key, value, old_value)

func reset_section(section: String):
	for key in default_settings.get_section_keys(section):
		var value = default_settings.get_value(section, key)
		set_value(section, key, value)

func save():
	settings.save(SETTINGS_PATH)
