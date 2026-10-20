class_name Checkpoint
extends Trap
## チェックポイント（葉っぱの寝袋）。絶対に罠にしない（企画書 6.2）。

var rect := Rect2()
var spawn_pos := Vector2.ZERO
var spawn_dir := Vector2.RIGHT
var reached := false


func setup(r: Rect2, head_pos: Vector2, dir: Vector2 = Vector2.RIGHT) -> Checkpoint:
	rect = r
	spawn_pos = head_pos
	spawn_dir = dir
	trap_id = "checkpoint"
	return self


func tick(_dt: float, cat: Caterpillar) -> void:
	if reached or not cat.is_alive():
		return
	if rect.has_point(cat.head()):
		reached = true
		stage.set_respawn(spawn_pos, spawn_dir)
		queue_redraw()


func _draw() -> void:
	var base := Vector2(rect.get_center().x, rect.end.y)
	draw_line(base, base + Vector2(0, -70), Color("5e3a1a"), 4.0)
	var col := Color("ffd54f") if reached else Color("c8e6c9")
	var flag := PackedVector2Array([base + Vector2(0, -70), base + Vector2(40, -58), base + Vector2(0, -46)])
	draw_colored_polygon(flag, col)
	draw_polyline(flag, Color("33691e"), 2.0)
