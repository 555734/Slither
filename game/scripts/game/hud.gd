class_name Hud
extends CanvasLayer
## 画面上の UI：上部バー（リトライ・ミス数・デバッグ・調整・メニュー）、操作スティック、
## 失敗時の部位表示、クリア画面、調整パネル。

signal retry_pressed
signal menu_pressed
signal debug_toggled
signal tuning_applied
signal next_pressed
signal restart_pressed

var stick: TouchStick
var tuning: TuningPanel
var root: Control
var title_label: Label
var miss_label: Label
var death_label: Label
var toast_label: Label
var hint_panel: PanelContainer
var hint_label: Label
var clear_panel: PanelContainer
var clear_label: Label
var next_button: Button
var toast_t := 0.0


func build(title: String, has_next: bool) -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font_size = 30
	root.theme = theme
	add_child(root)

	stick = TouchStick.new()
	root.add_child(stick)

	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 110
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.18, 0.1, 0.55)
	sb.set_content_margin_all(10)
	bar.add_theme_stylebox_override("panel", sb)
	root.add_child(bar)
	var row := HBoxContainer.new()
	bar.add_child(row)
	row.add_child(_button("↻", func() -> void: retry_pressed.emit()))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 26)
	info.add_child(title_label)
	miss_label = Label.new()
	miss_label.add_theme_font_size_override("font_size", 24)
	info.add_child(miss_label)
	row.add_child(_button("DBG", func() -> void: debug_toggled.emit()))
	row.add_child(_button("⚙", func() -> void: open_tuning()))
	row.add_child(_button("≡", func() -> void: menu_pressed.emit()))

	death_label = Label.new()
	death_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	death_label.offset_top = 220
	death_label.offset_bottom = 400
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.add_theme_font_size_override("font_size", 56)
	death_label.add_theme_color_override("font_color", Color("fff59d"))
	death_label.add_theme_color_override("font_outline_color", Color("4e342e"))
	death_label.add_theme_constant_override("outline_size", 14)
	death_label.visible = false
	root.add_child(death_label)

	toast_label = Label.new()
	toast_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toast_label.offset_top = 150
	toast_label.offset_bottom = 210
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 36)
	toast_label.add_theme_color_override("font_outline_color", Color.BLACK)
	toast_label.add_theme_constant_override("outline_size", 10)
	toast_label.visible = false
	root.add_child(toast_label)

	hint_panel = PanelContainer.new()
	hint_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint_panel.offset_top = 120
	hint_panel.offset_left = 16
	hint_panel.offset_right = -16
	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(1, 0.97, 0.8, 0.92)
	hs.set_corner_radius_all(14)
	hs.set_content_margin_all(14)
	hint_panel.add_theme_stylebox_override("panel", hs)
	hint_label = Label.new()
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 26)
	hint_label.add_theme_color_override("font_color", Color("4e342e"))
	hint_panel.add_child(hint_label)
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_panel.visible = false
	root.add_child(hint_panel)

	clear_panel = PanelContainer.new()
	clear_panel.set_anchors_preset(Control.PRESET_CENTER)
	clear_panel.custom_minimum_size = Vector2(560, 0)
	clear_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	clear_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(1, 0.98, 0.9, 0.95)
	cs.set_corner_radius_all(20)
	cs.set_content_margin_all(28)
	clear_panel.add_theme_stylebox_override("panel", cs)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 16)
	clear_panel.add_child(cv)
	clear_label = Label.new()
	clear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clear_label.add_theme_color_override("font_color", Color("3e2723"))
	cv.add_child(clear_label)
	next_button = _button("つぎへ", func() -> void: next_pressed.emit(), true)
	next_button.visible = has_next
	cv.add_child(next_button)
	cv.add_child(_button("もういちど", func() -> void: restart_pressed.emit(), true))
	cv.add_child(_button("メニュー", func() -> void: menu_pressed.emit(), true))
	clear_panel.visible = false
	root.add_child(clear_panel)

	tuning = TuningPanel.new()
	tuning.visible = false
	root.add_child(tuning)
	tuning.applied.connect(func() -> void:
		stick.enabled = true
		tuning_applied.emit())
	tuning.closed.connect(func() -> void: stick.enabled = true)


func _button(text: String, cb: Callable, wide: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0 if wide else 88, 88)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


func is_paused() -> bool:
	return tuning.visible


func open_tuning() -> void:
	tuning.refresh()
	tuning.visible = true
	stick.enabled = false
	stick.release_all()


func set_misses(deaths: int, elapsed: float) -> void:
	miss_label.text = "ミス ×%d   %d秒" % [deaths, int(elapsed)]


func show_death(part: String, text: String) -> void:
	death_label.text = "%s！\n%s" % [part, text]
	death_label.visible = true


func hide_death() -> void:
	death_label.visible = false


func show_hint(text: String) -> void:
	hint_label.text = "ヒント：" + text
	hint_panel.visible = true


func hide_hint() -> void:
	hint_panel.visible = false


func toast(text: String) -> void:
	toast_label.text = text
	toast_label.visible = true
	toast_t = 1.2


func show_clear(deaths: int, elapsed: float) -> void:
	var title := "しぶといイモムシ" if deaths >= 10 else ("ねばりづよいイモムシ" if deaths >= 3 else "すなおなイモムシ")
	clear_label.text = "クリア！\nぜんしん はいった\n\nミス ×%d\nタイム %d秒\n「%s」" % [deaths, int(elapsed), title]
	clear_panel.visible = true
	stick.enabled = false
	stick.release_all()


func hide_clear() -> void:
	clear_panel.visible = false
	stick.enabled = true


func _process(delta: float) -> void:
	if toast_t > 0.0:
		toast_t -= delta
		if toast_t <= 0.0:
			toast_label.visible = false
