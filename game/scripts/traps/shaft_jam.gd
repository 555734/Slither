class_name ShaftJam
extends Trap
## #29 つっかえ棒：縦穴の幅は全長より狭い。横向きのまま落ちると壁に突っ張って止まる。
## 頭から細く落ちると、そのまま底のトゲまで落ちる。

var x0 := 0.0
var x1 := 0.0
var jam_y := 0.0
var jammed := false
var amp := 0.0


func setup(st: Stage, left: float, right: float, y: float) -> ShaftJam:
	stage = st
	x0 = left
	x1 = right
	jam_y = y
	trap_id = "shaft_jam"
	st.world.providers.append(self)
	return self


func reset() -> void:
	jammed = false
	queue_redraw()


func support_at(p: Vector2) -> bool:
	return jammed and p.x >= x0 and p.x <= x1 and absf(p.y - jam_y) <= amp + 16.0


func tick(_dt: float, cat: Caterpillar) -> void:
	if jammed or cat.state != Caterpillar.State.FALL:
		return
	var c := cat.centroid()
	if c.y < jam_y - 10.0 or c.x < x0 or c.x > x1:
		return
	var lo := INF
	var hi := -INF
	for p in cat.seg:
		lo = minf(lo, p.x)
		hi = maxf(hi, p.x)
	if hi - lo >= (x1 - x0) * 0.55:
		_jam(cat)


func _jam(cat: Caterpillar) -> void:
	var r := Params.BODY_RADIUS
	var a := x0 + r + 1.0
	var b := x1 - r - 1.0
	var need := cat.body_len() + 2.0
	# 必要な長さが収まる波の振幅を探す
	amp = 0.0
	var waves := 2.0
	while _wave_len(a, b, amp, waves) < need:
		amp += 1.0
		if amp > 40.0:
			amp = 0.0
			waves += 1.0
	var head_right := cat.head().x >= cat.centroid().x
	var pts := _sample_wave(a, b, amp, waves, cat.n, Params.spacing, head_right)
	jammed = true
	cat.force_pose(pts)
	cat.heading = 0.0 if head_right else PI
	queue_redraw()


func _wave_y(u: float, a_: float, waves: float) -> float:
	return jam_y - a_ * sin(TAU * waves * u)


func _wave_len(a: float, b: float, a_: float, waves: float) -> float:
	var total := 0.0
	var prev := Vector2(a, _wave_y(0.0, a_, waves))
	for k in range(1, 201):
		var u := float(k) / 200.0
		var p := Vector2(lerpf(a, b, u), _wave_y(u, a_, waves))
		total += prev.distance_to(p)
		prev = p
	return total


func _sample_wave(a: float, b: float, a_: float, waves: float, count: int, spacing: float, head_right: bool) -> PackedVector2Array:
	var dense := PackedVector2Array()
	for k in 401:
		var u := float(k) / 400.0
		if head_right:
			u = 1.0 - u
		dense.append(Vector2(lerpf(a, b, u), _wave_y(u, a_, waves)))
	var out := PackedVector2Array()
	var acc := 0.0
	var idx := 0
	var cur := dense[0]
	for i in count:
		var target := i * spacing
		while idx < dense.size() - 1 and acc + cur.distance_to(dense[idx + 1]) < target:
			acc += cur.distance_to(dense[idx + 1])
			idx += 1
			cur = dense[idx]
		if idx >= dense.size() - 1:
			out.append(cur)
		else:
			var nxt := dense[idx + 1]
			var l := cur.distance_to(nxt)
			out.append(cur.lerp(nxt, (target - acc) / l if l > 0.0001 else 0.0))
	return out


func _draw() -> void:
	if not jammed:
		return
	for side in [x0, x1]:
		for k in 3:
			var y: float = jam_y - 16.0 + k * 16.0
			var dx := 10.0 if side == x0 else -10.0
			draw_line(Vector2(side + dx, y), Vector2(side + dx * 2.0, y - 4.0), Color("ffffff"), 2.0)
