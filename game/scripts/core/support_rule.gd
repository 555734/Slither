class_name SupportRule
extends RefCounted
## 支持ルール（企画書 5.4）：
## 頭側の空中の節は reach 以内、尻尾側のぶら下がりは tail_hang 以内、
## 支えられた節に挟まれた空中の区間（橋渡し）は bridge 以内。


static func evaluate(sup: Array, reach: int, bridge: int, tail_hang: int) -> Dictionary:
	var n := sup.size()
	var res := {"ok": false, "head_run": n, "tail_run": n, "mid_max": 0, "any": false}
	var first := -1
	var last := -1
	for i in n:
		if sup[i]:
			if first < 0:
				first = i
			last = i
	if first < 0:
		return res
	res.any = true
	res.head_run = first
	res.tail_run = n - 1 - last
	var run := 0
	var mid := 0
	for i in range(first, last + 1):
		if sup[i]:
			mid = maxi(mid, run)
			run = 0
		else:
			run += 1
	res.mid_max = mid
	res.ok = res.head_run <= reach and res.tail_run <= tail_hang and mid <= bridge
	return res


static func evaluate_default(sup: Array) -> Dictionary:
	return evaluate(sup, Params.reach, Params.bridge_max, Params.tail_hang)
