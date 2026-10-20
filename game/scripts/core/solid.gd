class_name Solid
extends Node2D
## 地形の矩形。素材で「つかめる/つかめない」が決まる（企画書 5.4）。
## 床（上向きの面）は素材に関係なく支えになり、壁と天井は grip な素材だけが支えになる。

enum Mat { BARK, LEAF, GLASS, PAPER, PLANK, STONE, TWIG }

const COLORS := {
	Mat.BARK: [Color("8b5a2b"), Color("a8743f"), Color("5e3a1a")],
	Mat.LEAF: [Color("4caf50"), Color("7ccf6a"), Color("2e7d32")],
	Mat.GLASS: [Color(0.75, 0.92, 1.0, 0.45), Color(1, 1, 1, 0.8), Color(0.45, 0.7, 0.85, 0.9)],
	Mat.PAPER: [Color("52b356"), Color("7ccf6a"), Color("2e7d32")],
	Mat.PLANK: [Color("c58b4f"), Color("deaa6f"), Color("7a4f25")],
	Mat.STONE: [Color("8d8d8d"), Color("b0b0b0"), Color("5a5a5a")],
	Mat.TWIG: [Color("7a5230"), Color("9c6e44"), Color("4f321a")],
}

var rect := Rect2()
var mat: int = Mat.BARK
var grip := true
var active := true
## 落下アニメーション用（当たり判定には影響しない）
var fall_time := -1.0
var fall_spin := 0.0
var grass := true


func setup(r: Rect2, m: int) -> Solid:
	rect = r
	mat = m
	grip = m != Mat.GLASS and m != Mat.STONE
	return self


func set_active(on: bool, animate_fall: bool = false) -> void:
	active = on
	if on:
		fall_time = -1.0
		visible = true
	elif animate_fall:
		fall_time = 0.0
	else:
		visible = false
	queue_redraw()


func _process(delta: float) -> void:
	if fall_time >= 0.0:
		fall_time += delta
		if fall_time > 1.5:
			fall_time = -1.0
			visible = false
		queue_redraw()


func _draw() -> void:
	var r := rect
	var cols: Array = COLORS[mat]
	if fall_time >= 0.0:
		var drop := 0.5 * 1400.0 * fall_time * fall_time
		draw_set_transform(r.get_center() + Vector2(0, drop), fall_spin * fall_time, Vector2.ONE)
		r = Rect2(-r.size / 2.0, r.size)
	if mat == Mat.LEAF and r.size.y > 40.0:
		# 大きな葉の足場は、樹皮の土台の上に葉が乗っている見た目にする
		draw_rect(r, COLORS[Mat.BARK][0])
		r = Rect2(r.position, Vector2(r.size.x, 24.0))
	draw_rect(r, cols[0])
	match mat:
		Mat.GLASS:
			draw_rect(r, cols[2], false, 2.0)
			var step := 40.0
			var x := r.position.x + 8.0
			while x < r.end.x - 6.0:
				draw_line(Vector2(x, r.position.y + 6), Vector2(minf(x + 14, r.end.x - 2), r.position.y + 30), cols[1], 2.0)
				x += step
		Mat.PLANK:
			var x2 := r.position.x
			while x2 < r.end.x:
				draw_line(Vector2(x2, r.position.y), Vector2(x2, r.end.y), cols[2], 1.5)
				x2 += 22.0
			draw_rect(r, cols[2], false, 2.0)
		Mat.STONE:
			draw_rect(r, cols[2], false, 2.0)
		_:
			# 上面のハイライトと草
			var top := Rect2(r.position, Vector2(r.size.x, minf(6.0, r.size.y)))
			draw_rect(top, cols[1])
			if grass and (mat == Mat.BARK or mat == Mat.LEAF) and r.size.x > 30 and fall_time < 0.0:
				var gx := r.position.x + 6.0
				var i := 0
				while gx < r.end.x - 4.0:
					var h := 5.0 + float((i * 7) % 5)
					draw_line(Vector2(gx, r.position.y), Vector2(gx - 2, r.position.y - h), Color("3f9a3a"), 2.0)
					gx += 17.0 + float((i * 5) % 9)
					i += 1
			if mat == Mat.LEAF or mat == Mat.PAPER:
				draw_line(Vector2(r.position.x + 4, r.get_center().y), Vector2(r.end.x - 4, r.get_center().y), cols[2], 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
