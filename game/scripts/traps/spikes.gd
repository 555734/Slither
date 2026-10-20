class_name Spikes
extends Trap
## 即死のトゲ。どの節が触れても失敗。

var rect := Rect2()
var up := true


func setup(r: Rect2, pointing_up: bool = true) -> Spikes:
	rect = r
	up = pointing_up
	trap_id = "spikes"
	return self


func tick(_dt: float, cat: Caterpillar) -> void:
	if not cat.is_alive():
		return
	var idx := cat.first_hit_rect(rect)
	if idx >= 0:
		cat.kill("トゲ", idx, "トゲ！")


func _draw() -> void:
	var w := 18.0
	var x := rect.position.x
	draw_rect(Rect2(rect.position.x, rect.end.y - 4 if up else rect.position.y, rect.size.x, 4), Color("6d1b1b"))
	while x < rect.end.x - 1.0:
		var xe := minf(x + w, rect.end.x)
		var pts: PackedVector2Array
		if up:
			pts = PackedVector2Array([Vector2(x, rect.end.y), Vector2(xe, rect.end.y), Vector2((x + xe) / 2.0, rect.position.y)])
		else:
			pts = PackedVector2Array([Vector2(x, rect.position.y), Vector2(xe, rect.position.y), Vector2((x + xe) / 2.0, rect.end.y)])
		draw_colored_polygon(pts, Color("e53935"))
		draw_polyline(PackedVector2Array([pts[0], pts[2], pts[1]]), Color("8e1c1c"), 1.5)
		x += w
