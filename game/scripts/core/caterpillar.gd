class_name Caterpillar
extends Node2D
## 主人公のイモムシ。
## 通常は「頭の軌跡を胴体が正確になぞる」クロール状態。支持ルールを破ったときだけ
## 簡易ロープ物理の落下状態になり、落ち着いたらその形のまま軌跡を作り直して復帰する
## （企画書 5.2 のハイブリッド方式）。

signal died(info: Dictionary)
signal snipped(index: int)

enum State { CRAWL, FALL, DEAD, CLEAR }

const BODY_COLOR := Color("8bd346")
const BODY_COLOR_2 := Color("7cc23b")
const OUTLINE := Color("3e7a1e")
const HIGHLIGHT := Color("c6f07a")
const HEART := Color("f48fb1")

var state: int = State.CRAWL
var world: World
var trail := Trail.new()
var n: int = 12
var seg := PackedVector2Array()
var prev := PackedVector2Array()
var last_seg := PackedVector2Array()
var sup: Array = []
var sup_n := PackedVector2Array()
var rule: Dictionary = {}
var heading := 0.0

# 入力（Game が毎フレーム設定する）
var in_dir := Vector2.ZERO
var in_fast := true
var in_back := false

var unstable_t := 0.0
var strain_t := 0.0
var straining := false
var still_t := 0.0
var fall_t := 0.0
var nogrip_t := 0.0
var moving := false
var stopped_t := 0.0
var tail_speed := 0.0
var anim_t := 0.0
var debris: Array = []
var exploded := false
var death_info: Dictionary = {}
## 前フレームの頭の位置（ビームの横切り判定などに使う）
var prev_head := Vector2.ZERO
var _last_tail := Vector2.ZERO


func spawn(head_pos: Vector2, facing: Vector2 = Vector2.RIGHT) -> void:
	n = Params.seg_count
	var f := facing.normalized()
	var pts := PackedVector2Array()
	for i in n:
		pts.append(head_pos - f * Params.spacing * i)
	trail.reset_line(pts)
	seg = pts.duplicate()
	prev = seg.duplicate()
	last_seg = seg.duplicate()
	heading = f.angle()
	state = State.CRAWL
	unstable_t = 0.0
	strain_t = 0.0
	straining = false
	still_t = 0.0
	fall_t = 0.0
	nogrip_t = 0.0
	moving = false
	stopped_t = 0.0
	tail_speed = 0.0
	exploded = false
	debris.clear()
	death_info = {}
	prev_head = head()
	_last_tail = tail()
	_eval_support()
	queue_redraw()


func head() -> Vector2:
	return seg[0]


func tail() -> Vector2:
	return seg[n - 1]


func body_len() -> float:
	return Params.spacing * (n - 1)


func is_alive() -> bool:
	return state == State.CRAWL or state == State.FALL


func step(dt: float) -> void:
	anim_t += dt
	prev_head = seg[0] if n > 0 else Vector2.ZERO
	_step_debris(dt)
	match state:
		State.CRAWL:
			_crawl(dt)
		State.FALL:
			_fall(dt)
	if n > 0 and is_alive():
		var ts := tail().distance_to(_last_tail) / dt
		tail_speed = lerpf(tail_speed, ts, 0.3)
		_last_tail = tail()
	if moving:
		stopped_t = 0.0
	else:
		stopped_t += dt
	queue_redraw()


# ---------------------------------------------------------------- クロール

func _crawl(dt: float) -> void:
	_eval_support()
	if not rule.ok:
		# 足場が消えた・押されたなど、環境の変化で支えを失った
		unstable_t += dt
		if unstable_t > 0.05:
			_enter_fall(0.0)
			return
	else:
		unstable_t = 0.0

	var snap := trail.snapshot()
	var tried := false
	moving = false
	if in_back:
		tried = trail.retreat(Params.speed_slow * dt, body_len())
	elif in_dir != Vector2.ZERO:
		var slow := not in_fast or Params.always_slow
		var rate := deg_to_rad(Params.turn_rate_slow if slow else Params.turn_rate)
		heading = rotate_toward(heading, in_dir.angle(), rate * dt)
		var spd := Params.speed_slow if slow else Params.speed_fast
		var want := Vector2.from_angle(heading) * spd * dt
		var np := _move_head(trail.head, want)
		if np.distance_to(trail.head) > 0.01:
			trail.move_head(np)
			tried = true

	if tried:
		var cand := _compute_segments()
		var cflags := _support_flags(cand)
		var crule := SupportRule.evaluate_default(cflags[0])
		if crule.ok or not rule.ok:
			last_seg = seg
			seg = cand
			sup = cflags[0]
			sup_n = cflags[1]
			rule = crule
			moving = true
			if crule.ok:
				straining = false
				strain_t = 0.0
		else:
			trail.restore(snap)
			if crule.head_run > Params.reach and not in_back:
				# 首を伸ばせる限界。押し続けると手が滑って落ちる
				straining = true
				strain_t += dt
				if strain_t >= Params.strain_letgo:
					_enter_fall(0.35)
					return
	else:
		straining = false
		strain_t = maxf(0.0, strain_t - dt * 2.0)
	trail.trim(maxf(body_len() * 3.0, 400.0))


