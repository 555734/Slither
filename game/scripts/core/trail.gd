class_name Trail
extends RefCounted
## 頭の軌跡。古い点が先頭、最新の記録点が末尾。現在の頭の位置 head は別に持つ。
## 胴体は head から弧長 i*spacing の位置に置かれる（企画書 5.2 の軌跡追従）。

const STEP := 4.0

var pts := PackedVector2Array()
var head := Vector2.ZERO


## 頭→尻尾の順に並んだ点列から軌跡を作り直す（スポーン・落下からの復帰時）。
func reset_line(points_head_first: PackedVector2Array) -> void:
	pts = PackedVector2Array()
	for i in range(points_head_first.size() - 1, 0, -1):
		pts.append(points_head_first[i])
	head = points_head_first[0]


func move_head(p: Vector2) -> void:
	head = p
	if pts.is_empty() or pts[pts.size() - 1].distance_to(p) >= STEP:
		pts.append(p)


func length() -> float:
	var total := 0.0
	var cur := head
	for i in range(pts.size() - 1, -1, -1):
		total += cur.distance_to(pts[i])
		cur = pts[i]
	return total


## 頭から弧長 0, spacing, 2*spacing ... の位置を count 個返す。
func sample(count: int, spacing: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(count)
	var cur := head
	var acc := 0.0
	var idx := pts.size() - 1
	for k in count:
		var target := k * spacing
		while idx >= 0:
			var nxt := pts[idx]
			var seg_len := cur.distance_to(nxt)
			if acc + seg_len >= target and seg_len > 0.0001:
				break
			acc += seg_len
			cur = nxt
			idx -= 1
		if idx < 0:
			out[k] = cur
		else:
			var nxt2 := pts[idx]
			var seg_len2 := cur.distance_to(nxt2)
			out[k] = cur.lerp(nxt2, (target - acc) / seg_len2)
	return out


## 古い点を捨てて、全長を max_len 以内に保つ。
func trim(max_len: float) -> void:
	var total := length()
	var drop := 0
	while pts.size() - drop > 2:
		var d := pts[drop].distance_to(pts[drop + 1])
		if total - d < max_len:
			break
		total -= d
		drop += 1
	if drop > 0:
		pts = pts.slice(drop)


## 来た道を d だけ戻る（後ずさり）。体長ぶんの軌跡が残らない場合は失敗。
func retreat(d: float, keep_len: float) -> bool:
	if length() - d < keep_len + 1.0:
		return false
	var remaining := d
	while not pts.is_empty():
		var last := pts[pts.size() - 1]
		var seg_len := head.distance_to(last)
		if seg_len > remaining:
			head = head.lerp(last, remaining / seg_len)
			return true
		remaining -= seg_len
		head = last
		pts.remove_at(pts.size() - 1)
	return true


func snapshot() -> Array:
	return [pts.duplicate(), head]


func restore(snap: Array) -> void:
	pts = snap[0]
	head = snap[1]
