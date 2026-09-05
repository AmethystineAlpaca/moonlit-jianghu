extends Node
var music: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		return
	get_tree().auto_accept_quit = false
	music = AudioStreamPlayer.new()
	var stream := load("res://assets/audio/qinglan_night.wav") as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = 22050 * 24
	music.stream = stream
	music.volume_db = -17.0
	add_child(music)
	music.tree_exiting.connect(_stop_music)
	var settings := ConfigFile.new()
	settings.load("user://settings.cfg")
	AudioServer.set_bus_mute(0, not bool(settings.get_value("audio", "sound", true)))
	music.play()

func _stop_music() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		shutdown()

func shutdown() -> void:
	_stop_music()
	# Let the audio server release the playback on its next mix before teardown.
	await get_tree().process_frame
	await get_tree().create_timer(0.08, true).timeout
	get_tree().quit()
