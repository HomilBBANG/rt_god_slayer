extends CanvasLayer

var hp_bar  : ProgressBar
var sp_bar  : ProgressBar
var mp_bar  : ProgressBar
var exp_lbl : Label
var gold_lbl : Label
var level_lbl : Label

var _player = null

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ── 좌상단 스탯 패널 ──────────────────────────────────
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	panel.custom_minimum_size = Vector2(220, 0)
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	hp_bar  = _make_bar("HP", Color(0.85, 0.15, 0.15), 100.0)
	sp_bar  = _make_bar("SP", Color(0.15, 0.75, 0.25), 100.0)
	mp_bar  = _make_bar("MP", Color(0.25, 0.35, 0.90), 80.0)
	vbox.add_child(hp_bar)
	vbox.add_child(sp_bar)
	vbox.add_child(mp_bar)

	# ── 우하단 골드·EXP ───────────────────────────────────
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hbox.position = Vector2(-220, -50)
	root.add_child(hbox)

	gold_lbl = _make_label("골드: 0")
	exp_lbl  = _make_label("  EXP: 0")
	hbox.add_child(gold_lbl)
	hbox.add_child(exp_lbl)

func _make_bar(label_text: String, color: Color, max_val: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(200, 22)
	bar.max_value = max_val
	bar.value     = max_val
	bar.show_percentage = false

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.1)
	bar.add_theme_stylebox_override("background", bg)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_color_override("font_color", Color.WHITE)
	bar.add_child(lbl)
	return bar

func _make_label(txt: String) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_color_override("font_color", Color.WHITE)
	return lbl

func link_player(p: Node) -> void:
	if _player and _player.stats_changed.is_connected(_on_stats):
		_player.stats_changed.disconnect(_on_stats)
	_player = p
	_player.stats_changed.connect(_on_stats)

func _on_stats(h, mh, s, ms, m, mm) -> void:
	hp_bar.max_value = mh; hp_bar.value = h
	sp_bar.max_value = ms; sp_bar.value = s
	mp_bar.max_value = mm; mp_bar.value = m

func _process(_delta: float) -> void:
	if gold_lbl: gold_lbl.text = "골드: %d" % GameManager.run_gold
	if exp_lbl:  exp_lbl.text  = "  EXP: %d" % GameManager.run_exp
