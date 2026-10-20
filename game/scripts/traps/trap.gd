class_name Trap
extends Node2D
## 罠の基底。罠は stage.tick() から毎物理フレーム呼ばれ、イモムシの節の位置を見て作動する。
## リスポーン時には reset() で必ず初期状態に戻す（企画書 10.2）。

var stage: Stage
var trap_id := "trap"


func reset() -> void:
	pass


func tick(_dt: float, _cat: Caterpillar) -> void:
	pass


## ログ・図鑑用の短い名前
func trap_name() -> String:
	return trap_id
