extends SceneTree
## ヘッドレスのシナリオテスト。
## 実行：godot --headless --path game --script res://tests/run_tests.gd
## 各罠について「初見の素直な操作では失敗し、企画書どおりの攻略では突破できる」ことを確かめる。

const DT := 1.0 / 60.0

var failures := 0
var passes := 0


func _initialize() -> void:
	Params.reset_defaults()
	test_trail()
	test_support_rule()
	test_flat_crawl()
	test_reach_and_gap()
	test_wall_climb()
	test_alpha_full_run()
	test_alpha_imprecise_input()
	test_alpha_clam_slow()
	test_beta_guillotine()
	test_beta_switch()
	test_beta_earwig()
	test_gamma_plank()
	test_gamma_fake_floor()
	test_gamma_shaft()
	print("\n%d passed, %d failed" % [passes, failures])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------ ヘルパー

func check(cond: bool, label: String) -> void:
	if cond:
		passes += 1
		print("  ok   ", label)
	else:
		failures += 1
		print("  FAIL ", label)


func make(path: String, head_pos = null, dir: Vector2 = Vector2.RIGHT) -> Dictionary:
	for c in root.get_children():
		c.free()
	var stage: Stage = load(path).new()
	root.add_child(stage)
	stage.setup()
	var cat := Caterpillar.new()
	cat.world = stage.world
	root.add_child(cat)
	var ctx := {"stage": stage, "cat": cat, "death": {}, "t": 0.0, "phase": 0, "pt": 0.0}
	cat.died.connect(func(info: Dictionary) -> void: ctx.death = info)
	cat.spawn(stage.spawn_pos if head_pos == null else head_pos, dir)
	return ctx


## driver(ctx) が毎フレーム入力を決める。死亡・クリア・時間切れで止まる。
func run(ctx: Dictionary, seconds: float, driver: Callable) -> String:
	var stage: Stage = ctx.stage
	var cat: Caterpillar = ctx.cat
	var frames := int(seconds / DT)
	for _f in frames:
		cat.in_dir = Vector2.ZERO
		cat.in_fast = true
		cat.in_back = false
		driver.call(ctx)
		cat.step(DT)
		stage.tick(DT, cat)
		if cat.is_alive():
			for i in cat.n:
				if cat.seg[i].y > stage.kill_y:
					cat.kill("奈落", i, "おちた…")
					break
		ctx.t += DT
		ctx.pt += DT
		if not ctx.death.is_empty():
			return "dead"
		if stage.cleared:
			return "clear"
	return "timeout"


func go(ctx: Dictionary, d: Vector2, fast: bool = true) -> void:
	ctx.cat.in_dir = d.normalized()
	ctx.cat.in_fast = fast


func next_phase(ctx: Dictionary) -> void:
	ctx.phase += 1
	ctx.pt = 0.0


func trap_of(ctx: Dictionary, cls) -> Trap:
	for t in ctx.stage.traps:
		if is_instance_of(t, cls):
			return t
	return null


# ------------------------------------------------------------ 基礎

func test_trail() -> void:
	print("trail")
	var tr := Trail.new()
	tr.reset_line(PackedVector2Array([Vector2(100, 0), Vector2(50, 0), Vector2(0, 0)]))
	var s := tr.sample(3, 25.0)
	check(s[0].is_equal_approx(Vector2(100, 0)) and s[1].is_equal_approx(Vector2(75, 0)) and s[2].is_equal_approx(Vector2(50, 0)), "弧長サンプリング")
	tr.move_head(Vector2(110, 0))
	check(is_equal_approx(tr.length(), 110.0), "頭の移動で軌跡が伸びる")
	check(tr.retreat(30.0, 50.0) and is_equal_approx(tr.head.x, 80.0), "後ずさりで来た道を戻る")
	check(not tr.retreat(60.0, 50.0), "体長ぶんの軌跡が無ければ戻れない")


func test_support_rule() -> void:
	print("support rule (reach 4 / bridge 8 / tail 6)")
	var t := true
	var f := false
	check(SupportRule.evaluate([f, f, f, f, t, t, t, t], 4, 8, 6).ok, "首伸ばし4節はOK")
	check(not SupportRule.evaluate([f, f, f, f, f, t, t, t], 4, 8, 6).ok, "首伸ばし5節はNG")
	check(SupportRule.evaluate([t, f, f, f, f, f, f, f, f, t], 4, 8, 6).ok, "橋渡し8節はOK")
	check(not SupportRule.evaluate([t, f, f, f, f, f, f, f, f, f, t], 4, 8, 6).ok, "橋渡し9節はNG")
	check(not SupportRule.evaluate([f, f, f], 4, 8, 6).ok, "どこにも支えが無ければNG")


