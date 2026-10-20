class_name PaperBridge
extends Trap
## #06 紙の葉っぱ橋：体の真ん中が乗ったところで破れる。
## 頭が向こう岸に届いていれば、体がハンモックになって助かる（支持ルールの救済）。

var rect := Rect2()
var solid: Solid
var torn := false
var torn_t := 0.0


func setup(st: Stage, r: Rect2) -> PaperBridge:
	stage = st
	rect = r
	solid = st.solid(r, Solid.Mat.PAPER)
	trap_id = "paper_bridge"
	return self


func reset() -> void:
	torn = false
	torn_t = 0.0
	solid.set_active(true)
	queue_redraw()


func tick(dt: float, cat: Caterpillar) -> void:
	if torn:
		torn_t += dt
		queue_redraw()
		return
	if not cat.is_alive():
		return
	var mid := cat.n / 2
	var p := cat.seg[mid]
	if absf(p.x - rect.get_center().x) < 14.0 and p.y <= rect.position.y + 2.0 and p.y >= rect.position.y - 30.0:
		torn = true
		torn_t = 0.0
		solid.set_active(false)
		cat.jolt()
		queue_redraw()


func _draw() -> void:
	if not torn:
		return
	# 破れた紙が両岸からぶら下がって揺れる
	var swing := sin(torn_t * 6.0) * 0.15 * exp(-torn_t)
	var half := rect.size.x * 0.35
	for side in [0, 1]:
		var anchor := rect.position if side == 0 else Vector2(rect.end.x, rect.position.y)
		var dir := Vector2.DOWN.rotated(swing if side == 0 else -swing)
		var across := Vector2.RIGHT if side == 0 else Vector2.LEFT
		var pts := PackedVector2Array([anchor, anchor + across * 10.0, anchor + dir * half + across * 4.0, anchor + dir * half * 0.8])
		draw_colored_polygon(pts, Solid.COLORS[Solid.Mat.PAPER][0])
		draw_polyline(pts, Color("2e7d32"), 1.5)
