class_name PlankBridge
extends Trap
## #01 定員オーバー橋：看板の「定員 5ふし」は本当だった。
## 板の上に乗っている節が定員を超えるとバキッと割れる。

var rect := Rect2()
var capacity := 5
var solid: Solid
var broken := false
var on_count := 0


func setup(st: Stage, r: Rect2, cap: int = 5) -> PlankBridge:
	stage = st
	rect = r
	capacity = cap
	solid = st.solid(r, Solid.Mat.PLANK)
	trap_id = "plank_bridge"
	return self


func reset() -> void:
	broken = false
	on_count = 0
	solid.set_active(true)
	solid.fall_spin = 0.0
	queue_redraw()


func tick(_dt: float, cat: Caterpillar) -> void:
	if broken or not cat.is_alive():
		return
	# 板の端の継ぎ目に乗っている節は数えない
	on_count = cat.count_on_top(rect.grow_individual(-4.0, 0.0, -4.0, 0.0))
	if on_count > capacity:
		broken = true
		solid.fall_spin = 0.6
		solid.set_active(false, true)
	queue_redraw()


func _draw() -> void:
	if broken:
		return
	# 乗っている節の数だけ板がしなる（伏線）
	if on_count > 0:
		var sag := 2.0 * on_count
		draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.get_center().x, rect.end.y + sag), Color("7a4f25"), 3.0)
		draw_line(Vector2(rect.get_center().x, rect.end.y + sag), Vector2(rect.end.x, rect.end.y), Color("7a4f25"), 3.0)
