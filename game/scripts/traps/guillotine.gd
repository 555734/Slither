class_name Guillotine
extends Trap
## #17 頭センサーのギロチン：頭が赤い光線を横切ると delay 秒後に刃が落ちる。
## 頭はもう通り過ぎているので、落ちるのは体の真ん中。
## 対策：頭だけ光線に突っ込んで、すぐ後ずさり（フェイント）。刃は床に沈み、down_time 秒は止まったまま。

enum S { ARMED, DELAY, DROP, DOWN, RISE }

var beam_x := 0.0
var beam_top := 0.0
var beam_bottom := 0.0
var blade_x := 0.0
var blade_top := 0.0
var floor_y := 0.0
var delay := 0.4
var drop_time := 0.12
var down_time := 3.0
var rise_time := 0.5
var state: int = S.ARMED
var t := 0.0
var anim := 0.0


func setup(bx: float, btop: float, bbottom: float, blx: float, bltop: float, fy: float, delay_sec: float = 0.4) -> Guillotine:
	delay = delay_sec
	beam_x = bx
	beam_top = btop
	beam_bottom = bbottom
	blade_x = blx
	blade_top = bltop
	floor_y = fy
	trap_id = "guillotine"
	return self


func reset() -> void:
	state = S.ARMED
	t = 0.0
	queue_redraw()


func _height() -> float:
	return floor_y - blade_top


## 刃の下端のy座標
func _bottom() -> float:
	var h := _height()
	match state:
		S.DROP:
			return lerpf(blade_top, floor_y + h, minf(1.0, t / drop_time))
		S.DOWN:
			return floor_y + h
		S.RISE:
			return lerpf(floor_y + h, blade_top, minf(1.0, t / rise_time))
	return blade_top


func blade_rect() -> Rect2:
	var h := _height()
	return Rect2(blade_x - 12.0, _bottom() - h, 24.0, h)


func tick(dt: float, cat: Caterpillar) -> void:
	t += dt
	anim += dt
	match state:
		S.ARMED:
			if cat.is_alive():
				var a := cat.prev_head
				var b := cat.head()
				var crossed := (a.x < beam_x and b.x >= beam_x) or (a.x > beam_x and b.x <= beam_x)
				if crossed and b.y >= beam_top and b.y <= beam_bottom:
					state = S.DELAY
					t = 0.0
		S.DELAY:
			if t >= delay:
				state = S.DROP
				t = 0.0
		S.DROP:
			_cut_check(cat)
			if t >= drop_time:
				state = S.DOWN
				t = 0.0
		S.DOWN:
			if t >= down_time:
				state = S.RISE
				t = 0.0
		S.RISE:
			_cut_check(cat)
			if t >= rise_time:
				state = S.ARMED
				t = 0.0
	queue_redraw()


func _cut_check(cat: Caterpillar) -> void:
	if not cat.is_alive():
		return
	var r := blade_rect()
	# 床より上の部分だけが刃として危険
	r = r.intersection(Rect2(r.position.x, blade_top, r.size.x, floor_y - blade_top))
	if r.size.y <= 0.0:
		return
	var idx := cat.first_hit_rect(r)
	if idx >= 0:
		cat.cut(idx, "ギロチン", "まっぷたつ！")


func _draw() -> void:
	# センサーと光線（伏線：赤いランプが点滅している）
	var lamp_on := state == S.ARMED and fmod(anim, 1.0) < 0.6
	draw_rect(Rect2(beam_x - 10, beam_top - 4, 20, 12), Color("424242"))
	draw_circle(Vector2(beam_x, beam_top + 8), 5.0, Color("ff1744") if lamp_on or state == S.DELAY else Color("7f0000"))
	if state == S.ARMED or state == S.DELAY:
		var y := beam_top + 14.0
		var col := Color(1, 0.1, 0.1, 0.35 if state == S.ARMED else 0.8)
		while y < beam_bottom:
			draw_line(Vector2(beam_x, y), Vector2(beam_x, minf(y + 8.0, beam_bottom)), col, 2.0)
			y += 14.0
	# 天井の刃の差し込み口
	draw_rect(Rect2(blade_x - 16, blade_top - 6, 32, 6), Color("37474f"))
	# 刃は通路の中に出ている部分だけを描く（天井と床の中は見えない）
	var r := blade_rect().intersection(Rect2(blade_x - 20, blade_top, 40, floor_y - blade_top))
	if r.size.y > 0.5:
		draw_rect(r, Color("cfd8dc"))
		var edge_y := blade_rect().end.y
		if edge_y <= floor_y:
			draw_rect(Rect2(r.position.x, edge_y - 8, r.size.x, 8), Color("eceff1"))
		draw_rect(r, Color("607d8b"), false, 2.0)
