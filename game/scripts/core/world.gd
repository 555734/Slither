class_name World
extends RefCounted
## 簡易コリジョン世界。地形はすべて軸平行の矩形（Solid）。
## Godot の物理エンジンを使わず、毎回同じ結果になる決定的な計算にしている（企画書 5.7）。

var solids: Array[Solid] = []
## support_at(p: Vector2) -> bool を持つオブジェクト（罠が一時的に支えを提供する）
var providers: Array = []


func add_solid(s: Solid) -> void:
	solids.append(s)


static func closest_on_rect(r: Rect2, p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))


static func circle_hits_rect(r: Rect2, p: Vector2, rad: float) -> bool:
	return closest_on_rect(r, p).distance_squared_to(p) < rad * rad


## 円を地形の外へ押し出す。{pos, hit, normal, grip}
## grip は「当たった面のどれかが、つかめる素材だったか」。
func push_out(p: Vector2, rad: float) -> Dictionary:
	var hit := false
	var grip := false
	var normal := Vector2.ZERO
	for _iter in 3:
		var moved := false
		for s in solids:
			if not s.active:
				continue
			var r := s.rect
			var c := closest_on_rect(r, p)
			var d := p - c
			var dist := d.length()
			if dist >= rad:
				continue
			var n: Vector2
			if dist > 0.0001:
				n = d / dist
				p = c + n * rad
			else:
				# 中心が矩形の中：最も浅い方向へ押し出す
				var pens := [p.x - r.position.x, r.end.x - p.x, p.y - r.position.y, r.end.y - p.y]
				var dirs := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
				var best := 0
				for k in 4:
					if pens[k] < pens[best]:
						best = k
				n = dirs[best]
				p += n * (pens[best] + rad)
			normal += n
			hit = true
			grip = grip or s.grip
			moved = true
		if not moved:
			break
	return {"pos": p, "hit": hit, "normal": normal.normalized() if hit else Vector2.ZERO, "grip": grip}


## 支えになっている面の法線（地形→節の向き）。支えが無ければ ZERO。
func support_normal(p: Vector2, rad: float) -> Vector2:
	var reach := rad + Params.CONTACT_MARGIN
	for s in solids:
		if not s.active:
			continue
		var c := closest_on_rect(s.rect, p)
		var d := p - c
		var dist := d.length()
		if dist > reach:
			continue
		var n := d / dist if dist > 0.0001 else Vector2.UP
		if n.y < -0.5 or s.grip:
			return n
	for prov in providers:
		if prov.support_at(p):
			return Vector2.UP
	return Vector2.ZERO


func is_supported(p: Vector2, rad: float) -> bool:
	return support_normal(p, rad) != Vector2.ZERO


## 近くにある「つかめる壁」（縦の面）への向き。無ければ ZERO。
func nearby_grip_wall(p: Vector2, rad: float, within: float) -> Vector2:
	var best := INF
	var dir := Vector2.ZERO
	for s in solids:
		if not s.active or not s.grip:
			continue
		var c := closest_on_rect(s.rect, p)
		var d := c - p
		var dist := d.length()
		if dist < 0.0001 or dist > rad + within:
			continue
		var n := d / dist
		if absf(n.x) < 0.8:
			continue
		if dist < best:
			best = dist
			dir = Vector2(signf(n.x), 0.0)
	return dir
