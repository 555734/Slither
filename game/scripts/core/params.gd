class_name Params
extends RefCounted
## 調整可能なパラメータ一式（企画書 5.3 / 4.2 の【仮説】値）。
## 実機のチューニングパネルから変更でき、user://tuning.cfg に保存される。

const SAVE_PATH := "user://tuning.cfg"

const DEFAULTS := {
	"seg_count": 12,
	"spacing": 22.0,
	"speed_slow": 120.0,
	"speed_fast": 240.0,
	"turn_rate": 300.0,
	"turn_rate_slow": 450.0,
	"reach": 4,
	"bridge_max": 8,
	"tail_hang": 8,
	"inner_wheel": 0.0,
	"strain_letgo": 1.0,
	"min_len": 6,
	"always_slow": false,
}

## [キー, 表示名, 最小, 最大, 刻み]
const TUNABLES := [
	["seg_count", "節の数", 4, 20, 1],
	["spacing", "節の間隔(px)", 14, 32, 1],
	["speed_slow", "低速(px/s)", 60, 200, 10],
	["speed_fast", "標準速(px/s)", 120, 400, 10],
	["turn_rate", "旋回(度/s)", 120, 720, 10],
	["turn_rate_slow", "低速時の旋回(度/s)", 120, 900, 10],
	["reach", "首伸ばしの限界(節)", 1, 8, 1],
	["bridge_max", "橋渡しの限界(節)", 2, 14, 1],
	["tail_hang", "尻尾ぶら下がり限界(節)", 1, 12, 1],
	["inner_wheel", "内輪差係数", 0.0, 1.0, 0.05],
	["strain_letgo", "限界で手を離すまで(秒)", 0.3, 3.0, 0.1],
	["min_len", "最短長(節)", 2, 10, 1],
]

static var seg_count: int = 12
static var spacing: float = 22.0
static var speed_slow: float = 120.0
static var speed_fast: float = 240.0
static var turn_rate: float = 300.0
static var turn_rate_slow: float = 450.0
static var reach: int = 4
static var bridge_max: int = 8
static var tail_hang: int = 8
static var inner_wheel: float = 0.0
static var strain_letgo: float = 1.0
static var min_len: int = 6
static var always_slow: bool = false

## 見た目と当たり判定（調整対象外）
const BODY_RADIUS := 12.0
const HIT_RADIUS := 9.0
const CONTACT_MARGIN := 4.0
const GRAVITY := 1400.0


static func get_value(key: String) -> Variant:
	match key:
		"seg_count": return seg_count
		"spacing": return spacing
		"speed_slow": return speed_slow
		"speed_fast": return speed_fast
		"turn_rate": return turn_rate
		"turn_rate_slow": return turn_rate_slow
		"reach": return reach
		"bridge_max": return bridge_max
		"tail_hang": return tail_hang
		"inner_wheel": return inner_wheel
		"strain_letgo": return strain_letgo
		"min_len": return min_len
		"always_slow": return always_slow
	return null


static func set_value(key: String, value: Variant) -> void:
	match key:
		"seg_count": seg_count = int(value)
		"spacing": spacing = float(value)
		"speed_slow": speed_slow = float(value)
		"speed_fast": speed_fast = float(value)
		"turn_rate": turn_rate = float(value)
		"turn_rate_slow": turn_rate_slow = float(value)
		"reach": reach = int(value)
		"bridge_max": bridge_max = int(value)
		"tail_hang": tail_hang = int(value)
		"inner_wheel": inner_wheel = float(value)
		"strain_letgo": strain_letgo = float(value)
		"min_len": min_len = int(value)
		"always_slow": always_slow = bool(value)


static func reset_defaults() -> void:
	for key in DEFAULTS:
		set_value(key, DEFAULTS[key])


static func save() -> void:
	var cfg := ConfigFile.new()
	for key in DEFAULTS:
		cfg.set_value("tuning", key, get_value(key))
	cfg.save(SAVE_PATH)


static func load_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for key in DEFAULTS:
		if cfg.has_section_key("tuning", key):
			set_value(key, cfg.get_value("tuning", key))


static func body_length() -> float:
	return spacing * (seg_count - 1)