## 頭を want だけ動かす。面に当たったら面に沿って滑らせる（壁登り・天井歩き）。
func _move_head(p: Vector2, want: Vector2) -> Vector2:
	var r := Params.BODY_RADIUS
	var res := world.push_out(p + want, r)
	if not res.hit:
		return p + want
	var nrm: Vector2 = res.normal
	var d := want.normalized()
	if -d.dot(nrm) > 0.2:
		var t := Vector2(-nrm.y, nrm.x)
		var along := d.dot(t)
		var sgn := signf(along)
		if absf(along) < 0.15:
			# 入口アシスト：真正面に押したとき、すぐ横に通れる隙間（煙突など）があれば寄せる
			for k in [6.0, 12.0, 18.0, 24.0]:
				for s2 in [1.0, -1.0]:
					if not world.push_out(p + t * s2 * k + d * 3.0, r).hit:
						return world.push_out(p + t * s2 * want.length(), r).pos
			if absf(nrm.y) > 0.7:
				# 床・天井に真正面から当たったら、それまで進んでいた向きに滑る
				var last := trail.pts[trail.pts.size() - 1] if trail.pts.size() > 0 else p
				var moved := (p - last).dot(t)
				if absf(moved) < 0.01:
					return res.pos
				sgn = signf(moved)
			elif res.grip:
				sgn = -1.0 if t.y > 0.0 else 1.0  # つかめる壁に真正面から当たったら上へ
			else:
				return res.pos  # ガラスなどは登れない
		var res2 := world.push_out(p + t * sgn * want.length(), r)
		return res2.pos
	return res.pos


func _compute_segments() -> PackedVector2Array:
	var s := trail.sample(n, Params.spacing)
	var k := Params.inner_wheel
	if k > 0.0 and last_seg.size() == n:
		# 内輪差：前の節に引っ張られる関節チェーンを混ぜる（検証項目 V-06）
		var chain := PackedVector2Array()
		chain.resize(n)
		chain[0] = s[0]
		for i in range(1, n):
			var dir := seg[i] - chain[i - 1]
			if dir.length() < 0.001:
				dir = s[i] - s[i - 1]
			chain[i] = chain[i - 1] + dir.normalized() * Params.spacing
		for i in n:
			s[i] = s[i].lerp(chain[i], k)
	return s


func _support_flags(arr: PackedVector2Array) -> Array:
	var flags: Array = []
	var normals := PackedVector2Array()
	flags.resize(arr.size())
	normals.resize(arr.size())
	for i in arr.size():
		var nrm := world.support_normal(arr[i], Params.BODY_RADIUS)
		flags[i] = nrm != Vector2.ZERO
		normals[i] = nrm
	return [flags, normals]


func _eval_support() -> void:
	var f := _support_flags(seg)
	sup = f[0]
	sup_n = f[1]
	rule = SupportRule.evaluate_default(sup)


# ---------------------------------------------------------------- 落下

func _enter_fall(nogrip: float) -> void:
	state = State.FALL
	prev = PackedVector2Array()
	prev.resize(n)
	for i in n:
		# クロール中の動きを初速として引き継ぐ
		prev[i] = last_seg[i] if last_seg.size() == n else seg[i]
	fall_t = 0.0
	still_t = 0.0
	nogrip_t = nogrip
	straining = false
	strain_t = 0.0
	moving = false


