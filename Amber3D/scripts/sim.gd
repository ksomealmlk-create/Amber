extends RefCounted
# محاكاة اللعب: منقولة حرفياً من engine.dart (نفس الفيزياء ونفس الأرقام، 60 خطوة/ثانية).
# الإحداثيات هنا بالبكسل المنطقي الأصلي (y للأسفل). الرسم ثلاثي الأبعاد يحوّلها في world.gd.

const K_FLOOR := 440.0
const K_H := 500.0

class Bx:
	var x: float = 0.0
	var y: float = 0.0
	var w: float = 0.0
	var h: float = 0.0
	func _init(ax: float = 0.0, ay: float = 0.0, aw: float = 0.0, ah: float = 0.0):
		x = ax
		y = ay
		w = aw
		h = ah
	func hits(o) -> bool:
		return x < o.x + o.w and x + w > o.x and y < o.y + o.h and y + h > o.y

class Player extends Bx:
	var vx: float = 0.0
	var vy: float = 0.0
	var anim: float = 0.0
	var sq: float = 0.0
	var l_n: float = 0.0
	var l_f: float = 0.0
	var a_n: float = 0.0
	var a_f: float = 0.0
	var lean: float = 0.0
	var bob: float = 0.0
	var f: int = 1
	var coy: int = 0
	var atk: int = 0
	var dash: int = 0
	var dcd: int = 0
	var hp: int = 5
	var inv: int = 0
	var jb: int = 0
	var spr: int = 0
	var g: bool = true
	var pj: bool = false
	var pa: bool = false
	var pd: bool = false
	func _init():
		super(30.0, 418.0, 14.0, 22.0)

class Enemy extends Bx:
	var min_x: float = 0.0
	var max_x: float = 0.0
	var ph: float = 0.0
	var base_y: float = 0.0
	var d: int = 1
	var hp: int = 2
	var hit: int = 0
	var kb: int = 0
	var kind: int = 0
	func _init(ax: float, ay: float, amin: float, amax: float, akind: int, aph: float):
		super(ax, ay, 20.0 if akind == 2 else 18.0, 12.0)
		min_x = amin
		max_x = amax
		kind = akind
		ph = aph
		base_y = ay
	func flying() -> bool:
		return kind == 1 or kind == 6

class Ember:
	var x: float = 0.0
	var y: float = 0.0
	var taken: bool = false
	func _init(ax: float, ay: float):
		x = ax
		y = ay

class Chest:
	var x: float = 0.0
	var y: float = 0.0
	var open: bool = false
	var anim: int = 0
	func _init(ax: float, ay: float):
		x = ax
		y = ay

class MovPlat extends Bx:
	var ox: float = 0.0
	var oy: float = 0.0
	var ax: float = 0.0
	var ay: float = 0.0
	var sp: float = 0.0
	var ph: float = 0.0
	var dx: float = 0.0
	var dy: float = 0.0
	func _init(s: Array):
		super(s[0], s[1], s[2], 14.0)
		ox = s[0]
		oy = s[1]
		ax = s[3]
		ay = s[4]
		sp = s[5]
		ph = s[6]

class Crumble extends Bx:
	var timer: int = -1
	var respawn: int = 0
	var active: bool = true
	func _init(s: Array):
		super(s[0], s[1], s[2], 14.0)

class Haz extends Bx:
	var kind: int = 0
	func _init(s: Array):
		super(s[0], s[1], s[2], s[3])
		kind = int(s[4])

class Brk extends Bx:
	var kind: int = 0
	var drop: bool = true
	var hp: int = 1
	var hit: int = 0
	var alive: bool = true
	func _init(s: Array):
		super(s[1], s[2], s[3], s[4])
		kind = int(s[0])
		drop = bool(s[5])
		if kind == 2 or kind == 4 or kind == 5:
			hp = 3
		elif kind == 3:
			hp = 2
		else:
			hp = 1

class TimedHaz extends Bx:
	var kind: int = 0
	var period: float = 150.0
	var on_t: float = 60.0
	var phase: float = 0.0
	var on: bool = false
	var warn: bool = false
	func _init(s: Array):
		super(s[1], s[2], s[3], s[4])
		kind = int(s[0])
		period = s[5]
		on_t = s[6]
		phase = s[7]

