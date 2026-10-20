extends SceneTree
## 自動操縦（右へ全速）でステージを動かし、指定フレームのスクリーンショットを保存する。
## 実行例（画面のある環境、または xvfb-run 経由）：
##   godot --path game --resolution 720x1280 --script res://tests/screenshot.gd -- <ステージ番号 0-3> <出力先の接頭辞> [x,y の開始位置|-] [dbg|-] [フレーム番号,...]
var game: Game
var frame := 0
var out := ""
var plan: Array = []
var phase := 0

func _initialize() -> void:
	Params.reset_defaults()
	var args := OS.get_cmdline_user_args()
	var stage_idx := int(args[0])
	out = args[1]
	var stages := ["res://scripts/stages/stage_sandbox.gd", "res://scripts/stages/stage_alpha.gd", "res://scripts/stages/stage_beta.gd", "res://scripts/stages/stage_gamma.gd"]
	game = Game.new()
	root.add_child(game)
	game.start(load(stages[stage_idx]), true)
	if args.size() > 2 and args[2] != "-":
		var sp := args[2].split(",")
		game.stage.set_respawn(Vector2(float(sp[0]), float(sp[1])), Vector2.RIGHT)
		game.respawn()
		game.cam.snap_to(game.cat)
	game.debug_draw.visible = args.size() > 3 and args[3] == "dbg"
	game.autopilot = func(g: Game) -> void:
		g.cat.in_dir = Vector2.RIGHT
		g.cat.in_fast = true
		g.cat.in_back = false
	for s in (args[4] if args.size() > 4 else "60,120,180").split(","):
		plan.append(int(s))

func _process(_delta: float) -> bool:
	frame += 1
	if frame in plan:
		var img := root.get_texture().get_image()
		img.save_png("%s_%04d.png" % [out, frame])
	return frame > plan.max()
