class_name CrumbleBridge
extends Trap
## 崩れる足場。上に need 節以上が乗ると delay 秒後に崩れる。
## respawn > 0 なら、その秒数後に元に戻る（試験場用）。

var rect := Rect2()
var need := 1
var delay := 0.5
var respawn := -1.0
var solid: Solid
var crack_t := -1.0
var gone_t := -1.0


func setup(st: Stage, r: Rect2, need_count: int, crumble_delay: float, respawn_after: float = -1.0, mat: int = Solid.Mat.TWIG) -> CrumbleBridge:
	stage = st
	rect = r
	need = need_count
	delay = crumble_delay
	respawn = respawn_after
	solid = st.solid(r, mat)
	trap_id = "crumble"
	return self


func reset() -> void:
	crack_t = -1.0
	gone_t = -1.0
	solid.set_active(true)
	queue_redraw()


func tick(dt: float, cat: Caterpillar) -> void:
	if gone_t >= 0.0:
		gone_t += dt
		if respawn > 0.0 and gone_t >= respawn and cat.first_hit_rect(rect, Params.BODY_RADIUS) < 0:
			reset()
		return
	if crack_t >= 0.0:
		crack_t += dt
		if crack_t >= delay:
			solid.fall_spin = 0.3
			solid.set_active(false, true)
			gone_t = 0.0
			crack_t = -1.0
		queue_redraw()
		return
	if cat.is_alive() and cat.count_on_top(rect) >= need:
		crack_t = 0.0
		queue_redraw()


func _draw() -> void:
	if crack_t < 0.0:
		return
	var shake := sin(crack_t * 60.0) * 1.5
	var x := rect.position.x + 14.0
	while x < rect.end.x - 6.0:
		draw_line(Vector2(x + shake, rect.position.y), Vector2(x + 6 + shake, rect.end.y), Color("212121"), 2.0)
		x += 28.0