class Faller:
	var kind: int = 0
	var x: float = 0.0
	var period: float = 140.0
	var phase: float = 0.0
	var st: int = 0
	var tm: int = 0
	var y: float = -30.0
	var vy: float = 0.0
	func _init(s: Array):
		kind = int(s[0])
		x = s[1]
		period = s[2]
		phase = s[3]
		tm = int(s[3])

class VanishP extends Bx:
	var period: float = 0.0
	var phase: float = 0.0
	var hidden: bool = false
	var solid: bool = true
	var warn: bool = false
	func _init(s: Array):
		super(s[0], s[1], s[2], 14.0)
		period = s[3]
		phase = s[4]
		hidden = bool(s[5])

# ---------------------------------------------------------------- الحالة
var cfg: Dictionary
var length: float = 3400.0
var t: int = 0
var p: Player
var en: Array = []
var embers: Array = []
var chests: Array = []
var movs: Array = []
var crums: Array = []
var haz: Array = []
var brks: Array = []
var timed_h: Array = []
var fallers: Array = []
var vplats: Array = []
var solids: Array = []
var live: Array = []
var checks: Array = []

var inp_left := false
var inp_right := false
var inp_jump := false
var inp_dash := false
var inp_atk := false
var atk_buf: int = 0
var dash_buf: int = 0

var phase: String = "playing" # playing / dead / won
var dead_t: int = 0
var shake: int = 0
var flash: int = 0
var collected: int = 0
var kills: int = 0
var deaths: int = 0
var play_frames: int = 0
var max_hp: int = 5
var dash_cd: int = 40
var hammer_dmg: int = 2
var cp_idx: int = -1
var cp_x: float = 30.0
var cp_y: float = 418.0
var safe_x: float = 30.0
var safe_y: float = 418.0
var goal_x: float = 3300.0
var goal_y: float = 370.0
var total_embers: int = 0

var rng := RandomNumberGenerator.new()
# أحداث للرسم: كل عنصر [النوع, x, y, بيانات]
var events: Array = []

func _init(level: Dictionary):
	cfg = level
	length = level["length"]
	goal_x = level["goal"][0]
	goal_y = level["goal"][1]
	rng.seed = 101
	for a in level["grounds"]:
		solids.append(Bx.new(a[0], a[1], a[2], a[3]))
	for a in level["platforms"]:
		solids.append(Bx.new(a[0], a[1], a[2], a[3]))
	for a in level["extra"]:
		solids.append(Bx.new(a[0], a[1], a[2], a[3]))
	solids.append(Bx.new(length - 10.0, 0.0, 10.0, K_H))
	solids.append(Bx.new(-10.0, 0.0, 10.0, K_H))
	reset()

func emit(kind: String, x: float, y: float, data = null) -> void:
	events.append([kind, x, y, data])

func spark(x: float, y: float, n: int, c: Color) -> void:
	emit("spark", x, y, [n, c])

func dust(x: float, y: float, n: int) -> void:
	emit("dust", x, y, n)

func reset() -> void:
	p = Player.new()
	p.x = 30.0
	p.hp = max_hp
	cp_x = 30.0
	cp_y = 418.0
	safe_x = 30.0
	safe_y = 418.0
	cp_idx = -1
	en.clear()
	for a in cfg["enemies"]:
		var ey: float = (K_FLOOR if a[4] < 0.0 else a[4]) - 12.0
		en.append(Enemy.new(a[0], ey, a[1], a[2], int(a[3]), rng.randf() * 6.0))
	embers.clear()
	for a in cfg["embers"]:
		embers.append(Ember.new(a[0], a[1]))
	chests.clear()
	for a in cfg["chests"]:
		chests.append(Chest.new(a[0], a[1]))
	movs.clear()
	for a in cfg["movs"]:
		movs.append(MovPlat.new(a))
	crums.clear()
	for a in cfg["crumbs"]:
		crums.append(Crumble.new(a))
	haz.clear()
	for a in cfg["hazards"]:
		haz.append(Haz.new(a))
	brks.clear()
	for a in cfg["breaks"]:
		brks.append(Brk.new(a))
	timed_h.clear()
	for a in cfg["timed"]:
		timed_h.append(TimedHaz.new(a))
	fallers.clear()
	for a in cfg["falls"]:
		fallers.append(Faller.new(a))
	vplats.clear()
	for a in cfg["vanish"]:
		vplats.append(VanishP.new(a))
	checks = cfg["checks"]
	collected = 0
	kills = 0
	deaths = 0
	play_frames = 0
	t = 0
	phase = "playing"
	total_embers = cfg["embers"].size() + cfg["chests"].size() * 3
	for b in brks:
		if b.drop:
			total_embers += 1

