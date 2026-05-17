extends SceneTree

var failures := 0

func _initialize() -> void:
	_test_gameplay_viewport_uses_fixed_canvas()
	quit(failures)

func _test_gameplay_viewport_uses_fixed_canvas() -> void:
	_assert_equal(ProjectSettings.get_setting("display/window/size/viewport_width"), 1280, "viewport width is fixed")
	_assert_equal(ProjectSettings.get_setting("display/window/size/viewport_height"), 720, "viewport height is fixed")
	_assert_equal(ProjectSettings.get_setting("display/window/stretch/mode"), "viewport", "window scales the gameplay viewport")
	_assert_equal(ProjectSettings.get_setting("display/window/stretch/aspect"), "keep", "window keeps gameplay aspect ratio")

func _assert_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	failures += 1
	push_error("%s: expected %s, got %s" % [message, expected, actual])
