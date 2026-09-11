extends RefCounted
## The run's rhythm, mastery and build state. Updated only by the active world.
var world: Node3D
var flow := 0.0
var chain := 0
var best_chain := 0
var score := 0
var surge_left := 0.0
var cinematic_left := 0.0
var cinematic_focus := Vector3.ZERO
var quiet_time := 0.0
var chain_time := 0.0
var event_caption := ""
var event_time := 0.0
var event_color := Color("a4dacc")
var stats := {"hits":0,"parries":0,"perfect_dodges":0,"executions":0,"recalls":0,"crashes":0,"surges":0,"damage_taken":0.0,"retries":0}
var bonuses := {"blade":0,"resolve":0,"echo":0,"wine":0,"breath":0,"mercy":0}
var hints_seen := {}
var surge_active: bool:
	get: return surge_left > 0
var technique_ready: bool:
	get: return flow >= 100.0 and not surge_active

func update(delta: float) -> void:
	if world.mode != "play": return
	cinematic_left = maxf(0,cinematic_left-delta)
	event_time = maxf(0,event_time-delta)
	if cinematic_left > 0: return
	surge_left = maxf(0,surge_left-delta)
	chain_time = maxf(0,chain_time-delta)
	quiet_time += delta
	if chain_time <= 0: chain = 0
	if quiet_time > 6 and world.encounter and flow < 100:
		flow = maxf(0,flow-delta*1.5)
	if is_instance_valid(world.boss_node) and not world.boss_node.dead:
		if world.boss_phase == 1 and world.boss_node.hp <= world.boss_node.max_hp*0.5:
			world.enter_boss_phase_two()
	if world.run_time > 9 and not world.encounter and world.round_index == 0:
		hint("first_seal", "循灯入山", "跟随石灯标记，靠近后按 F 唤醒守灯人")
	if world.player.hp < world.player.max_hp*0.45 and world.heal_count > 0:
		hint("wine", "留一口气", "R 饮下温酒恢复气血；封印解开后还会恢复")

func record(kind: String, actor: Node3D, _source: Node3D, amount := 0.0) -> void:
	if world.mode != "play": return
	match kind:
		"hit":
			if actor == world.player: return
			stats.hits += 1
			chain += 1
			best_chain = maxi(best_chain,chain)
			chain_time = 4.5
			score += 10 + mini(chain,20)*2
			gain(3.2)
		"damage_taken":
			stats.damage_taken += amount
			chain = 0
			chain_time = 0
			flow = maxf(0,flow-8)
		"parry":
			stats.parries += 1
			gain(20+bonuses.resolve*5)
			score += 90
			caption("见切  ·  反击时机",Color("f2d79d"))
		"perfect_dodge":
			stats.perfect_dodges += 1
			gain(16+bonuses.resolve*5)
			score += 75
			caption("掠影  ·  一线之隙",Color("a4e3dd"))
		"execution":
			stats.executions += 1
			gain(20)
			score += 120
			if bonuses.mercy > 0: world.player.hp = minf(world.player.max_hp,world.player.hp+bonuses.mercy*1.2)
			caption("追斩  ·  收剑听雨",Color("f2d79d"))
		"recall":
			stats.recalls += 1
			gain(8)
			score += 45
			caption("回锋  ·  雨痕成刃",Color("a4e3dd"))
		"crash":
			stats.crashes += 1
			gain(12)
			score += 70
			caption("撞破  ·  借势而行",Color("efc28c"))
		"kill":
			gain(9)
			score += 100
		"posture_break":
			gain(6)
			hint("execute", "对手已失势", "靠近金色破势标记，按 F 追斩")

func gain(amount: float) -> void:
	quiet_time = 0
	if surge_active: return
	var was_ready := technique_ready
	flow = clampf(flow+amount,0,100)
	if technique_ready and not was_ready:
		world.notify("万籁将寂", "剑意已满 · 按 V 释放万籁一斩",2.4)
		world.combat_sound("ready")

func caption(text: String, color: Color) -> void:
	event_caption = text
	event_color = color
	event_time = 1.8

func hint(key: String, title: String, text: String) -> void:
	if hints_seen.has(key) or not is_instance_valid(world.ui) or world.ui.toast_timer > 0.3: return
	hints_seen[key] = true
	world.notify(title,text,3.3)

func damage_multiplier() -> float:
	return 1.2 if surge_active else 1.0

func stamina_multiplier() -> float:
	return (1.4 if surge_active else 1.0) + bonuses.breath*0.18

func report() -> Dictionary:
	var result := stats.duplicate(true)
	result["score"] = score
	result["best_chain"] = best_chain
	var art: int = stats.parries+stats.perfect_dodges+stats.executions+stats.recalls+stats.crashes
	result["rank"] = "S" if score >= 4200 and art >= 12 and stats.damage_taken < 22 else ("A" if score >= 3000 and art >= 6 else ("B" if score >= 1600 else "C"))
	result["title"] = {"S":"雨中剑仙","A":"照影宗师","B":"山门剑客","C":"初入江湖"}[result.rank]
	result["difficulty"] = ["听雨","问剑","无相"][world.difficulty]
	return result

func snapshot() -> Dictionary:
	return {"stats":stats.duplicate(true),"bonuses":bonuses.duplicate(true),"score":score,"best_chain":best_chain,"flow":flow,"hints_seen":hints_seen.duplicate()}

func restore(data: Dictionary) -> void:
	stats = data.get("stats",stats).duplicate(true)
	bonuses = data.get("bonuses",bonuses).duplicate(true)
	score = data.get("score",0)
	best_chain = data.get("best_chain",0)
	flow = data.get("flow",0.0)
	hints_seen = data.get("hints_seen",{}).duplicate()