# ---------------------------------------------------------------- الخطوة
func step() -> void:
	t += 1
	if shake > 0:
		shake -= 1
	if flash > 0:
		flash -= 1
	if phase == "dead":
		dead_t += 1
		if dead_t > 110:
			respawn()
		return
	if phase == "won":
		if t % 3 == 0:
			spark(goal_x + (rng.randf() - 0.5) * 40.0, goal_y + 20.0 + (rng.randf() - 0.5) * 80.0, 1, Color(0.9, 0.78, 1.0))
		return
	play_frames += 1
	update_world()
	update_player()

func respawn() -> void:
	p = Player.new()
	p.x = cp_x - 7.0
	p.y = cp_y - 22.0
	p.hp = max_hp
	p.inv = 90
	safe_x = p.x
	safe_y = p.y
	for f in fallers:
		f.st = 0
		f.tm = int(f.phase)
		f.y = -30.0
		f.vy = 0.0
	phase = "playing"
	emit("respawn", p.x + 7.0, p.y + 11.0, null)

func on_top(b: Bx) -> bool:
	return absf(p.y + p.h - b.y) < 2.6 and p.x + p.w > b.x + 1.0 and p.x < b.x + b.w - 1.0

func update_world() -> void:
	for m in movs:
		var standing: bool = p.g and on_top(m)
		var nx: float = m.ox + sin(t * m.sp + m.ph) * m.ax
		var ny: float = m.oy + sin(t * m.sp * 1.3 + m.ph) * m.ay
		m.dx = nx - m.x
		m.dy = ny - m.y
		m.x = nx
		m.y = ny
		if standing:
			p.x += m.dx
			p.y += m.dy
	for c in crums:
		if c.active:
			if c.timer >= 0:
				c.timer -= 1
				if c.timer == 0:
					c.active = false
					c.respawn = 260
					emit("crumble_fall", c.x + c.w * 0.5, c.y, c)
					dust(c.x + c.w * 0.5, c.y + 8.0, 8)
		else:
			c.respawn -= 1
			if c.respawn <= 0:
				c.active = true
				c.timer = -1
				emit("crumble_back", c.x + c.w * 0.5, c.y, c)
	update_gadgets()
	live.clear()
	live.append_array(solids)
	live.append_array(movs)
	for c in crums:
		if c.active:
			live.append(c)
	for b in brks:
		if b.alive:
			live.append(b)
	for v in vplats:
		if v.solid:
			live.append(v)
	for c in chests:
		if c.open and c.anim < 30:
			c.anim += 1

func brk_color(k: int) -> Color:
	match k:
		1:
			return Color("7A4E2A")
		2:
			return Color("8A8E9A")
		3:
			return Color("7FE6FF")
		4:
			return Color("6A6F7A")
		5:
			return Color("D8CCB4")
	return Color("A06A34")

func hit_breakables(ab: Bx) -> void:
	for b in brks:
		if not b.alive or not ab.hits(b):
			continue
		b.hp -= 1
		b.hit = 8
		spark(b.x + b.w * 0.5, b.y + b.h * 0.5, 6, brk_color(b.kind))
		if b.hp <= 0:
			b.alive = false
			emit("break", b.x + b.w * 0.5, b.y + b.h * 0.5, b)
			shake = 5
			if b.drop:
				collected += 1
				flash = 5
				spark(b.x + b.w * 0.5, b.y, 12, Color("FFD98A"))
				emit("drop", b.x + b.w * 0.5, b.y, null)

