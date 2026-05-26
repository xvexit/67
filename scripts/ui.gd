# ============================================================
# UI.GD - Интерфейс пользователя
#
# Responsive anchors-based layout:
# - Rage bar: прижат к правому краю, растянут по высоте
# - Money: верхний левый угол
# - Время: нижний левый угол
# - Статус: центр
# - Game Over: центр
#
# Работает на любом разрешении / соотношении сторон.
# ============================================================

extends CanvasLayer


# ---- UI элементы ----
var money_label: Label
var rage_bar_bg: ColorRect
var rage_bar: ColorRect
var rage_label: Label
var score_label: Label
var status_label: Label
var game_over_panel: Panel
var final_money_label: Label
var final_time_label: Label
var restart_button: Button

# ---- Event system ----
var event_warning_label: Label
var event_overlay: ColorRect

# ---- Rage bar параметры ----
const RAGE_BAR_WIDTH := 28
const RAGE_BAR_MARGIN := 16
const RAGE_BAR_HEIGHT_RATIO := 0.45  # 45% высоты экрана

# ---- Rage marks (7 уровней) ----
var rage_marks: Array[ColorRect] = []
var rage_mark_labels: Array[Label] = []

# ---- Анимация rage ----
var _current_rage_value: float = 0.0
var _rage_high: bool = false
var _pulse_tween: Tween = null


func build():
	_create_money_label()
	_create_rage_bar()
	_create_score_label()
	_create_status_label()
	_create_event_overlay()
	_create_event_warning()
	_create_game_over_panel()


# ============================================================
# ДЕНЬГИ — верхний левый угол
# ============================================================
func _create_money_label():
	money_label = Label.new()
	money_label.name = "MoneyLabel"
	money_label.text = "$0"
	
	money_label.add_theme_font_size_override("font_size", 36)
	money_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	money_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	money_label.add_theme_constant_override("outline_size", 4)
	
	# anchors: top-left
	money_label.anchor_left = 0.0
	money_label.anchor_top = 0.0
	money_label.anchor_right = 0.0
	money_label.anchor_bottom = 0.0
	# offset: 16px от левого и верхнего края
	money_label.offset_left = 16
	money_label.offset_top = 16
	
	add_child(money_label)


# ============================================================
# RAGE BAR — прижат к правому краю, высота = 45% экрана
# ============================================================
func _create_rage_bar():
	# ---- Фоновая полоса ----
	rage_bar_bg = ColorRect.new()
	rage_bar_bg.name = "RageBarBg"
	rage_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	
	# Прижат к правому краю, вертикально по центру
	rage_bar_bg.anchor_left = 1.0
	rage_bar_bg.anchor_top = 0.5
	rage_bar_bg.anchor_right = 1.0
	rage_bar_bg.anchor_bottom = 0.5
	
	# Ширина и высота через offset
	rage_bar_bg.offset_left = -(RAGE_BAR_WIDTH + RAGE_BAR_MARGIN)
	rage_bar_bg.offset_top = -(RAGE_BAR_HEIGHT_RATIO * 0.5 * get_viewport().size.y)
	rage_bar_bg.offset_right = -RAGE_BAR_MARGIN
	rage_bar_bg.offset_bottom = RAGE_BAR_HEIGHT_RATIO * 0.5 * get_viewport().size.y
	
	add_child(rage_bar_bg)
	
	# ---- Отметки шкалы (1x-7x) — ДО заполняемой полоски, чтобы быть под ней ----
	_create_rage_marks()
	
	# ---- Заполняемая полоска (снизу вверх) ----
	rage_bar = ColorRect.new()
	rage_bar.name = "RageBar"
	rage_bar.color = Color(0.9, 0.05, 0.0)
	
	# Те же anchors, offset позже пересчитывается динамически
	rage_bar.anchor_left = 1.0
	rage_bar.anchor_top = 0.5
	rage_bar.anchor_right = 1.0
	rage_bar.anchor_bottom = 0.5
	
	rage_bar.offset_left = -(RAGE_BAR_WIDTH + RAGE_BAR_MARGIN) + 2
	rage_bar.offset_right = -RAGE_BAR_MARGIN - 2
	rage_bar.offset_top = 0  # будет пересчитано в update_rage
	
	add_child(rage_bar)
	
	# ---- Текст "RAGE" ----
	rage_label = Label.new()
	rage_label.name = "RageLabel"
	rage_label.text = "RAGE"
	rage_label.add_theme_font_size_override("font_size", 13)
	rage_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	
	# Под полоской, прижат к правому краю
	rage_label.anchor_left = 1.0
	rage_label.anchor_top = 0.5
	rage_label.offset_left = -(RAGE_BAR_WIDTH + RAGE_BAR_MARGIN) - 4
	rage_label.offset_top = RAGE_BAR_HEIGHT_RATIO * 0.5 * get_viewport().size.y + 6
	
	add_child(rage_label)
	
	# Пересчёт rage bar при изменении размера окна
	get_window().size_changed.connect(_on_viewport_size_changed)


