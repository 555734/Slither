class_name GraveLayer
extends Node2D
## 失敗した場所に残る葉っぱの墓標。どの部位がやられたかを示す（企画書 6.5）。

var graves: Array = []


func add(pos: Vector2, part: String) -> void:
	graves.append({"pos": pos, "part": part})
	queue_redraw()


func clear_all() -> void:
	graves.clear()
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for g in graves:
		var p: Vector2 = g.pos
		var leaf := PackedVector2Array([p + Vector2(0, -16), p + Vector2(10, -4), p + Vector2(0, 10), p + Vector2(-10, -4)])
		draw_colored_polygon(leaf, Color(0.4, 0.6, 0.3, 0.7))
		draw_line(p + Vector2(0, -16), p + Vector2(0, 10), Color(0.2, 0.35, 0.15, 0.8), 1.5)
		var letter := "頭" if g.part == "あたま" else ("尻" if g.part == "おしり" else "中")
		draw_string(font, p + Vector2(-8, -20), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.1, 0.1, 0.8))