func update_gadgets() -> void:
	if phase != "playing":
		return
	var px: float = p.x + 7.0
	for b in brks:
		if b.hit > 0:
			b.hit -= 1
	for h in timed_h:
		var m: float = fposmod(float(t) + h.phase, h.period)
		h.on = m < h.on_t
		h.warn = (not h.on) and m > h.period - 26.0
		if h.on and m < 2.0 and absf(px - h.x) < 300.0:
			spark(h.x + h.w * 0.5, h.y + h.h, 4, Color("FFE27A"))
		if h.on and p.hits(h):
			if hurt(h.x + h.w * 0.5):
				return
	for f in fallers:
		var fx: float = f.x
		if f.st == 0:
			if absf(px - fx) < 340.0:
				f.tm += 1
				if f.tm >= int(f.period):
					f.st = 1
					f.tm = 0
		elif f.st == 1:
			f.tm += 1
			if f.tm >= 36:
				f.st = 2
				f.y = -20.0
				f.vy = 0.0
		elif f.st == 2:
			f.vy = minf(8.0, f.vy + 0.35)
			f.y += f.vy
			if p.hits(Bx.new(fx - 9.0, f.y - 9.0, 18.0, 18.0)):
				f.st = 3
				f.tm = 0
				spark(fx, f.y, 10, Color("CCCCCC"))
				emit("rock_hit", fx, f.y, null)
				if hurt(fx):
					return
			elif f.y >= K_FLOOR - 9.0:
				f.st = 3
				f.tm = 0
				shake = 3
				spark(fx, K_FLOOR - 8.0, 12, Color("BBBBBB"))
				dust(fx, K_FLOOR, 6)
				emit("rock_hit", fx, K_FLOOR - 8.0, null)
		else:
			f.tm += 1
			if f.tm > 20:
				f.st = 0
				f.tm = 0
	for v in vplats:
		if v.period > 0.0:
			var m2: float = fposmod(float(t) + v.phase, v.period)
			v.solid = m2 < v.period * 0.68
			v.warn = v.solid and m2 > v.period * 0.68 - 24.0
		else:
			v.solid = true

func hurt(from_x: float) -> bool:
	if p.inv > 0:
		return false
	p.hp -= 1
	p.inv = 70
	p.vy = -5.0
	p.vx = (-1.0 if p.x < from_x else 1.0) * 4.0
	shake = 7
	spark(p.x + 7.0, p.y + 11.0, 12, Color("FF6666"))
	emit("hurt", p.x + 7.0, p.y + 11.0, null)
	if p.hp <= 0:
		die()
		return true
	return false

func die() -> void:
	deaths += 1
	phase = "dead"
	dead_t = 0
	shake = 12
	spark(p.x + 7.0, p.y + 11.0, 40, Color("FFB347"))
	emit("die", p.x + 7.0, p.y + 11.0, null)

func move_x(o: Player, dx: float) -> void:
	o.x += dx
	for s in live:
		if o.hits(s):
			if dx > 0.0:
				o.x = s.x - o.w
			elif dx < 0.0:
				o.x = s.x + s.w
			o.vx = 0.0

func move_y(o: Player, dy: float) -> bool:
	var g := false
	o.y += dy
	for s in live:
		if o.hits(s):
			if dy > 0.0:
				o.y = s.y - o.h
				g = true
			elif dy < 0.0:
				o.y = s.y + s.h
			o.vy = 0.0
	return g

func check_checkpoints() -> void:
	var i: int = cp_idx + 1
	while i < checks.size():
		var c = checks[i]
		if absf((p.x + 7.0) - c[0]) < 26.0 and p.g and absf((p.y + p.h) - c[1]) < 6.0:
			cp_idx = i
			cp_x = c[0]
			cp_y = c[1]
			spark(c[0], c[1] - 24.0, 22, Color("9FE8FF"))
			emit("checkpoint", c[0], c[1], i)
			flash = 4
			break
		i += 1

func track_safe() -> void:
	if not p.g or p.inv > 0:
		return
	for h in haz:
		if Bx.new(h.x - 26.0, h.y - 30.0, h.w + 52.0, h.h + 60.0).hits(p):
			return
	for h in timed_h:
		if Bx.new(h.x - 26.0, h.y - 30.0, h.w + 52.0, h.h + 60.0).hits(p):
			return
	for s in solids:
		if s.w >= 24.0 and on_top(s):
			safe_x = maxf(s.x + 4.0, minf(s.x + s.w - p.w - 4.0, p.x))
			safe_y = s.y - p.h
			return

