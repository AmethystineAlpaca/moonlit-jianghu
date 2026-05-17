extends Control

const EDGE_MARGIN: float = 24.0
const ARROW_LENGTH: float = 14.0
const ARROW_WIDTH: float = 10.0
const OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 0.6)

const TRACKED := [
	{"group": "hostile_enemies", "color": Color(0.95, 0.18, 0.18)},
	{"group": "zombies",         "color": Color(0.25, 0.85, 0.32)},
	{"group": "chests",          "color": Color(0.98, 0.84, 0.18)},
]

var _camera: Camera2D = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	queue_redraw()

func _get_camera() -> Camera2D:
	if _camera != null and is_instance_valid(_camera) and _camera.is_inside_tree():
		return _camera
	_camera = get_viewport().get_camera_2d()
	return _camera

func _draw() -> void:
	var camera := _get_camera()
	if camera == null:
		return
	var viewport_size := get_viewport_rect().size
	var half := viewport_size * 0.5
	var inset := half - Vector2(EDGE_MARGIN, EDGE_MARGIN)
	if inset.x <= 0.0 or inset.y <= 0.0:
		return
	var cam_center := camera.get_screen_center_position()
	var zoom := camera.zoom

	for entry in TRACKED:
		var color: Color = entry["color"]
		var nodes := get_tree().get_nodes_in_group(entry["group"])
		for node in nodes:
			if not is_instance_valid(node) or not node.is_inside_tree():
				continue
			if not (node is Node2D):
				continue
			if "visible" in node and not node.visible:
				continue
			if "is_dead" in node and node.get("is_dead") == true:
				continue
			var entity_pos: Vector2 = (node as Node2D).global_position
			var screen_delta := (entity_pos - cam_center) * zoom
			if absf(screen_delta.x) <= inset.x and absf(screen_delta.y) <= inset.y:
				continue
			var ax := absf(screen_delta.x)
			var ay := absf(screen_delta.y)
			if ax <= 0.0001 and ay <= 0.0001:
				continue
			var tx := INF if ax <= 0.0001 else inset.x / ax
			var ty := INF if ay <= 0.0001 else inset.y / ay
			var t: float = min(tx, ty)
			var edge_pos := half + screen_delta * t
			var angle := screen_delta.angle()
			_draw_arrow(edge_pos, angle, color)

func _draw_arrow(pos: Vector2, angle: float, color: Color) -> void:
	var tip := Vector2(ARROW_LENGTH * 0.6, 0.0)
	var back_left := Vector2(-ARROW_LENGTH * 0.4, -ARROW_WIDTH * 0.5)
	var back_right := Vector2(-ARROW_LENGTH * 0.4, ARROW_WIDTH * 0.5)
	var p0 := pos + tip.rotated(angle)
	var p1 := pos + back_left.rotated(angle)
	var p2 := pos + back_right.rotated(angle)
	var pts := PackedVector2Array([p0, p1, p2])
	draw_colored_polygon(pts, color)
	var outline := PackedVector2Array([p0, p1, p2, p0])
	draw_polyline(outline, OUTLINE_COLOR, 1.0, true)
