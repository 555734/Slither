class_name ClamGoal
extends Trap
## #22 変種「ハマグリの扉」：ゴールの巣穴の入口がハマグリ。
## 頭が巣穴に入ってから close_delay 秒で閉じる。そのとき入口に節があれば、おしりが挟まる。

enum S { OPEN, TIMING, CLOSING, DONE, REOPEN }

var interior := Rect2()
var mouth := Rect2()
var close_delay := 1.25
var state: int = S.OPEN
var t := 0.0
var close_amount := 0.0


func setup(r_interior: Rect2, r_mouth: Rect2, delay: float = 1.25) -> ClamGoal:
	interior = r_interior
	mouth = r_mouth
	close_delay = delay
	trap_id = "clam_goal"
	return self


func reset() -> void:
	state = S.OPEN
	t = 0.0
	close_amount = 0.0
	queue_redraw()


func tick(dt: float, cat: Caterpillar) -> void:
	t += dt
	match state:
		S.OPEN:
			if cat.is_alive() and interior.has_point(cat.head()):
				state = S.TIMING
				t = 0.0
		S.TIMING:
			if cat.state == Caterpillar.State.CRAWL and cat.all_inside(interior):
				stage.clear()
				state = S.CLOSING
				t = 0.0
			elif t >= close_delay:
				state = S.CLOSING
				t = 0.0
				_snap(cat)
		S.CLOSING:
			close_amount = minf(1.0, t / 0.1)
			if close_amount >= 1.0:
				state = S.DONE if stage.cleared else S.REOPEN
				t = 0.0
		S.REOPEN:
			close_amount = maxf(0.0, 1.0 - (t - 1.0) / 0.3)
			if t > 1.3:
				state = S.OPEN
				close_amount = 0.0
	queue_redraw()


func _snap(cat: Caterpillar) -> void:
	if not cat.is_alive():
		return
	var pinched := -1
	for i in cat.n:
		if World.circle_hits_rect(mouth, cat.seg[i], Params.HIT_RADIUS):
			pinched = i
	if pinched >= 0:
		cat.kill("ハマグリ", pinched, "おしりがはさまった！", "pinch")


func _draw() -> void:
	draw_rect(interior, Color(0.18, 0.11, 0.06, 0.85))
	var c := close_amount
	var cx := mouth.get_center().x
	var rx := mouth.size.x * 0.75
	var ry := mouth.size.y * 0.7
	var top_y := lerpf(mouth.position.y - 4.0, mouth.get_center().y, c)
	var bot_y := lerpf(mouth.end.y + 4.0, mouth.get_center().y, c)
	_shell(Vector2(cx, top_y), rx, ry, true)
	_shell(Vector2(cx, bot_y), rx, ry, false)
	var flag_base := Vector2(interior.position.x + 40, interior.position.y - 100)
	draw_line(flag_base, flag_base + Vector2(0, -60), Color("5e3a1a"), 4.0)
	var flag := PackedVector2Array([flag_base + Vector2(0, -60), flag_base + Vector2(46, -48), flag_base + Vector2(0, -36)])
	draw_colored_polygon(flag, Color("ff7043"))
	draw_string(ThemeDB.fallback_font, flag_base + Vector2(-22, -66), "GOAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)


func _shell(center: Vector2, rx: float, ry: float, upper: bool) -> void:
	var pts := PackedVector2Array()
	var sgn := -1.0 if upper else 1.0
	for k in 17:
		var a := PI * float(k) / 16.0
		pts.append(center + Vector2(-cos(a) * rx, sgn * sin(a) * ry))
	draw_colored_polygon(pts, Color("f6e7d0"))
	draw_polyline(pts, Color("a1887f"), 2.5)
	for k in range(1, 5):
		var a2 := PI * float(k) / 5.0
		draw_line(center, center + Vector2(-cos(a2) * rx, sgn * sin(a2) * ry), Color("d7ccc8"), 1.5)
	draw_line(center - Vector2(rx, 0), center + Vector2(rx, 0), Color("8d6e63"), 2.5)