func test_flat_crawl() -> void:
	print("crawl")
	var ctx := make("res://scripts/stages/stage_beta.gd")
	var x0: float = ctx.cat.head().x
	run(ctx, 1.0, func(c: Dictionary) -> void: go(c, Vector2.RIGHT))
	var dx: float = ctx.cat.head().x - x0
	check(dx > 200.0 and dx < 250.0, "標準速度でおよそ240px/s進む (%.0f)" % dx)
	check(ctx.cat.rule.ok and ctx.cat.state == Caterpillar.State.CRAWL, "平地では全節が支えられている")
	var tail_before: Vector2 = ctx.cat.tail()
	run(ctx, 0.5, func(_c: Dictionary) -> void: pass)
	check(ctx.cat.tail().is_equal_approx(tail_before), "指を離すと止まる")


func test_reach_and_gap() -> void:
	print("reach / gaps (sandbox)")
	# 4節の隙間は首を伸ばして渡れる
	var ctx := make("res://scripts/stages/stage_sandbox.gd", Vector2(1790, 988))
	var res := run(ctx, 2.5, func(c: Dictionary) -> void: go(c, Vector2.RIGHT))
	check(res == "timeout" and ctx.cat.head().x > 1950.0 and ctx.cat.state == Caterpillar.State.CRAWL, "4節の隙間を首伸ばしで渡れる (x=%.0f)" % ctx.cat.head().x)
	# 8節の隙間は届かない → 押し続けると手が滑って浅い穴に落ち、そこから復帰する
	ctx = make("res://scripts/stages/stage_sandbox.gd", Vector2(2520, 988))
	var max_x := [0.0]
	var fell := [false]
	res = run(ctx, 4.0, func(c: Dictionary) -> void:
		go(c, Vector2.RIGHT)
		if c.cat.state == Caterpillar.State.FALL:
			fell[0] = true
		if not fell[0]:
			max_x[0] = maxf(max_x[0], c.cat.head().x)
		return)
	check(max_x[0] < 2700.0, "8節の隙間は首が届かない (max x=%.0f)" % max_x[0])
	check(fell[0] and res == "timeout" and ctx.cat.state == Caterpillar.State.CRAWL, "限界で押し続けると落ち、浅い穴の中で復帰する")


func test_wall_climb() -> void:
	print("wall climb")
	var ctx := make("res://scripts/stages/stage_sandbox.gd", Vector2(600, 988))
	var min_y := [9999.0]
	run(ctx, 3.0, func(c: Dictionary) -> void:
		go(c, Vector2.RIGHT)
		min_y[0] = minf(min_y[0], c.cat.head().y))
	check(min_y[0] < 815.0 and ctx.cat.is_alive(), "右へ押すだけで樹皮の壁を登って上に出る (min y=%.0f)" % min_y[0])
	# ガラスの天井にはつかまれない：真上に伸ばしても支えにならない
	ctx = make("res://scripts/stages/stage_sandbox.gd", Vector2(1000, 988))
	run(ctx, 1.0, func(c: Dictionary) -> void: go(c, Vector2.UP))
	check(not ctx.cat.sup[0], "ガラスの天井は支えにならない")
	ctx = make("res://scripts/stages/stage_sandbox.gd", Vector2(1220, 988))
	var held := [false]
	run(ctx, 1.0, func(c: Dictionary) -> void:
		go(c, Vector2.UP)
		if c.cat.head().y < 916.0 and c.cat.sup[0] and c.cat.head().x < 1340.0:
			held[0] = true)
	check(held[0], "樹皮の天井は支えになる")


# ------------------------------------------------------------ α

func test_alpha_full_run() -> void:
	print("alpha")
	var ctx := make("res://scripts/stages/stage_alpha.gd")
	var hammock := [false]
	var res := run(ctx, 25.0, func(c: Dictionary) -> void:
		go(c, Vector2.RIGHT)
		var pb: PaperBridge = trap_of(c, PaperBridge)
		if pb.torn and c.cat.state == Caterpillar.State.FALL:
			hammock[0] = true
		return)
	var pb2: PaperBridge = trap_of(ctx, PaperBridge)
	check(pb2.torn, "紙の葉っぱ橋が破れる")
	check(hammock[0], "破れたあと体がハンモックになる（落下状態）")
	check(res == "clear", "右へ全速で押すだけで、段差・茎・隙間・紙の橋・ハマグリを越えてクリア (%s, %s)" % [res, ctx.death.get("text", "")])


