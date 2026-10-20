class_name Earwig
extends Trap
## #16 背後のハサミムシ：画面外の後ろから尻尾を追いかけ、3節ずつチョキン。
## 尻尾が動いている間だけ追う。止まってしばらくすると、あきらめて帰っていく。

enum S { INACTIVE, CHASE, RETREAT, LEAVING, GONE }

var floor_y := 0.0
var act_x := 0.0
var end_x := 0.0
var state: int = S.INACTIVE
var x := 0.0
var t := 0.0
var retreat_to := 0.0
var walk := 0.0
var snips := 0


func setup(fy: float, activate_x: float, give_up_x: float) -> Earwig:
	floor_y = fy
	act_x = activate_x
	end_x = give_up_x
	trap_id = "earwig"
	return self


func reset() -> void:
	state = S.INACTIVE
	x = 0.0
	t = 0.0
	snips = 0
	queue_redraw()


func _tail_on_floor(cat: Caterpillar) -> bool:
	return absf(cat.tail().y - (floor_y - Params.BODY_RADIUS)) < 20.0


func tick(dt: float, cat: Caterpillar) -> void:
	t += dt
	match state:
		S.INACTIVE:
			if cat.is_alive() and cat.head().x > act_x:
				state = S.CHASE
				x = cat.tail().x - 380.0
		S.CHASE:
			if not cat.is_alive():
				pass
			elif cat.tail().x > end_x:
				state = S.LEAVING
				t = 0.0
			elif cat.stopped_t >= 0.6:
				state = S.LEAVING  # 止まると、あきらめる
				t = 0.0
			elif _tail_on_floor(cat):
				var target := cat.tail().x - Params.BODY_RADIUS
				x = move_toward(x, target, 400.0 * dt)
				walk += dt
				if absf(x - target) < 6.0:
					snips += 1
					cat.cut(cat.n - 3, "ハサミムシ", "おしりチョキン！")
					state = S.RETREAT
					retreat_to = x - 60.0
					t = 0.0
		S.RETREAT:
			x = move_toward(x, retreat_to, 260.0 * dt)
			walk += dt
			if t > 0.4:
				state = S.CHASE
		S.LEAVING:
			x -= 250.0 * dt
			walk += dt
			if t > 2.5:
				state = S.GONE
	queue_redraw()


func _draw() -> void:
	if state == S.INACTIVE or state == S.GONE:
		return
	var facing := -1.0 if state == S.LEAVING else 1.0
	var c := Vector2(x, floor_y - 12.0)
	# 体
	for k in 3:
		draw_circle(c - Vector2(facing * k * 14.0, 0), 11.0 - k, Color("5d4037"))
	draw_circle(c + Vector2(facing * 12.0, -2), 8.0, Color("3e2723"))
	# はさみ
	var tip := c + Vector2(facing * 22.0, -2)
	var open := 0.4 + 0.3 * sin(t * 14.0)
	for s in [-1.0, 1.0]:
		draw_line(tip, tip + Vector2(facing * 16.0, s * 9.0 * open), Color("d84315"), 3.0)
	# 足
	for k in 3:
		var lx := c.x - facing * k * 14.0
		var ph := sin(walk * 20.0 + k) * 4.0
		draw_line(Vector2(lx, c.y + 6), Vector2(lx + ph, floor_y), Color("3e2723"), 2.0)
	# 画面外から迫っているときの警告（伏線）
	var cam := get_viewport().get_camera_2d()
	if cam and state == S.CHASE:
		var half := get_viewport_rect().size / cam.zoom / 2.0
		var left := cam.get_screen_center_position().x - half.x
		if x < left:
			var p := Vector2(left + 26.0, c.y - 30.0)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-14, 0), p + Vector2(6, -12), p + Vector2(6, 12)]), Color(1, 0.3, 0.2, 0.5 + 0.5 * sin(t * 12.0)))
			draw_string(ThemeDB.fallback_font, p + Vector2(10, 6), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("d84315"))
