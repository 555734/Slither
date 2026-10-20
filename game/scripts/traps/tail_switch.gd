class_name TailSwitch
extends Trap
## #19 しっぽ離しスイッチ：踏んでも何も起きない。最後の節が離れた瞬間に作動し、
## 後ろから大玉が転がってくる。大玉は先の穴に落ちて栓になる（罠のおさがり）。

var rect := Rect2()
var floor_y := 0.0
var start_x := 0.0
var pit_x0 := 0.0
var pit_x1 := 0.0
var radius := 35.0
var speed := 230.0
var plug: Solid

var occupied := false
var fired := false
var rolling := false
var falling := false
var plugged := false
var ball := Vector2.ZERO
var vy := 0.0
var spin := 0.0


func setup(st: Stage, r: Rect2, fy: float, boulder_start_x: float, px0: float, px1: float) -> TailSwitch:
	stage = st
	rect = r
	floor_y = fy
	start_x = boulder_start_x
	pit_x0 = px0
	pit_x1 = px1
	plug = st.solid(Rect2(px0, fy, px1 - px0, radius * 2.0), Solid.Mat.STONE)
	plug.visible = false
	trap_id = "tail_switch"
	reset()
	return self


func reset() -> void:
	occupied = false
	fired = false
	rolling = false
	falling = false
	plugged = false
	ball = Vector2(start_x, floor_y - radius)
	vy = 0.0
	spin = 0.0
	if plug:
		plug.set_active(false)
	queue_redraw()


func tick(dt: float, cat: Caterpillar) -> void:
	if not fired and cat.is_alive():
		var occ := cat.count_on_top(Rect2(rect.position.x, rect.position.y, rect.size.x, rect.size.y)) > 0
		if occupied and not occ:
			fired = true
			rolling = true
		occupied = occ
	if rolling:
		ball.x += speed * dt
		spin += speed * dt / radius
		if ball.x >= pit_x0 + radius:
			rolling = false
			falling = true
	elif falling:
		vy += Params.GRAVITY * dt
		ball.y += vy * dt
		ball.x = move_toward(ball.x, (pit_x0 + pit_x1) / 2.0, 120.0 * dt)
		if ball.y >= floor_y + radius:
			ball.y = floor_y + radius
			falling = false
			plugged = true
			plug.set_active(true)
			plug.visible = false
	if (rolling or falling) and cat.is_alive():
		var idx := cat.first_hit_circle(ball, radius)
		if idx >= 0:
			cat.kill("大玉", idx, "ぺちゃんこ！", "squash")
	queue_redraw()


func _draw() -> void:
	var pressed := occupied
	var top := rect.position.y + (6.0 if pressed else 0.0)
	draw_rect(Rect2(rect.position.x, top, rect.size.x, rect.end.y - top), Color("ef5350") if not fired else Color("9e9e9e"))
	draw_rect(Rect2(rect.position.x - 6, rect.end.y - 4, rect.size.x + 12, 4), Color("616161"))
	if fired or plugged:
		draw_circle(ball, radius, Color("8d8d8d"))
		draw_arc(ball, radius, 0, TAU, 32, Color("5a5a5a"), 3.0)
		for k in 3:
			var a := spin + k * TAU / 3.0
			draw_line(ball + Vector2.from_angle(a) * radius * 0.3, ball + Vector2.from_angle(a) * radius * 0.8, Color("6d6d6d"), 3.0)
