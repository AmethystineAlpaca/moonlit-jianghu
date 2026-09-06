extends Node
var music: AudioStreamPlayer
var stopping := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		return
	get_tree().auto_accept_quit = false
	# No continuous music bed: the courtyard leaves space for combat Foley.
	var settings := ConfigFile.new()
	settings.load("user://settings.cfg")
	AudioServer.set_bus_mute(0, not bool(settings.get_value("audio", "sound", true)))


func _stop_music() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		shutdown()

func shutdown() -> void:
	if stopping: return
	stopping = true
	var scene := get_tree().current_scene
	if is_instance_valid(scene) and scene.has_method("prepare_shutdown"): scene.prepare_shutdown()
	get_tree().paused = true
	_stop_audio_tree(get_tree().root)
	# Let the audio server release the playback on its next mix before teardown.
	await get_tree().process_frame
	await get_tree().create_timer(0.08, true).timeout
	get_tree().quit()

func _stop_audio_tree(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D or node is AudioStreamPlayer2D:
		node.stop()
		node.stream = null
	for child in node.get_children(): _stop_audio_tree(child)
