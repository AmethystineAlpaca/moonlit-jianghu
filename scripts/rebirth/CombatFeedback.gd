extends Control
const FONT := preload("res://assets/fonts/StillwaterSans.tres")
var world: Node3D
var remaining := 0.0
var origin := Vector3.ZERO
var damage := 0.0
var veil: ColorRect
var veil_material: ShaderMaterial
var defense_remaining := 0.0
var defense_kind := ""
var defense_origin := Vector3.ZERO
var pulse_clock := 0.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil = ColorRect.new()
	veil.size = get_viewport_rect().size
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform float strength=0.0;
uniform float resolve=0.0;
void fragment(){vec2 p=UV*2.0-1.0;float edge=smoothstep(0.55,1.35,length(p));vec3 tint=mix(vec3(0.55,0.085,0.045),vec3(0.35,0.74,0.65),resolve);COLOR=vec4(tint,edge*strength*0.38);}
"""
	veil_material = ShaderMaterial.new()
	veil_material.shader = shader
	veil.material = veil_material
	add_child(veil)
func receive_hit(from: Vector3, amount: float) -> void:
	origin = from
	damage = amount
	remaining = 0.7
	queue_redraw()
func receive_defense(kind: String, from: Vector3) -> void:
	defense_kind = kind
	defense_origin = from
	defense_remaining = 0.65 if kind in ["parry","perfect_dodge"] else 0.35
	queue_redraw()
func _process(delta: float) -> void:
	if world.mode != "play": return
	pulse_clock += delta
	remaining = maxf(0,remaining-delta)
	defense_remaining = maxf(0,defense_remaining-delta)
	veil.size = get_viewport_rect().size
	var low_health := 0.0
	if is_instance_valid(world.player) and world.player.hp > 0 and world.player.hp <= world.player.max_hp*0.25:
		low_health = 0.11+0.05*sin(pulse_clock*3.5)
	var resolve := defense_remaining > 0.3 and defense_kind in ["parry","perfect_dodge"] and remaining <= 0
	veil_material.set_shader_parameter("resolve",1.0 if resolve else 0.0)
	veil_material.set_shader_parameter("strength",maxf(low_health,minf(1,remaining/0.35)) if not resolve else defense_remaining*0.5)
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(world.player): return
	var point: Vector2 = world.camera.unproject_position(world.player.position+Vector3.UP)
	if defense_remaining > 0: draw_defense(point)
	if remaining <= 0: return
	var source: Vector2 = world.camera.unproject_position(origin+Vector3.UP)
	var angle := (source-point).angle()
	var alpha := minf(1,remaining/0.25)
	var polygon := PackedVector2Array()
	for i in range(13): polygon.append(point+Vector2.from_angle(angle-0.5+i/12.0)*43)
	for i in range(12,-1,-1): polygon.append(point+Vector2.from_angle(angle-0.5+i/12.0)*38)
	draw_colored_polygon(polygon,Color(1,0.38,0.22,alpha))
	var damage_position := point+Vector2(25,-38-(0.7-remaining)*24)
	var text := "−%s" % snappedf(damage,0.1)
	draw_string_outline(FONT,damage_position,text,HORIZONTAL_ALIGNMENT_LEFT,-1,21,4,Color(0.12,0.04,0.02,alpha*0.75))
	draw_string(FONT,damage_position,text,HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color(1,0.83,0.67,alpha))

func draw_defense(point: Vector2) -> void:
	var rewarded := defense_kind in ["parry","perfect_dodge"]
	var color := Color("b9eedc") if defense_kind == "perfect_dodge" else Color("f3d69a")
	if defense_kind == "guard_break": color = Color("f39d77")
	if defense_kind == "block": color = Color("bdd2cd")
	color.a = minf(1,defense_remaining/0.18)
	var source: Vector2 = world.camera.unproject_position(defense_origin+Vector3.UP)
	var angle := (source-point).angle()
	var radius := 34.0+(1.0-defense_remaining/0.65)*12.0
	draw_arc(point,radius,angle-0.60,angle+0.60,16,color,2.5 if rewarded else 1.5,true)
	if rewarded:
		var label := "擦身" if defense_kind == "perfect_dodge" else "见切"
		var extent := FONT.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x
		var label_position := point+Vector2(-extent*0.5,-49-(0.65-defense_remaining)*18)
		draw_string_outline(FONT,label_position,label,HORIZONTAL_ALIGNMENT_LEFT,-1,17,4,Color(0.015,0.065,0.07,color.a*0.85))
		draw_string(FONT,label_position,label,HORIZONTAL_ALIGNMENT_LEFT,-1,17,color)
		var dash_origin := point+Vector2(0,-61-(0.65-defense_remaining)*18)
		draw_line(dash_origin+Vector2(-extent*0.5-16,5),dash_origin+Vector2(-extent*0.5-6,5),color,1.0,true)
		draw_line(dash_origin+Vector2(extent*0.5+6,5),dash_origin+Vector2(extent*0.5+16,5),color,1.0,true)
