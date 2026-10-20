class_name BurrowGoal
extends Trap
## ゴールの巣穴。頭だけでなく「全身」が入ったらクリア（おしりまでがイモムシです）。

var interior := Rect2()


func setup(r: Rect2) -> BurrowGoal:
	interior = r
	trap_id = "goal"
	return self


func tick(_dt: float, cat: Caterpillar) -> void:
	if cat.state == Caterpillar.State.CRAWL and cat.all_inside(interior):
		stage.clear()


func _draw() -> void:
	draw_rect(interior, Color(0.18, 0.11, 0.06, 0.85))
	var flag_base := Vector2(interior.position.x - 14, interior.position.y)
	draw_line(flag_base, flag_base + Vector2(0, -80), Color("5e3a1a"), 4.0)
	var flag := PackedVector2Array([flag_base + Vector2(0, -80), flag_base + Vector2(46, -68), flag_base + Vector2(0, -56)])
	draw_colored_polygon(flag, Color("ff7043"))
	draw_string(ThemeDB.fallback_font, flag_base + Vector2(-20, -88), "GOAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