func _fall(dt: float) -> void:
	fall_t += dt
	nogrip_t -= dt
	var f := _support_flags(seg)
	var flags: Array = f[0]
	var r := SupportRule.evaluate_default(flags)
	var pin: Array = []
	pin.resize(n)
	for i in n:
		pin[i] = r.ok and flags[i] and nogrip_t <= 0.0

	var g := Vector2(0.0, Params.GRAVITY) * dt * dt
	for i in n:
		if pin[i]:
			prev[i] = seg[i]
			continue
		var v := (seg[i] - prev[i]) * 0.995
		prev[i] = seg[i]
		seg[i] += v + g
	if n > 0 and not pin[0]:
		seg[0].x += in_dir.x * 500.0 * dt * dt  # ぶら下がり中は体を少し振れる

	var sp := Params.spacing
	var rad := Params.BODY_RADIUS
	var contact := PackedVector2Array()
	contact.resize(n)
	var slick: Array = []
	slick.resize(n)
	for _k in 8:
		for i in n - 1:
			var wa := 0.0 if pin[i] else 1.0
			var wb := 0.0 if pin[i + 1] else 1.0
			if wa + wb == 0.0:
				continue
			var d := seg[i + 1] - seg[i]
			var dist := d.length()
			if dist < 0.0001:
				continue
			var corr := d * ((dist - sp) / dist) / (wa + wb)
			seg[i] += corr * wa
			seg[i + 1] -= corr * wb
		for i in n - 2:
			# 曲げの硬さ：鋭く折れ曲がらないようにする
			var d2 := seg[i + 2] - seg[i]
			var dist2 := d2.length()
			var minimum := sp * 1.5
			if dist2 < minimum and dist2 > 0.0001:
				var push := d2 * ((dist2 - minimum) / dist2) * 0.125
				if not pin[i]:
					seg[i] += push
				if not pin[i + 2]:
					seg[i + 2] -= push
		for i in n:
			if pin[i]:
				continue
			var res := world.push_out(seg[i], rad)
			if res.hit:
				seg[i] = res.pos
				contact[i] = res.normal
				slick[i] = not res.grip
	# 接触面での摩擦
	var maxv := 0.0
	for i in n:
		if contact[i] != Vector2.ZERO:
			var v2 := seg[i] - prev[i]
			var nn := contact[i]
			var vn := nn * v2.dot(nn)
			var vt := v2 - vn
			if v2.dot(nn) < 0.0:
				vn = Vector2.ZERO
			prev[i] = seg[i] - (vt * (0.98 if slick[i] else 0.7) + vn)
		maxv = maxf(maxv, (seg[i] - prev[i]).length() / dt)

	_eval_support()
	if rule.ok and maxv < 60.0 and nogrip_t <= 0.0:
		still_t += dt
	else:
		still_t = 0.0
	if still_t >= 0.15:
		_recover()
	elif fall_t > 4.0:
		kill("落下", 0, "おちた…")


func _recover() -> void:
	trail.reset_line(seg)
	heading = (seg[0] - seg[1]).angle() if n > 1 else heading
	last_seg = seg.duplicate()
	state = State.CRAWL
	unstable_t = 0.0
	_eval_support()


## 足場が壊れたときなどに呼ぶ。支えのある節は踏ん張り、それ以外は重力でたるむ。
func jolt() -> void:
	if state == State.CRAWL:
		_enter_fall(0.0)


## 罠が体の形を強制的に決める（例：縦穴でつっかえる）。
func force_pose(points_head_first: PackedVector2Array) -> void:
	seg = points_head_first.duplicate()
	prev = seg.duplicate()
	_recover()


# ---------------------------------------------------------------- 失敗・切断

static func part_name_for(index: int, count: int) -> String:
	if index <= 0:
		return "あたま"
	if index >= count - 3:
		return "おしり"
	return "まんなか"


func kill(cause: String, index: int, text: String, fx: String = "pop") -> void:
	if not is_alive():
		return
	var idx := clampi(index, 0, maxi(n - 1, 0))
	death_info = {
		"cause": cause,
		"index": idx,
		"part": part_name_for(idx, n),
		"text": text,
		"fx": fx,
		"pos": seg[idx] if n > 0 else Vector2.ZERO,
	}
	state = State.DEAD
	if fx == "cut" and idx > 0:
		# 切られた場所で体を離して見せる
		var gap := (seg[idx - 1] - seg[idx]).normalized() * 10.0
		for i in range(idx, n):
			seg[i] -= gap
	died.emit(death_info)


