extends Control
const FONT := preload("res://assets/fonts/NotoSansSC.ttf")
var world: Node3D
var remaining := 0.0
var origin := Vector3.ZERO
var damage := 0.0
var veil: ColorRect
var veil_material: ShaderMaterial
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil = ColorRect.new()
	veil.size = Vector2(1280,720)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform float strength=0.0;
void fragment(){vec2 p=UV*2.0-1.0;float edge=smoothstep(0.45,1.25,length(p));COLOR=vec4(0.55,0.085,0.045,edge*strength*0.38);}
"""
	veil_material = ShaderMaterial.new()
	veil_material.shader = shader
	veil.material = veil_material
	add_child(veil)
func receive_hit(from: Vector3, amount: float) -> void:
	origin = from
	damage = amount
	remaining = 0.7
func _process(delta: float) -> void:
	if world.mode != "play": return
	remaining = maxf(0,remaining-delta)
	veil_material.set_shader_parameter("strength",minf(1,remaining/0.35))
	queue_redraw()
func _draw() -> void:
	if remaining <= 0 or not is_instance_valid(world.player): return
	var point: Vector2 = world.camera.unproject_position(world.player.position+Vector3.UP)
	var source: Vector2 = world.camera.unproject_position(origin+Vector3.UP)
	var angle := (source-point).angle()
	var alpha := minf(1,remaining/0.25)
	var polygon := PackedVector2Array()
	for i in range(13): polygon.append(point+Vector2.from_angle(angle-0.5+i/12.0)*43)
	for i in range(12,-1,-1): polygon.append(point+Vector2.from_angle(angle-0.5+i/12.0)*38)
	draw_colored_polygon(polygon,Color(1,0.38,0.22,alpha))
	draw_string(FONT,point+Vector2(25,-38-(0.7-remaining)*24),"−%s" % snappedf(damage,0.1),HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color(1,0.78,0.62,alpha))