func update_player() -> void:
	var L: bool = inp_left
	var R: bool = inp_right
	if p.inv > 0:
		p.inv -= 1
	if p.spr > 0:
		p.spr -= 1
	if p.dcd > 0:
		p.dcd -= 1
	if inp_jump and not p.pj:
		p.jb = 10
	p.pj = inp_jump
	if p.jb > 0:
		p.jb -= 1
	if inp_atk and not p.pa:
		atk_buf = 10
	if atk_buf > 0:
		atk_buf -= 1
		if p.atk <= 0:
			p.atk = 26
			atk_buf = 0
			for e in en:
				e.hit = 0
			emit("swing", p.x + 7.0, p.y + 11.0, p.f)
	p.pa = inp_atk
	if inp_dash and not p.pd:
		dash_buf = 8
	if dash_buf > 0:
		dash_buf -= 1
		if p.dcd <= 0 and p.dash <= 0:
			p.dash = 10
			p.dcd = dash_cd
			p.vy = 0.0
			dash_buf = 0
			emit("dash", p.x + 7.0, p.y + 11.0, p.f)
	p.pd = inp_dash
	if p.dash > 0:
		p.dash -= 1
		p.vx = p.f * 8.0
		p.vy = 0.0
		if t % 2 == 0:
			spark(p.x + 7.0, p.y + 11.0, 1, Color("66AADD"))
	else:
		var a: float = 0.95 if p.g else 0.62
		if L and not R:
			p.vx -= a
			p.f = -1
		elif R and not L:
			p.vx += a
			p.f = 1
		else:
			p.vx *= 0.7 if p.g else 0.93
		p.vx = maxf(-3.0, minf(3.0, p.vx))
		p.vy += 0.5
		if p.vy > 11.0:
			p.vy = 11.0
	if p.g:
		p.coy = 8
	elif p.coy > 0:
		p.coy -= 1
	if p.jb > 0 and p.coy > 0:
		p.vy = -9.5
		p.coy = 0
		p.jb = 0
		p.g = false
		p.sq = -0.25
		dust(p.x + 7.0, p.y + 22.0, 6)
		emit("jump", p.x + 7.0, p.y + 22.0, null)
	if not inp_jump and p.vy < -3.5 and p.dash <= 0 and p.spr <= 0:
		p.vy = -3.5

	var was_g: bool = p.g
	var pre_vy: float = p.vy
	move_x(p, p.vx)
	p.g = move_y(p, p.vy)
	if p.g and not was_g and pre_vy > 3.0:
		p.sq = 0.3
		dust(p.x + 7.0, p.y + 22.0, 8)
		emit("land", p.x + 7.0, p.y + 22.0, pre_vy)
	p.sq *= 0.8
	if p.g and absf(p.vx) > 0.5:
		p.anim += absf(p.vx) * 0.12
		if t % 9 == 0:
			dust(p.x + 7.0, p.y + 22.0, 1)
	if p.g:
		for c in crums:
			if c.active and c.timer < 0 and on_top(c):
				c.timer = 28
				emit("crumble_start", c.x + c.w * 0.5, c.y, c)

	if checks.size() > 0:
		check_checkpoints()
		track_safe()
	if p.y > K_H + 40.0:
		p.hp -= 1
		shake = 8
		if checks.size() > 0:
			p.x = safe_x
			p.y = safe_y
		else:
			p.x = cp_x
			p.y = 380.0
		p.vx = 0.0
		p.vy = 0.0
		p.inv = 100 if checks.size() > 0 else 60
		emit("fell", p.x + 7.0, p.y + 11.0, null)
		if p.hp <= 0:
			die()
			return

	# ضربة المطرقة
	var ab := Bx.new(p.x + p.w if p.f > 0 else p.x - 36.0, p.y - 8.0, 36.0, 36.0)
	for e in en:
		if e.hp <= 0:
			continue
		move_enemy(e)
		if p.atk > 8 and p.atk < 17 and e.hit == 0 and ab.hits(e):
			e.hit = 1
			e.hp -= hammer_dmg
			e.kb = 8
			spark(e.x + 9.0, e.y + 6.0, 10, Color("FFB347"))
			shake = 4
			emit("enemy_hit", e.x + 9.0, e.y + 6.0, e)
			if e.hp <= 0:
				kills += 1
				spark(e.x + 9.0, e.y + 6.0, 26, Color("FFD27A"))
				emit("enemy_die", e.x + 9.0, e.y + 6.0, e)
		if e.hp > 0 and p.hits(e):
			if hurt(e.x + 9.0):
				return
	for h in haz:
		if p.hits(h):
			if hurt(h.x + h.w * 0.5):
				return

	for m in embers:
		if m.taken:
			continue
		var dx: float = (p.x + 7.0) - m.x
		var dy: float = (p.y + 11.0) - m.y
		if dx * dx + dy * dy < 400.0:
			m.taken = true
			collected += 1
			spark(m.x, m.y, 14, Color("FFD98A"))
			emit("ember", m.x, m.y, m)
			flash = 6
			if collected % 6 == 0 and p.hp < max_hp:
				p.hp += 1
				emit("heal", p.x + 7.0, p.y + 11.0, null)
	for c in chests:
		if not c.open and p.hits(Bx.new(c.x - 2.0, c.y - 2.0, 22.0, 18.0)):
			c.open = true
			collected += 3
			if p.hp < max_hp:
				p.hp = mini(max_hp, p.hp + 2)
			spark(c.x + 8.0, c.y + 4.0, 30, Color("FFD27A"))
			emit("chest", c.x + 8.0, c.y + 4.0, c)
			shake = 4

	if absf(p.x - goal_x) < 30.0 and absf(p.y - goal_y) < 70.0:
		phase = "won"
		spark(goal_x, goal_y + 20.0, 50, Color("E6C8FF"))
		emit("win", goal_x, goal_y, null)
	if p.atk == 12:
		hit_breakables(ab)
		spark(p.x + 7.0 + p.f * 24.0, p.y + 18.0, 18, Color("BDEFFF"))
		shake = 5
	if p.atk > 0:
		p.atk -= 1
	animate()

