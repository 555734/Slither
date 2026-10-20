class_name SignBoard
extends Trap
## 看板（飾り。ただし書いてあることが本当のこともある）。

var pos := Vector2.ZERO
var text := ""
var width := 120.0


func setup(p: Vector2, t: String, w: float = 120.0) -> SignBoard:
	pos = p
	text = t
	width = w
	trap_id = "sign"
	return self


func _draw() -> void:
	draw_line(pos, pos + Vector2(0, -60), Color("6d4c2f"), 5.0)
	var board := Rect2(pos + Vector2(-width / 2.0, -100), Vector2(width, 44))
	draw_rect(board, Color("f3e2c0"))
	draw_rect(board, Color("6d4c2f"), false, 3.0)
	var font := ThemeDB.fallback_font
	draw_string(font, board.position + Vector2(0, 30), text, HORIZONTAL_ALIGNMENT_CENTER, width, 20, Color("3e2723"))
