class_name Stage
extends Node2D
## ステージの基底。地形（Solid）と罠（Trap）を組み立て、リスポーン地点とクリア状態を持つ。

var world := World.new()
var traps: Array[Trap] = []
var stage_id := "stage"
var title := ""
var spawn_pos := Vector2.ZERO
var spawn_dir := Vector2.RIGHT
var respawn_pos := Vector2.ZERO
var respawn_dir := Vector2.RIGHT
var kill_y := 2000.0
var bounds := Rect2(0, 0, 3000, 1500)
var cleared := false
var show_drag_hint := false
var sky_top := Color("7fc2ea")
var sky_bottom := Color("dff3ff")


## サブクラスで地形と罠を組み立てる
func build() -> void:
	pass


func setup() -> void:
	build()
	respawn_pos = spawn_pos
	respawn_dir = spawn_dir


func solid(r: Rect2, m: int = Solid.Mat.BARK) -> Solid:
	var s := Solid.new().setup(r, m)
	add_child(s)
	world.add_solid(s)
	return s


func block(x0: float, y0: float, x1: float, y1: float, m: int = Solid.Mat.BARK) -> Solid:
	return solid(Rect2(x0, y0, x1 - x0, y1 - y0), m)


func add_trap(t: Trap):
	t.stage = self
	add_child(t)
	traps.append(t)
	return t


func sign_at(x: float, y: float, text: String, w: float = 120.0) -> void:
	add_trap(SignBoard.new()).setup(Vector2(x, y), text, w)


func set_respawn(p: Vector2, d: Vector2) -> void:
	respawn_pos = p
	respawn_dir = d


func clear() -> void:
	cleared = true


func reset_traps() -> void:
	cleared = false
	for t in traps:
		t.reset()


func reset_progress() -> void:
	respawn_pos = spawn_pos
	respawn_dir = spawn_dir
	for t in traps:
		if t is Checkpoint:
			t.reached = false
			t.queue_redraw()
	reset_traps()


func tick(dt: float, cat: Caterpillar) -> void:
	for t in traps:
		t.tick(dt, cat)


func _draw() -> void:
	var r := bounds.grow(1200.0)
	var bands := 12
	for k in bands:
		var y0 := lerpf(r.position.y, r.end.y, float(k) / bands)
		var y1 := lerpf(r.position.y, r.end.y, float(k + 1) / bands)
		draw_rect(Rect2(r.position.x, y0, r.size.x, y1 - y0 + 1.0), sky_top.lerp(sky_bottom, float(k) / bands))
	# 画面の下端より下は土で埋める
	draw_rect(Rect2(r.position.x, bounds.end.y - 2.0, r.size.x, 2000.0), Color("5e3a1a"))
	# 遠景の木と雲
	var x := bounds.position.x
	var i := 0
	while x < bounds.end.x:
		var h := 260.0 + float((i * 97) % 180)
		var base_y := bounds.end.y - 420.0
		draw_rect(Rect2(x + 40.0, base_y - h, 26.0, h + 420.0), Color(0.45, 0.62, 0.5, 0.35))
		draw_circle(Vector2(x + 53.0, base_y - h), 90.0, Color(0.45, 0.7, 0.5, 0.3))
		draw_circle(Vector2(x + 200.0, bounds.position.y + 160.0 + float((i * 53) % 120)), 40.0, Color(1, 1, 1, 0.6))
		draw_circle(Vector2(x + 240.0, bounds.position.y + 150.0 + float((i * 53) % 120)), 52.0, Color(1, 1, 1, 0.6))
		x += 420.0
		i += 1