## 実機テストで「前に進めない・上に上がれない」と指摘された点の回帰テスト。
## 指の向きが水平から多少ずれていても、αをクリアできること。
func test_alpha_imprecise_input() -> void:
	for deg in [-25.0, -12.0, -5.0, 5.0, 12.0, 25.0, -45.0]:
		var ctx := make("res://scripts/stages/stage_alpha.gd")
		var stuck := [0.0]
		var res := run(ctx, 30.0, func(c: Dictionary) -> void:
			go(c, Vector2.from_angle(deg_to_rad(deg)))
			if c.cat.straining:
				stuck[0] += DT
			return)
		check(res == "clear" and stuck[0] < 2.5, "指が %+.0f 度ずれていてもαをクリアできる (%s, 詰まり %.1f 秒)" % [deg, res, stuck[0]])


func test_alpha_clam_slow() -> void:
	var ctx := make("res://scripts/stages/stage_alpha.gd", Vector2(2400, 748))
	var res := run(ctx, 10.0, func(c: Dictionary) -> void: go(c, Vector2.RIGHT, false))
	check(res == "dead" and ctx.death.cause == "ハマグリ" and ctx.death.part == "おしり", "低速で巣穴に入るとハマグリにおしりを挟まれる (%s %s)" % [res, ctx.death.get("part", "")])


# ------------------------------------------------------------ β

func test_beta_guillotine() -> void:
	print("beta")
	var ctx := make("res://scripts/stages/stage_beta.gd")
	var res := run(ctx, 6.0, func(c: Dictionary) -> void: go(c, Vector2.RIGHT))
	check(res == "dead" and ctx.death.cause == "ギロチン" and ctx.death.index > 0, "まっすぐ進むと、頭が通った後に体がギロチンで切られる (%s idx=%s)" % [res, ctx.death.get("index", -1)])
	# フェイント：頭だけ光線に入れて引き返し、刃が床に沈んでいる間に通る
	ctx = make("res://scripts/stages/stage_beta.gd")
	res = run(ctx, 12.0, func(c: Dictionary) -> void:
		var g: Guillotine = trap_of(c, Guillotine)
		match c.phase:
			0:
				go(c, Vector2.RIGHT)
				if c.cat.head().x > 906.0:
					next_phase(c)
			1:
				c.cat.in_back = true
				if g.state == Guillotine.S.DOWN:
					next_phase(c)
			2:
				go(c, Vector2.RIGHT)
				if c.cat.head().x > 1560.0:
					next_phase(c)
			4:
				pass
		return)
	check(res == "timeout" and ctx.cat.is_alive() and ctx.cat.n == 12 and ctx.cat.head().x > 1500.0, "頭だけ光線に入れて後ずさり、刃を空振りさせて全身で通過できる (%s x=%.0f n=%d)" % [res, ctx.cat.head().x, ctx.cat.n])


func test_beta_switch() -> void:
	var ctx := make("res://scripts/stages/stage_beta.gd", Vector2(1900, 988))
	var res := run(ctx, 12.0, func(c: Dictionary) -> void: go(c, Vector2.RIGHT))
	check(res == "dead", "スイッチを素通りすると、大玉か穴でやられる (%s)" % ctx.death.get("cause", res))
	# 煙突に逃げ込んで大玉をやり過ごすと、大玉が穴の栓になる
	ctx = make("res://scripts/stages/stage_beta.gd", Vector2(1900, 988))
	res = run(ctx, 20.0, func(c: Dictionary) -> void:
		var sw: TailSwitch = trap_of(c, TailSwitch)
		match c.phase:
			0:
				go(c, Vector2.RIGHT)
				if c.cat.head().x >= 2300.0:
					next_phase(c)
			1:
				go(c, Vector2.UP)
				if c.cat.head().y < 640.0:
					next_phase(c)
			2:
				if sw.plugged:
					next_phase(c)
			3:
				go(c, Vector2.DOWN)
				if c.cat.head().y > 980.0:
					next_phase(c)
			4:
				go(c, Vector2.RIGHT)
				if c.cat.head().x > 3000.0:
					next_phase(c)
			5:
				pass
		return)
	var sw2: TailSwitch = trap_of(ctx, TailSwitch)
	check(sw2.fired and sw2.plugged, "尻尾が離れた瞬間に大玉が転がり、穴の栓になる")
	check(res == "timeout" and ctx.cat.is_alive() and ctx.cat.head().x > 3000.0, "煙突に全身で逃げ込めば助かり、栓の上を渡れる (%s x=%.0f)" % [ctx.death.get("cause", res), ctx.cat.head().x])


