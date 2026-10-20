class_name CameraRig
extends Camera2D
## 進行方向を先読みし、止まると少し引いて尻尾側も見せる（企画書 4.4）。
## 失敗時は犯人カメラとして、当たった節に寄る。

var lead := Vector2.ZERO
var focus_active := false
var focus_pos := Vector2.ZERO
var base_zoom := 1.15


func setup_limits(b: Rect2) -> void:
	limit_left = int(b.position.x)
	limit_top = int(b.position.y)
	limit_right = int(b.end.x)
	limit_bottom = int(b.end.y)


func snap_to(cat: Caterpillar) -> void:
	lead = Vector2.ZERO
	position = cat.centroid()
	zoom = Vector2.ONE * base_zoom
	reset_smoothing()


func focus_at(p: Vector2) -> void:
	focus_active = true
	focus_pos = p


func release() -> void:
	focus_active = false


func follow(cat: Caterpillar, dt: float) -> void:
	var target_zoom := base_zoom
	var desired: Vector2
	if focus_active:
		desired = focus_pos
		target_zoom = base_zoom * 1.6
	else:
		var target_lead := lead
		if cat.moving:
			target_lead = Vector2.from_angle(cat.heading) * cat.body_len() * 0.6
		elif cat.stopped_t > 0.25 or cat.state == Caterpillar.State.FALL:
			target_lead = cat.centroid() - cat.head()
			if cat.stopped_t > 0.25:
				target_zoom = base_zoom * 0.8
		lead = lead.lerp(target_lead, 1.0 - exp(-dt * 3.0))
		desired = cat.head() + lead if cat.n > 0 else position
	var k := 1.0 - exp(-dt * (10.0 if focus_active else 6.0))
	position = position.lerp(desired, k)
	var z := lerpf(zoom.x, target_zoom, 1.0 - exp(-dt * (8.0 if focus_active else 2.5)))
	zoom = Vector2(z, z)
