extends Stage
## MVP-0 試験場：目的なく這い回って、操作と体の挙動を確かめる部屋（企画書 11.2）。

const G := 1000.0


func build() -> void:
	stage_id = "sandbox"
	title = "試験場"
	bounds = Rect2(0, 300, 4300, 1200)
	kill_y = 1450.0
	spawn_pos = Vector2(300, G - 12)
	block(-100, 0, 0, 1500)
	block(0, G, 1500, 1500)
	# 段差と、のぼれる樹皮の塔
	block(380, G - 40, 500, G)
	block(640, G - 180, 780, G)
	sign_at(710, G - 200, "樹皮：のぼれる", 160)
	# つかめないガラスの天井 と つかめる樹皮の天井
	block(900, 800, 1060, 900, Solid.Mat.GLASS)
	sign_at(980, 780, "ガラス", 100)
	block(1180, 800, 1340, 900)
	sign_at(1260, 780, "樹皮", 100)
	# 幅 2 / 4 / 6 / 8 節ぶんの隙間（底は浅い）
	var x := 1500.0
	var widths := [2, 4, 6, 8]
	for w in widths:
		var gap: float = w * Params.DEFAULTS["spacing"]
		block(x, G + 100, x + gap, 1500)
		sign_at(x + gap / 2.0, G - 40, "%dふし" % w, 90)
		x += gap
		block(x, G, x + 260, 1500)
		x += 260
	# 崩れる床（3秒で戻る）
	block(x, G + 100, x + 160, 1500)
	add_trap(CrumbleBridge.new()).setup(self, Rect2(x, G, 160, 14), 1, 0.5, 3.0, Solid.Mat.PLANK)
	sign_at(x + 80, G - 40, "崩れる床", 110)
	x += 160
	block(x, G, x + 300, 1500)
	x += 300
	# 深い穴（トゲ）
	block(x, G + 400, x + 160, 1500)
	block(x, G + 6, x + 6, G + 380, Solid.Mat.GLASS)
	block(x + 154, G + 6, x + 160, G + 380, Solid.Mat.GLASS)
	add_trap(Spikes.new()).setup(Rect2(x, G + 380, 160, 20))
	x += 160
	block(x, G, x + 600, 1500)
	block(x + 600, 0, x + 700, 1500)
	bounds.size.x = x + 700