# ============================================================
# ОТМЕТКИ ШКАЛЫ RAGE: 1x-7x
# ============================================================
func _create_rage_marks():
	for i in range(7):
		var level = i + 1
		
		var mark = ColorRect.new()
		mark.name = "RageMark_" + str(level)
		mark.color = Color(0.5, 0.5, 0.5, 0.3)
		mark.anchor_left = 1.0
		mark.anchor_top = 0.5
		mark.anchor_right = 1.0
		mark.anchor_bottom = 0.5
		mark.offset_left = -(RAGE_BAR_WIDTH + RAGE_BAR_MARGIN)
		mark.offset_right = -RAGE_BAR_MARGIN
		mark.offset_top = 0
		mark.offset_bottom = 1
		add_child(mark)
		rage_marks.append(mark)
		
		var label = Label.new()
		label.name = "RageMarkLabel_" + str(level)
		label.text = str(level) + "x"
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		label.anchor_left = 1.0
		label.anchor_top = 0.5
		label.offset_left = -(RAGE_BAR_WIDTH + RAGE_BAR_MARGIN) - 22
		label.offset_top = 0
		add_child(label)
		rage_mark_labels.append(label)
	
	_update_rage_marks()


func _update_rage_marks():
	if not is_instance_valid(rage_bar_bg):
		return
	
	var bg_top = rage_bar_bg.offset_top
	var bg_bot = rage_bar_bg.offset_bottom
	var bg_h = bg_bot - bg_top
	var segment_h = bg_h / 7.0
	
	for i in range(7):
		if not is_instance_valid(rage_marks[i]) or not is_instance_valid(rage_mark_labels[i]):
			continue
		var y = bg_bot - segment_h * (i + 1)
		rage_marks[i].offset_top = y
		rage_marks[i].offset_bottom = y + 1
		rage_mark_labels[i].offset_top = y - 8


func _update_rage_level_display(value: float):
	var segment = 1.0 / 7.0
	var level = min(floor(value / segment), 6) + 1
	for i in range(7):
		if not is_instance_valid(rage_mark_labels[i]):
			continue
		if i + 1 == level:
			rage_mark_labels[i].add_theme_font_size_override("font_size", 13)
			rage_mark_labels[i].add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			rage_mark_labels[i].add_theme_font_size_override("font_size", 10)
			rage_mark_labels[i].add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))


# ============================================================
# ВРЕМЯ — нижний левый угол
# ============================================================
func _create_score_label():
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Time: 0s"
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	# bottom-left
	score_label.anchor_left = 0.0
	score_label.anchor_bottom = 1.0
	score_label.anchor_right = 0.0
	score_label.anchor_top = 1.0
	
	score_label.offset_left = 16
	score_label.offset_bottom = -16
	
	add_child(score_label)


# ============================================================
# СТАТУС (67!, MISS!, MISSED 67!) — центр экрана
# ============================================================
func _create_status_label():
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = ""
	
	status_label.add_theme_font_size_override("font_size", 72)
	status_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))
	status_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	status_label.add_theme_constant_override("outline_size", 6)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.visible = false
	
	# Центр экрана
	status_label.anchor_left = 0.0
	status_label.anchor_top = 0.0
	status_label.anchor_right = 1.0
	status_label.anchor_bottom = 1.0
	
	add_child(status_label)


