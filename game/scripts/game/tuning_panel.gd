class_name TuningPanel
extends PanelContainer
## 実機で数値を変えて手触りを調整するパネル（企画書 10.6）。

signal applied
signal closed

var _labels := {}
var _sliders := {}
var _slow_check: CheckBox


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 30
	offset_right = -30
	offset_top = 130
	offset_bottom = -40
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.12, 0.1, 0.92)
	bg.set_corner_radius_all(16)
	bg.set_content_margin_all(18)
	add_theme_stylebox_override("panel", bg)
	var outer := VBoxContainer.new()
	add_child(outer)
	var head := Label.new()
	head.text = "パラメータ調整（【仮説】値）"
	outer.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for t in Params.TUNABLES:
		var key: String = t[0]
		var lab := Label.new()
		lab.add_theme_font_size_override("font_size", 24)
		list.add_child(lab)
		var sl := HSlider.new()
		sl.min_value = t[2]
		sl.max_value = t[3]
		sl.step = t[4]
		sl.custom_minimum_size = Vector2(0, 48)
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.value_changed.connect(_on_changed.bind(key))
		list.add_child(sl)
		_labels[key] = [lab, t[1]]
		_sliders[key] = sl
	_slow_check = CheckBox.new()
	_slow_check.text = "常に低速（精密操作モード）"
	_slow_check.toggled.connect(func(on: bool) -> void: Params.always_slow = on)
	list.add_child(_slow_check)
	var row := HBoxContainer.new()
	outer.add_child(row)
	for spec in [["適用して再開", _on_apply], ["初期値", _on_defaults], ["閉じる", _on_close]]:
		var b := Button.new()
		b.text = spec[0]
		b.custom_minimum_size = Vector2(0, 80)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(spec[1])
		row.add_child(b)
	refresh()


func refresh() -> void:
	for key in _sliders:
		_sliders[key].set_value_no_signal(float(Params.get_value(key)))
		_update_label(key)
	_slow_check.set_pressed_no_signal(Params.always_slow)


func _update_label(key: String) -> void:
	var v: Variant = Params.get_value(key)
	var txt := ("%.2f" % v) if v is float else str(v)
	_labels[key][0].text = "%s：%s" % [_labels[key][1], txt]


func _on_changed(value: float, key: String) -> void:
	Params.set_value(key, value)
	_update_label(key)


func _on_apply() -> void:
	Params.save()
	visible = false
	applied.emit()


func _on_defaults() -> void:
	Params.reset_defaults()
	refresh()


func _on_close() -> void:
	Params.save()
	visible = false
	closed.emit()