## index 番目から後ろを切り落とす。残りが最短長より短ければ失敗。
func cut(index: int, cause: String, text: String) -> void:
	if not is_alive():
		return
	if index <= 0:
		kill(cause, 0, text, "cut")
		return
	if index < Params.min_len:
		kill(cause, index, text, "cut")
		return
	if index >= n:
		return
	for i in range(index, n):
		debris.append({
			"p": seg[i],
			"v": Vector2(-40.0 + 25.0 * (i % 3), -220.0 - 30.0 * (i % 4)),
			"life": 3.0,
			"r": _radius(i),
			"tail": i == n - 1,
			"head": false,
		})
	n = index
	seg.resize(n)
	prev.resize(n)
	last_seg.resize(n)
	sup.resize(n)
	sup_n.resize(n)
	_eval_support()
	snipped.emit(index)


func explode() -> void:
	if exploded:
		return
	exploded = true
	var center := Vector2.ZERO
	for p in seg:
		center += p
	center /= maxf(1.0, float(n))
	for i in n:
		var out := (seg[i] - center)
		if out.length() < 1.0:
			out = Vector2(0, -1)
		var v := out.normalized() * (180.0 + 40.0 * (i % 3)) + Vector2(0, -260)
		debris.append({"p": seg[i], "v": v, "life": 2.5, "r": _radius(i), "tail": i == n - 1, "head": i == 0})


func _step_debris(dt: float) -> void:
	var keep: Array = []
	for d in debris:
		d.life -= dt
		if d.life <= 0.0:
			continue
		d.v.y += Params.GRAVITY * dt
		var np: Vector2 = d.p + d.v * dt
		if world != null:
			var res := world.push_out(np, d.r * 0.8)
			if res.hit:
				np = res.pos
				d.v = d.v.bounce(res.normal) * 0.45
		d.p = np
		keep.append(d)
	debris = keep


# ---------------------------------------------------------------- 判定ヘルパー（罠から使う）

func first_hit_rect(r: Rect2, rad: float = Params.HIT_RADIUS) -> int:
	for i in n:
		if World.circle_hits_rect(r, seg[i], rad):
			return i
	return -1


func first_hit_circle(c: Vector2, cr: float) -> int:
	var lim := cr + Params.HIT_RADIUS
	for i in n:
		if seg[i].distance_squared_to(c) < lim * lim:
			return i
	return -1


## 矩形の上面に乗っている節の数
func count_on_top(r: Rect2) -> int:
	var c := 0
	var rad := Params.BODY_RADIUS
	for i in n:
		var p := seg[i]
		if p.x >= r.position.x - 2.0 and p.x <= r.end.x + 2.0 and p.y <= r.position.y + 2.0 and p.y >= r.position.y - rad - Params.CONTACT_MARGIN - 1.0:
			c += 1
	return c


func all_inside(r: Rect2) -> bool:
	for i in n:
		if not r.has_point(seg[i]):
			return false
	return n > 0


func centroid() -> Vector2:
	var c := Vector2.ZERO
	for p in seg:
		c += p
	return c / maxf(1.0, float(n))


# ---------------------------------------------------------------- 描画

func _radius(i: int) -> float:
	var r := Params.BODY_RADIUS * 1.3  # 見た目は当たり判定より太く
	if i == 0:
		return r * 1.18
	return r * (1.0 - 0.18 * float(i) / float(maxi(n - 1, 1)))


func _tangent(i: int) -> Vector2:
	var d := Vector2.ZERO
	if n < 2:
		return Vector2.from_angle(heading)
	if i == 0:
		d = seg[0] - seg[1]
	else:
		d = seg[i - 1] - seg[i]
	if d.length() < 0.001:
		return Vector2.from_angle(heading)
	return d.normalized()


func _draw() -> void:
	for d in debris:
		var a := clampf(d.life, 0.0, 1.0)
		draw_circle(d.p, d.r + 2.0, Color(OUTLINE, a))
		draw_circle(d.p, d.r, Color(BODY_COLOR, a))
		if d.tail:
			_draw_heart(d.p, d.r * 0.5, Color(HEART, a))
		if d.head:
			_draw_x_eyes(d.p, d.r, Vector2.RIGHT, Vector2.UP)
	if exploded or n == 0:
		return
	var alive := is_alive()
	for i in range(n - 1, -1, -1):
		var p := seg[i]
		var r := _radius(i)
		var t := _tangent(i)
		if i > 0:
			_draw_legs(i, p, r, t, alive)
		draw_circle(p, r + 2.0, OUTLINE)
		draw_circle(p, r, BODY_COLOR if i % 2 == 0 else BODY_COLOR_2)
		draw_circle(p + Vector2(-r * 0.3, -r * 0.35), r * 0.35, Color(HIGHLIGHT, 0.7))
		if i == n - 1 and i > 0:
			_draw_heart(p - t * r * 0.45, r * 0.5, HEART)
	_draw_face()


