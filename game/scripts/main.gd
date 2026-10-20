extends Node
## タイトル（ステージ選択）とゲームの切り替え。

const STAGES := [
	["試験場（MVP-0）", "res://scripts/stages/stage_sandbox.gd"],
	["α はじめての葉っぱ", "res://scripts/stages/stage_alpha.gd"],
	["β おしりは見えない", "res://scripts/stages/stage_beta.gd"],
	["γ 橋になれ", "res://scripts/stages/stage_gamma.gd"],
]

var game: Game
var menu: CanvasLayer
var current := -1


func _ready() -> void:
	Params.load_saved()
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--stage="):
			play(int(a.substr(8)))
			return
	show_menu()


func show_menu() -> void:
	if game:
		game.queue_free()
		game = null
	menu = CanvasLayer.new()
	add_child(menu)
	var bg := ColorRect.new()
	bg.color = Color("cdeccf")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 50
	box.offset_right = -50
	box.offset_top = 140
	box.add_theme_constant_override("separation", 22)
	var theme := Theme.new()
	theme.default_font_size = 34
	box.theme = theme
	menu.add_child(box)
	var title := Label.new()
	title.text = "おしりまでが\nイモムシです"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color("33691e"))
	box.add_child(title)
	var sub := Label.new()
	sub.text = "頭は避けた。おしりが死んだ。\n（MVP 試作版）"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color("4e342e"))
	box.add_child(sub)
	for i in STAGES.size():
		var b := Button.new()
		b.text = STAGES[i][0]
		b.custom_minimum_size = Vector2(0, 100)
		b.pressed.connect(play.bind(i))
		box.add_child(b)
	var note := Label.new()
	note.text = "記録したイベント：%d 件\n（user://mvp_log.jsonl）" % GameLog.count_events()
	note.add_theme_font_size_override("font_size", 22)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color", Color("4e342e"))
	box.add_child(note)


func play(index: int) -> void:
	if menu:
		menu.queue_free()
		menu = null
	if game:
		game.queue_free()
	current = index
	game = Game.new()
	add_child(game)
	game.exit_requested.connect(func() -> void: show_menu.call_deferred())
	game.next_requested.connect(func() -> void: play.call_deferred(current + 1))
	game.start(load(STAGES[index][1]), index >= 1 and index + 1 < STAGES.size())
