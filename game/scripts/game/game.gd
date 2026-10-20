class_name Game
extends Node2D
## 1ステージぶんのプレイ進行。
## プレイ → 失敗（ヒットストップ → 犯人カメラ → 死にざま → 1.2秒以内に再開）→ … → クリア。

signal exit_requested
signal next_requested

enum Phase { PLAY, DYING, CLEAR }

const HITSTOP := 0.15
const CULPRIT_END := 0.5
const RESPAWN_AT := 1.2

var stage: Stage
var cat: Caterpillar
var cam: CameraRig
var hud: Hud
var graves: GraveLayer
var debug_draw: DebugDraw
var phase: int = Phase.PLAY
var deaths := 0
var elapsed := 0.0
var life_t := 0.0
var dying_t := 0.0
var skip_requested := false
var clam_deaths := 0
var hint_counts := {}
const HINT_AFTER := 3
## デモ・スクリーンショット用：設定されていればタッチ入力の代わりに呼ばれる
var autopilot := Callable()


func start(stage_script: Script, has_next: bool) -> void:
	stage = stage_script.new()
	add_child(stage)
	stage.setup()
	graves = GraveLayer.new()
	add_child(graves)
	cat = Caterpillar.new()
	cat.world = stage.world
	add_child(cat)
	cat.died.connect(_on_died)
	cat.snipped.connect(_on_snipped)
	debug_draw = DebugDraw.new()
	debug_draw.cat = cat
	debug_draw.z_index = 10
	debug_draw.visible = false
	add_child(debug_draw)
	cam = CameraRig.new()
	add_child(cam)
	cam.setup_limits(stage.bounds)
	cam.make_current()
	hud = Hud.new()
	add_child(hud)
	hud.build(stage.title, has_next)
	hud.stick.show_hint = stage.show_drag_hint
	hud.retry_pressed.connect(_on_retry)
	hud.menu_pressed.connect(func() -> void: exit_requested.emit())
	hud.next_pressed.connect(func() -> void: next_requested.emit())
	hud.restart_pressed.connect(restart_stage)
	hud.debug_toggled.connect(func() -> void: debug_draw.visible = not debug_draw.visible)
	hud.tuning_applied.connect(_on_retry)
	GameLog.write({"event": "start", "stage": stage.stage_id})
	respawn()
	cam.snap_to(cat)


func respawn() -> void:
	stage.reset_traps()
	cat.spawn(stage.respawn_pos, stage.respawn_dir)
	phase = Phase.PLAY
	life_t = 0.0
	skip_requested = false
	cam.release()
	hud.hide_death()


func restart_stage() -> void:
	stage.reset_progress()
	deaths = 0
	elapsed = 0.0
	clam_deaths = 0
	hint_counts.clear()
	hud.hide_hint()
	graves.clear_all()
	hud.hide_clear()
	respawn()
	cam.snap_to(cat)
	GameLog.write({"event": "start", "stage": stage.stage_id})


func _on_retry() -> void:
	if phase == Phase.CLEAR:
		return
	GameLog.write({"event": "retry", "stage": stage.stage_id, "t": snappedf(life_t, 0.01)})
	respawn()


func _physics_process(dt: float) -> void:
	if hud.is_paused():
		return
	match phase:
		Phase.PLAY:
			elapsed += dt
			life_t += dt
			_apply_input()
			cat.step(dt)
			stage.tick(dt, cat)
			_check_kill_plane()
			if stage.cleared and phase == Phase.PLAY:
				_on_clear()
			cam.follow(cat, dt)
		Phase.DYING:
			dying_t += dt
			if dying_t >= CULPRIT_END:
				if not cat.exploded:
					cat.explode()
				cat.step(dt)
			cam.follow(cat, dt)
			if dying_t >= RESPAWN_AT or (skip_requested and dying_t >= 0.4):
				respawn()
		Phase.CLEAR:
			cat.step(dt)
			stage.tick(dt, cat)
			cam.follow(cat, dt)
	hud.set_misses(deaths, elapsed)


func _apply_input() -> void:
	if autopilot.is_valid():
		autopilot.call(self)
		return
	var dir := hud.stick.get_dir()
	var fast := hud.stick.is_fast()
	var back := hud.stick.is_back()
	# デスクトップでの確認用キーボード操作
	var kd := Vector2(
		float(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)))
	if kd != Vector2.ZERO:
		dir = kd.normalized()
		fast = not Input.is_key_pressed(KEY_SHIFT)
	if Input.is_key_pressed(KEY_X) or Input.is_key_pressed(KEY_BACKSPACE):
		back = true
	cat.in_dir = dir
	cat.in_fast = fast
	cat.in_back = back


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_R:
		_on_retry()
	if phase == Phase.DYING and (e is InputEventScreenTouch and e.pressed):
		skip_requested = true


func _check_kill_plane() -> void:
	if not cat.is_alive():
		return
	for i in cat.n:
		if cat.seg[i].y > stage.kill_y:
			cat.kill("奈落", i, "おちた…")
			return


func _on_died(info: Dictionary) -> void:
	deaths += 1
	phase = Phase.DYING
	dying_t = 0.0
	graves.add(info.pos, info.part)
	cam.focus_at(info.pos)
	hud.show_death(info.part, info.text)
	GameLog.write({
		"event": "death", "stage": stage.stage_id, "cause": info.cause, "part": info.part,
		"index": info.index, "x": snappedf(info.pos.x, 1.0), "y": snappedf(info.pos.y, 1.0),
		"t_since_respawn": snappedf(life_t, 0.01), "deaths": deaths,
	})
	var hint: Array = stage.hint_for(info)
	if hint.size() == 2:
		hint_counts[hint[0]] = hint_counts.get(hint[0], 0) + 1
		if hint_counts[hint[0]] >= HINT_AFTER:
			hud.show_hint(hint[1])
			GameLog.write({"event": "hint", "stage": stage.stage_id, "key": hint[0], "deaths": deaths})
	if info.cause == "ハマグリ":
		clam_deaths += 1
		if clam_deaths >= 2:
			hud.stick.flash_fast()


func _on_snipped(index: int) -> void:
	hud.toast("チョキン！ のこり %d 節" % index)
	GameLog.write({"event": "snip", "stage": stage.stage_id, "left": index, "t_since_respawn": snappedf(life_t, 0.01)})


func _on_clear() -> void:
	phase = Phase.CLEAR
	cat.state = Caterpillar.State.CLEAR
	hud.show_clear(deaths, elapsed)
	GameLog.write({"event": "clear", "stage": stage.stage_id, "deaths": deaths, "time": snappedf(elapsed, 0.1)})
