extends Stage
## ステージβ（＝ステージ2「おしりは見えない」の縮小版）。
## 体は過去の自分：罠は頭が通り過ぎたあとの体を狙う。
## #17 頭センサーのギロチン → #19 しっぽ離しスイッチ → #16 背後のハサミムシ。


func build() -> void:
	stage_id = "beta"
	title = "β おしりは見えない"
	bounds = Rect2(0, 300, 5400, 1200)
	kill_y = 1450.0
	spawn_pos = Vector2(380, 988)
	block(-100, 0, 0, 1500)
	block(0, 1000, 2700, 1500)
	# 部屋1（Uターンできる高さ）とギロチンの通路
	block(0, 300, 900, 640)
	block(900, 300, 1500, 900)
	add_trap(Guillotine.new()).setup(905.0, 900.0, 1000.0, 930.0, 900.0, 1000.0, 0.35)
	block(1500, 300, 1950, 700)
	add_trap(Checkpoint.new()).setup(Rect2(1600, 880, 60, 120), Vector2(1900, 988))
	# しっぽ離しスイッチ、逃げ込める煙突、渡れない穴
	block(1950, 380, 2334, 920)
	block(2362, 380, 2700, 920)
	block(2334, 380, 2362, 420)
	add_trap(TailSwitch.new()).setup(self, Rect2(2000, 990, 80, 10), 1000.0, 1500.0, 2700.0, 2840.0)
	block(2700, 1250, 2840, 1500)
	block(2700, 1006, 2706, 1230, Solid.Mat.GLASS)
	block(2834, 1006, 2840, 1230, Solid.Mat.GLASS)
	add_trap(Spikes.new()).setup(Rect2(2700, 1230, 140, 20))
	block(2840, 1000, 4700, 1500)
	add_trap(Checkpoint.new()).setup(Rect2(2900, 880, 60, 120), Vector2(3200, 988))
	# 背後のハサミムシ。段差の上までは追ってこない
	add_trap(Earwig.new()).setup(1000.0, 3350.0, 4700.0)
	block(4700, 940, 5300, 1500)
	block(4900, 600, 5300, 880)
	block(5200, 880, 5300, 940)
	block(5300, 0, 5400, 1500)
	add_trap(BurrowGoal.new()).setup(Rect2(4910, 880, 290, 60))
