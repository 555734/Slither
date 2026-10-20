extends Stage
## ステージα（＝ステージ1「はじめての葉っぱ」の縮小版）。
## 這う・止まる・登る・首を伸ばすを説明なしで覚え、最後にハマグリの扉で
## 「おしりまでがイモムシです」を体験する。死ぬのはゴールの1か所だけ。


func build() -> void:
	stage_id = "alpha"
	title = "α はじめての葉っぱ"
	bounds = Rect2(0, 300, 3300, 1200)
	kill_y = 1450.0
	spawn_pos = Vector2(330, 988)
	show_drag_hint = true
	block(-100, 0, 0, 1500)
	block(0, 1000, 700, 1500)
	# 小さな段差 → 茎（壁）を登る
	block(700, 940, 1000, 1500)
	block(1000, 760, 1500, 1500, Solid.Mat.LEAF)
	# 小さな隙間（首を伸ばせば届く。落ちても浅い）
	block(1500, 860, 1570, 1500)
	block(1570, 760, 1900, 1500, Solid.Mat.LEAF)
	# #06 紙の葉っぱ橋（下は浅い谷）
	block(1900, 900, 2054, 1500)
	add_trap(PaperBridge.new()).setup(self, Rect2(1900, 760, 154, 12))
	block(2054, 760, 3200, 1500, Solid.Mat.LEAF)
	add_trap(Checkpoint.new()).setup(Rect2(2100, 640, 60, 120), Vector2(2400, 748))
	# ゴール：ハマグリの巣穴（#22 変種）
	block(2740, 560, 3200, 700)
	block(3100, 700, 3200, 760)
	block(3200, 0, 3300, 1500)
	add_trap(ClamGoal.new()).setup(Rect2(2752, 700, 348, 60), Rect2(2700, 700, 52, 60), 1.25)