# ============================================================
# GAME OVER PANEL — центр экрана
# ============================================================
func _create_game_over_panel():
	game_over_panel = Panel.new()
	game_over_panel.name = "GameOverPanel"
	game_over_panel.visible = false
	
	# Центрируем: anchors 0.0-1.0, размер через offset
	game_over_panel.anchor_left = 0.5
	game_over_panel.anchor_top = 0.5
	game_over_panel.anchor_right = 0.5
	game_over_panel.anchor_bottom = 0.5
	
	game_over_panel.offset_left = -150
	game_over_panel.offset_top = -120
	game_over_panel.offset_right = 150
	game_over_panel.offset_bottom = 120
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	game_over_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(game_over_panel)
	
	var game_over_title = Label.new()
	game_over_title.text = "GAME OVER"
	game_over_title.add_theme_font_size_override("font_size", 36)
	game_over_title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1))
	game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_title.anchor_left = 0.0
	game_over_title.anchor_top = 0.0
	game_over_title.anchor_right = 1.0
	game_over_title.offset_top = 20
	game_over_title.offset_bottom = 60
	game_over_panel.add_child(game_over_title)
	
	final_money_label = Label.new()
	final_money_label.text = "Money: $0"
	final_money_label.add_theme_font_size_override("font_size", 24)
	final_money_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	final_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_money_label.anchor_left = 0.0
	final_money_label.anchor_top = 0.0
	final_money_label.anchor_right = 1.0
	final_money_label.offset_top = 70
	final_money_label.offset_bottom = 100
	game_over_panel.add_child(final_money_label)
	
	final_time_label = Label.new()
	final_time_label.text = "Time: 0s"
	final_time_label.add_theme_font_size_override("font_size", 24)
	final_time_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	final_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_time_label.anchor_left = 0.0
	final_time_label.anchor_top = 0.0
	final_time_label.anchor_right = 1.0
	final_time_label.offset_top = 100
	final_time_label.offset_bottom = 130
	game_over_panel.add_child(final_time_label)
	
	restart_button = Button.new()
	restart_button.text = "PLAY AGAIN"
	restart_button.size = Vector2(150, 40)
	restart_button.pressed.connect(_restart_game)
	restart_button.anchor_left = 0.5
	restart_button.anchor_top = 0.5
	restart_button.offset_left = -75
	restart_button.offset_top = 40
	game_over_panel.add_child(restart_button)


# ============================================================
# ПЕРЕСЧЁТ RAGE BAR ПРИ ИЗМЕНЕНИИ РАЗМЕРА ОКНА
# ============================================================
func _on_viewport_size_changed():
	if not is_instance_valid(rage_bar_bg) or not is_instance_valid(rage_label):
		return
	
	var vp_h = get_viewport().size.y
	var bar_h = int(vp_h * RAGE_BAR_HEIGHT_RATIO)
	
	rage_bar_bg.offset_top = -bar_h / 2
	rage_bar_bg.offset_bottom = bar_h / 2
	
	rage_label.offset_top = bar_h / 2 + 6
	
	_update_rage_bar_position()
	_update_rage_marks()


func _update_rage_bar_position():
	if not is_instance_valid(rage_bar) or not is_instance_valid(rage_bar_bg):
		return
	
	var bg_top = rage_bar_bg.offset_top
	var bg_bot = rage_bar_bg.offset_bottom
	var bg_h = bg_bot - bg_top
	var filled_h = bg_h * _current_rage_value
	
	rage_bar.offset_top = bg_bot - filled_h
	rage_bar.offset_bottom = bg_bot


# ============================================================
# ОБНОВЛЕНИЕ RAGE BAR
# value: 0.0 - 1.0
# Smooth tween + pulse на high rage
# ============================================================
func update_rage(value: float):
	if not is_instance_valid(rage_bar) or not is_instance_valid(rage_bar_bg):
		return
	
	value = clamp(value, 0.0, 1.0)
	
	# Smooth tween к целевому значению
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_method(_set_rage_fill, _current_rage_value, value, 0.15)
	
	_server_rage_color(value)
	_handle_pulse(value)
	_update_rage_level_display(value)


func _set_rage_fill(value: float):
	_current_rage_value = value
	_update_rage_bar_position()