func _draw_legs(i: int, p: Vector2, r: float, t: Vector2, alive: bool) -> void:
	var down: Vector2
	var grounded: bool = i < sup.size() and sup[i] and i < sup_n.size() and sup_n[i] != Vector2.ZERO
	if grounded:
		down = -sup_n[i]
	else:
		down = t.orthogonal()
		if down.y < 0.0:
			down = -down
	var leg_col := OUTLINE
	for side in [-1.0, 1.0]:
		var base: Vector2 = p + down * r * 0.6 + t * r * 0.35 * side
		var tip: Vector2
		if grounded:
			tip = base + down * 6.0
		else:
			var wig := sin(anim_t * 18.0 + i * 1.3 + side) * 0.6 if alive else 0.3
			tip = base + down.rotated(wig * side) * 9.0
		draw_line(base, tip, leg_col, 2.5)


func _draw_heart(c: Vector2, s: float, col: Color) -> void:
	draw_circle(c + Vector2(-s * 0.35, -s * 0.2), s * 0.42, col)
	draw_circle(c + Vector2(s * 0.35, -s * 0.2), s * 0.42, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.75, -s * 0.05), c + Vector2(s * 0.75, -s * 0.05), c + Vector2(0, s * 0.7)]), col)


func _draw_x_eyes(p: Vector2, r: float, f: Vector2, up: Vector2) -> void:
	for e in [p + f * r * 0.45 + up * r * 0.3, p + f * r * 0.0 + up * r * 0.42]:
		var s := r * 0.22
		draw_line(e + Vector2(-s, -s), e + Vector2(s, s), Color.BLACK, 2.0)
		draw_line(e + Vector2(-s, s), e + Vector2(s, -s), Color.BLACK, 2.0)


func _draw_face() -> void:
	var p := seg[0]
	var r := _radius(0)
	var f := _tangent(0)
	var up := f.orthogonal()
	if up.y > 0.0:
		up = -up
	# 触角
	for k in [0.0, 0.45]:
		var base: Vector2 = p + up * r * 0.8 - f * r * k
		var tip: Vector2 = base + up * r * 0.75 + f * r * 0.35
		draw_line(base, tip, OUTLINE, 2.0)
		draw_circle(tip, 2.5, OUTLINE)
	var eyes := [p + f * r * 0.45 + up * r * 0.3, p + f * r * 0.02 + up * r * 0.42]
	if state == State.DEAD:
		_draw_x_eyes(p, r, f, up)
	elif state == State.CLEAR:
		for e in eyes:
			draw_arc(e, r * 0.2, PI, TAU, 8, Color.BLACK, 2.0)
	elif straining:
		for e in eyes:
			draw_line(e - f * r * 0.2, e + f * r * 0.2, Color.BLACK, 2.5)
		var drop_t := fmod(anim_t * 2.0, 1.0)
		var dp := p + up * r * (1.0 + drop_t * 0.6) - f * r * (0.6 + drop_t * 0.5)
		draw_circle(dp, 3.5, Color("4fc3f7"))
	else:
		var big := state == State.FALL
		for e in eyes:
			draw_circle(e, r * (0.36 if big else 0.3), Color.WHITE)
			draw_circle(e + f * r * (0.05 if big else 0.1), r * (0.1 if big else 0.15), Color.BLACK)
	var mouth := p + f * r * 0.6 - up * r * 0.25
	if state == State.FALL:
		draw_circle(mouth, r * 0.18, Color("5d1f1f"))
	elif state == State.CLEAR:
		draw_arc(mouth, r * 0.22, 0.0, PI, 8, Color("5d1f1f"), 2.0)
	else:
		draw_line(mouth - up * r * 0.1, mouth + up * r * 0.05 + f * r * 0.1, Color("5d1f1f"), 2.0)
