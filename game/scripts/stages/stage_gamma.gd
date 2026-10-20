extends Stage
## ステージγ（＝ステージ3「橋になれ」の縮小版）。
## 体が長いことのメリットとデメリット：#01 定員オーバー橋 → #07 書き割り床 → #29 つっかえ棒。


func build() -> void:
	stage_id = "gamma"
	title = "γ 橋になれ"
	bounds = Rect2(0, 300, 3400, 1400)
	kill_y = 1680.0
	spawn_pos = Vector2(400, 988)
	block(-100, 0, 0, 1700)
	block(0, 1000, 700, 1700)
	# #01 定員オーバー橋
	sign_at(620, 1000, "定員 5ふし", 120)
	add_trap(PlankBridge.new()).setup(self, Rect2(700, 1000, 143, 12), 5)
	block(706, 1012, 712, 1280, Solid.Mat.GLASS)
	block(831, 1012, 837, 1280, Solid.Mat.GLASS)
	add_trap(Spikes.new()).setup(Rect2(700, 1280, 143, 20))
	block(700, 1300, 843, 1700)
	block(843, 1000, 1500, 1700)
	add_trap(Checkpoint.new()).setup(Rect2(1000, 880, 60, 120), Vector2(1300, 988))
	# #07 書き割り床（上に、つかまって渡れる枝）
	add_trap(FakeFloor.new()).setup(Rect2(1500, 1000, 132, 260))
	block(1500, 1006, 1508, 1280, Solid.Mat.GLASS)
	block(1624, 1006, 1632, 1280, Solid.Mat.GLASS)
	add_trap(Spikes.new()).setup(Rect2(1500, 1280, 132, 20))
	block(1500, 1300, 1632, 1700)
	block(1440, 880, 1700, 900)
	block(1632, 1000, 2200, 1700)
	add_trap(Checkpoint.new()).setup(Rect2(1900, 880, 60, 120), Vector2(2150, 988))
	# #29 つっかえ棒：細い枝の橋が崩れて縦穴へ。横向きなら壁に突っ張って止まる
	add_trap(CrumbleBridge.new()).setup(self, Rect2(2200, 1000, 210, 10), 8, 0.35)
	block(2200, 1010, 2210, 1580, Solid.Mat.GLASS)
	block(2410, 600, 2440, 1050, Solid.Mat.GLASS)
	block(2410, 1122, 2440, 1580, Solid.Mat.GLASS)
	add_trap(Spikes.new()).setup(Rect2(2210, 1560, 200, 20))
	block(2200, 1580, 2440, 1700)
	add_trap(ShaftJam.new()).setup(self, 2210.0, 2410.0, 1110.0)
	# 横穴の先がゴール
	block(2440, 1122, 3400, 1700)
	block(2440, 600, 3400, 1050)
	block(3290, 1050, 3400, 1122)
	add_trap(BurrowGoal.new()).setup(Rect2(2900, 1050, 390, 72))


func hint_for(info: Dictionary) -> Array:
	var x: float = info.pos.x
	if x < 900.0:
		return ["plank", "板に乗る節を5つ以下に。指を小さく引いて（低速）、板の手前で頭を斜め上に持ち上げて飛び越そう"]
	if x < 1800.0:
		return ["fake", "草の色が少し違う床は絵。上の枝の下側につかまって渡ろう"]
	return ["shaft", "横向きのまま落ちれば、細い穴の壁に突っ張って止まる"]