func _server_rage_color(_value: float):
	rage_bar.color = Color(0.9, 0.05, 0.0)


func _handle_pulse(value: float):
	if value < 0.7:
		_rage_high = false
		if _pulse_tween and _pulse_tween.is_valid():
			_pulse_tween.kill()
		rage_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
		return
	
	if not _rage_high:
		_rage_high = true
		_start_pulse()


func _start_pulse():
	if not is_instance_valid(rage_bar_bg):
		return
	
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.set_trans(Tween.TRANS_SINE)
	
	_pulse_tween.tween_property(rage_bar_bg, "color", Color(0.4, 0.1, 0.1, 0.85), 0.4)
	_pulse_tween.tween_property(rage_bar_bg, "color", Color(0.2, 0.2, 0.2, 0.8), 0.4)


# ============================================================
# ДЕНЬГИ
# ============================================================
func update_money(value: int):
	if not is_instance_valid(money_label):
		return
	money_label.text = "$" + str(value)


# ============================================================
# ВРЕМЯ
# ============================================================
func update_score(value: int):
	if not is_instance_valid(score_label):
		return
	score_label.text = "Time: " + str(value) + "s"


# ============================================================
# СТАТУС (67!, MISS!, MISSED 67!)
# ============================================================
func show_status(text: String):
	if not is_instance_valid(status_label):
		return
	
	status_label.text = text
	status_label.visible = true
	status_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	if text == "67!":
		status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	elif "MISS" in text:
		status_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	
	var tween = get_tree().create_tween()
	tween.tween_property(status_label, "modulate:a", 1.0, 0.1)
	tween.tween_interval(0.8)
	tween.tween_property(status_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_hide_status)


func _hide_status():
	if is_instance_valid(status_label):
		status_label.visible = false


# ============================================================
# GAME OVER
# ============================================================
func show_game_over(final_money: int, final_time: int):
	if not is_instance_valid(game_over_panel):
		return
	
	if is_instance_valid(final_money_label):
		final_money_label.text = "Money: $" + str(final_money)
	
	if is_instance_valid(final_time_label):
		final_time_label.text = "Time: " + str(final_time) + "s"
	
	game_over_panel.visible = true


func _restart_game():
	get_tree().reload_current_scene()


# ============================================================
# EVENT WARNING — название события крупно по центру
# ============================================================
func _create_event_warning():
	event_warning_label = Label.new()
	event_warning_label.name = "EventWarningLabel"
	event_warning_label.text = ""
	event_warning_label.visible = false

	event_warning_label.add_theme_font_size_override("font_size", 48)
	event_warning_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	event_warning_label.add_theme_constant_override("outline_size", 8)
	event_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	event_warning_label.anchor_left = 0.0
	event_warning_label.anchor_top = 0.0
	event_warning_label.anchor_right = 1.0
	event_warning_label.anchor_bottom = 1.0
	event_warning_label.offset_top = -60

	add_child(event_warning_label)


func show_event_warning(text: String, color: Color):
	if not is_instance_valid(event_warning_label):
		return
	event_warning_label.text = text
	event_warning_label.add_theme_color_override("font_color", color)
	event_warning_label.visible = true
	event_warning_label.modulate = Color(1.0, 1.0, 1.0, 1.0)


func hide_event_warning():
	if is_instance_valid(event_warning_label):
		event_warning_label.visible = false


# ============================================================
# EVENT OVERLAY — цветная вспышка на весь экран
# ============================================================
func _create_event_overlay():
	event_overlay = ColorRect.new()
	event_overlay.name = "EventOverlay"
	event_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	event_overlay.visible = false
	event_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	event_overlay.anchor_left = 0.0
	event_overlay.anchor_top = 0.0
	event_overlay.anchor_right = 1.0
	event_overlay.anchor_bottom = 1.0

	add_child(event_overlay)


func show_event_overlay(color: Color, alpha: float):
	if not is_instance_valid(event_overlay):
		return
	event_overlay.color = Color(color.r, color.g, color.b, alpha)
	event_overlay.visible = true


func hide_event_overlay():
	if is_instance_valid(event_overlay):
		event_overlay.color.a = 0.0
		event_overlay.visible = false