func test_beta_earwig() -> void:
	var ctx := make("res://scripts/stages/stage_beta.gd", Vector2(3200, 988))
	var res := run(ctx, 20.0, func(c: Dictionary) -> void: go(c, Vector2.RIGHT))
	check(res == "dead" and ctx.death.cause == "ハサミムシ", "止まらずに走ると、ハサミムシに尻尾を切られ続けて失敗 (%s)" % ctx.death.get("cause", res))
	ctx = make("res://scripts/stages/stage_beta.gd", Vector2(3200, 988))
	res = run(ctx, 25.0, func(c: Dictionary) -> void:
		var ew: Earwig = trap_of(c, Earwig)
		match c.phase:
			0:
				go(c, Vector2.RIGHT)
				if ew.state == Earwig.S.CHASE and c.pt > 1.2:
					next_phase(c)
			1:
				if ew.state == Earwig.S.GONE:
					next_phase(c)
			2:
				go(c, Vector2.RIGHT)
		return)
	check(res == "clear" and ctx.cat.n >= 9, "止まってやり過ごせば、ほぼ無傷でゴールできる (%s n=%d)" % [res, ctx.cat.n])


# ------------------------------------------------------------ γ

func test_gamma_plank() -> void:
	print("gamma")
	var ctx := make("res://scripts/stages/stage_gamma.gd")
	var res := run(ctx, 8.0, func(c: Dictionary) -> void: go(c, Vector2.RIGHT))
	var pl: PlankBridge = trap_of(ctx, PlankBridge)
	check(pl.broken and res == "dead", "まっすぐ渡ると6節目で板が割れて落ちる (%s)" % res)
	# 首を伸ばして板の手前半分を飛ばす
	ctx = make("res://scripts/stages/stage_gamma.gd")
	res = run(ctx, 10.0, func(c: Dictionary) -> void:
		match c.phase:
			0:
				go(c, Vector2.RIGHT)
				if c.cat.head().x >= 690.0:
					next_phase(c)
			1:
				go(c, Vector2(1, -1.2), false)
				if c.cat.head().y < 970.0:
					next_phase(c)
			2:
				go(c, Vector2(1, 1), false)
				if c.cat.sup.size() > 0 and c.cat.sup[0] and c.cat.head().x > 720.0:
					next_phase(c)
			3:
				go(c, Vector2.RIGHT)
				if c.cat.head().x > 1150.0:
					next_phase(c)
			4:
				pass
		return)
	pl = trap_of(ctx, PlankBridge)
	check(not pl.broken and res == "timeout" and ctx.cat.head().x > 1100.0, "低く小さく頭を持ち上げて板の手前を飛ばせば割れずに渡れる (%s broken=%s x=%.0f)" % [res, pl.broken, ctx.cat.head().x])


func test_gamma_fake_floor() -> void:
	var ctx := make("res://scripts/stages/stage_gamma.gd", Vector2(1300, 988))
	var res := run(ctx, 8.0, func(c: Dictionary) -> void: go(c, Vector2.RIGHT))
	check(res == "dead" and ctx.death.cause == "トゲ", "書き割り床に押し続けると落ちてトゲ (%s)" % ctx.death.get("cause", res))
	ctx = make("res://scripts/stages/stage_gamma.gd", Vector2(1300, 988))
	res = run(ctx, 10.0, func(c: Dictionary) -> void:
		match c.phase:
			0:
				go(c, Vector2.RIGHT)
				if c.cat.head().x >= 1450.0:
					next_phase(c)
			1:
				go(c, Vector2.UP)
				if c.cat.head().y < 916.0:
					next_phase(c)
			2:
				go(c, Vector2.RIGHT)
				if c.cat.head().x > 1675.0:
					next_phase(c)
			3:
				go(c, Vector2(0.3, 1))
				if c.cat.head().y > 980.0:
					next_phase(c)
			4:
				go(c, Vector2.RIGHT)
				if c.cat.head().x > 1900.0:
					next_phase(c)
			5:
				pass
		return)
	check(res == "timeout" and ctx.cat.is_alive() and ctx.cat.head().x > 1900.0, "上の枝につかまって渡れる (%s x=%.0f)" % [ctx.death.get("cause", res), ctx.cat.head().x])


func test_gamma_shaft() -> void:
	var ctx := make("res://scripts/stages/stage_gamma.gd", Vector2(2150, 988))
	var res := run(ctx, 15.0, func(c: Dictionary) -> void: go(c, Vector2.RIGHT))
	var jam: ShaftJam = trap_of(ctx, ShaftJam)
	check(jam.jammed, "横向きのまま落ちると縦穴でつっかえる")
	check(res == "clear", "つっかえた先の横穴からゴールへ (%s %s)" % [res, ctx.death.get("cause", "")])
