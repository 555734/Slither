class_name TouchStick
extends Control
## フローティングスティック（企画書 4.2）：画面下部のどこでも指を置いてドラッグ。
## 方向＝頭の目標方向、距離＝速度（2段階）、指を離すと停止。右下の「↩」は押している間だけ後ずさり。

const DEADZONE := 12.0
const FAST_DIST := 60.0
const FOLLOW := 120.0
const BACK_R := 62.0

var stick_index := -1
var origin := Vector2.ZERO
var cur := Vector2.ZERO
var back_index := -1
var enabled := true
var touched_once := false
var show_hint := false
var hint_t := 0.0
var fast_flash := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _screen() -> Vector2:
	return get_viewport_rect().size


func back_center() -> Vector2:
	var s := _screen()
	return Vector2(s.x - 100.0, s.y - 170.0)


func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			if not enabled:
				return
			if e.position.distance_to(back_center()) < BACK_R:
				back_index = e.index
			elif e.position.y >= _screen().y * 0.35 and stick_index == -1:
				stick_index = e.index
				origin = e.position
				cur = e.position
				touched_once = true
		else:
			if e.index == stick_index:
				stick_index = -1
			if e.index == back_index:
				back_index = -1
		queue_redraw()
	elif e is InputEventScreenDrag and e.index == stick_index:
		cur = e.position
		var d := cur - origin
		if d.length() > FOLLOW:
			origin = cur - d.normalized() * FOLLOW
		queue_redraw()


func release_all() -> void:
	stick_index = -1
	back_index = -1
	queue_redraw()


func get_dir() -> Vector2:
	if stick_index < 0:
		return Vector2.ZERO
	var d := cur - origin
	if d.length() < DEADZONE:
		return Vector2.ZERO
	return d.normalized()


func is_fast() -> bool:
	return (cur - origin).length() >= FAST_DIST


func is_back() -> bool:
	return back_index >= 0


## 全速の目盛りを光らせる（文字を使わないヒント）
func flash_fast() -> void:
	fast_flash = 2.0


func _process(delta: float) -> void:
	hint_t += delta
	if fast_flash > 0.0:
		fast_flash -= delta
	if (show_hint and not touched_once) or fast_flash > 0.0 or stick_index >= 0:
		queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var bc := back_center()
	draw_circle(bc, BACK_R, Color(1, 1, 1, 0.45 if back_index >= 0 else 0.25))
	draw_arc(bc, BACK_R, 0, TAU, 32, Color(0.2, 0.3, 0.2, 0.6), 3.0)
	draw_string(font, bc + Vector2(-22, 14), "↩", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(0.15, 0.25, 0.15, 0.9))
	if stick_index >= 0:
		draw_arc(origin, FOLLOW, 0, TAU, 40, Color(1, 1, 1, 0.35), 3.0)
		var flash := fast_flash > 0.0 and fmod(fast_flash, 0.4) < 0.2
		draw_arc(origin, FAST_DIST, 0, TAU, 32, Color(1, 0.85, 0.2, 0.9) if flash else Color(1, 1, 1, 0.5), 5.0 if flash else 2.0)
		draw_circle(origin, DEADZONE, Color(1, 1, 1, 0.3))
		draw_circle(cur, 30.0, Color(1, 1, 1, 0.55))
	elif fast_flash > 0.0:
		var c := Vector2(_screen().x / 2.0, _screen().y * 0.75)
		if fmod(fast_flash, 0.4) < 0.2:
			draw_arc(c, FAST_DIST, 0, TAU, 32, Color(1, 0.85, 0.2, 0.9), 5.0)
	if show_hint and not touched_once:
		var u := fmod(hint_t, 2.0) / 2.0
		var start := Vector2(_screen().x * 0.3, _screen().y * 0.75)
		var p := start + Vector2(_screen().x * 0.35 * minf(u * 1.4, 1.0), 0)
		draw_arc(start, FOLLOW * 0.5, 0, TAU, 32, Color(1, 1, 1, 0.4), 3.0)
		draw_circle(p, 26.0, Color(1, 1, 1, 0.7 * (1.0 - u * 0.5)))
		draw_arc(p, 26.0, 0, TAU, 24, Color(0.2, 0.2, 0.2, 0.3), 3.0)
