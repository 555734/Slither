class_name FakeFloor
extends Trap
## #07 書き割り床：前景の地面に見えるが、背景に描かれた絵。当たり判定が無い。
## 伏線：ここに生えている草だけ、ほんの少し青みがかっている。

var rect := Rect2()


func setup(r: Rect2) -> FakeFloor:
	rect = r
	trap_id = "fake_floor"
	return self


func _draw() -> void:
	var cols: Array = Solid.COLORS[Solid.Mat.BARK]
	draw_rect(rect, cols[0])
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 6)), cols[1])
	var gx := rect.position.x + 6.0
	var i := 0
	while gx < rect.end.x - 4.0:
		var h := 5.0 + float((i * 7) % 5)
		draw_line(Vector2(gx, rect.position.y), Vector2(gx - 2, rect.position.y - h), Color("3f8f6a"), 2.0)
		gx += 17.0 + float((i * 5) % 9)
		i += 1
