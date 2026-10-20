class_name DebugDraw
extends Node2D
## デバッグ表示：軌跡、各節の支え（緑=支えあり、赤=空中）、節番号、支持ルールの値。

var cat: Caterpillar


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if cat == null or cat.n == 0:
		return
	var poly := cat.trail.pts.duplicate()
	poly.append(cat.trail.head)
	if poly.size() >= 2:
		draw_polyline(poly, Color(1, 1, 0, 0.6), 2.0)
	var font := ThemeDB.fallback_font
	for i in cat.n:
		var supported: bool = i < cat.sup.size() and cat.sup[i]
		draw_arc(cat.seg[i], Params.BODY_RADIUS + Params.CONTACT_MARGIN, 0, TAU, 16, Color(0, 1, 0, 0.9) if supported else Color(1, 0, 0, 0.9), 2.0)
		draw_string(font, cat.seg[i] + Vector2(-6, -16), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLACK)
	var r := cat.rule
	if not r.is_empty():
		var txt := "head:%d tail:%d mid:%d %s" % [r.head_run, r.tail_run, r.mid_max, "OK" if r.ok else "NG"]
		draw_string(font, cat.head() + Vector2(-60, -50), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.BLACK)