func move_enemy(e: Enemy) -> void:
	if e.flying():
		e.y = e.base_y + sin(t / 25.0 + e.ph) * 10.0
	if e.kb > 0:
		e.kb -= 1
		e.x += (1.0 if p.x < e.x else -1.0) * 2.5
		return
	var sp: float = 0.9 if e.kind == 1 else (0.95 if e.kind == 2 else 0.7)
	e.x += e.d * sp
	if e.x < e.min_x:
		e.d = 1
	if e.x + e.w > e.max_x:
		e.d = -1

func animate() -> void:
	var l_n: float = 0.0
	var l_f: float = 0.0
	var a_n: float = 0.0
	var a_f: float = 0.0
	var lean: float = 0.0
	var bob: float = 0.0
	var spd: float = minf(1.0, absf(p.vx) / 3.0)
	var ph: float = p.anim
	if p.dash > 0:
		l_n = -0.75
		l_f = 0.7
		a_n = 1.2
		a_f = 1.0
		lean = 0.3
	elif not p.g:
		if p.vy < 0.0:
			l_n = -0.6
			l_f = 0.4
			a_n = -1.1
			a_f = -0.8
		else:
			l_n = -0.2
			l_f = 0.3
			a_n = -0.7
			a_f = -0.4
		lean = 0.05
	elif absf(p.vx) > 0.5:
		var sn: float = sin(ph)
		var amp: float = 0.35 + 0.35 * spd
		var a2: float = 0.5 + 0.3 * spd
		l_n = -amp * sn
		l_f = amp * sn
		a_n = a2 * sn
		a_f = -a2 * sn
		bob = -absf(sin(ph)) * 0.9
		lean = 0.07 * spd
	else:
		var br: float = sin(t / 25.0)
		a_n = 0.08 * br
		a_f = -0.08 * br
		bob = br * 0.25
	var kn: float = 0.3
	if p.atk > 0:
		kn = 0.5
		if p.atk > 16:
			a_n = -3.2
			a_f = -1.2
			lean = -0.12
		elif p.atk > 8:
			a_n = -0.9
			a_f = 0.5
			lean = 0.25
		else:
			a_n = -0.3
			lean = 0.1
	var k: float = 0.3
	p.l_n += (l_n - p.l_n) * k
	p.l_f += (l_f - p.l_f) * k
	p.a_n += (a_n - p.a_n) * kn
	p.a_f += (a_f - p.a_f) * k
	p.lean += (lean - p.lean) * kn
	p.bob += (bob - p.bob) * k
