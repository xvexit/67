# ============================================================
# UI.GD - Интерфейс пользователя
#
# Показывает:
# - Счетчик денег (сверху слева)
# - Rage meter (сверху справа)
# - Время игры (снизу слева)
# - Статусные сообщения (67!, MISS!, MISSED 67!)
# - Game Over экран
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


# ============================================================
# ПОСТРОЕНИЕ UI
# ============================================================
func build():
	# Получаем размер вьюпорта для позиционирования
	var viewport_size = get_viewport().get_visible_rect().size
	
	# --- ДЕНЬГИ (сверху слева) ---
	money_label = Label.new()
	money_label.name = "MoneyLabel"
	money_label.text = "$0"
	money_label.position = Vector2(20, 20)
	money_label.add_theme_font_size_override("font_size", 36)
	money_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	money_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	money_label.add_theme_constant_override("outline_size", 4)
	add_child(money_label)
	
	# --- RAGE METER (сверху справа) ---
	var bar_margin = 20
	var bar_width = 30
	var bar_height = 200
	
	# Фон бара
	rage_bar_bg = ColorRect.new()
	rage_bar_bg.name = "RageBarBg"
	rage_bar_bg.position = Vector2(viewport_size.x - bar_width - bar_margin, bar_margin)
	rage_bar_bg.size = Vector2(bar_width, bar_height)
	rage_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	add_child(rage_bar_bg)
	
	# Полоска rage (заполняется снизу вверх)
	rage_bar = ColorRect.new()
	rage_bar.name = "RageBar"
	rage_bar.position = Vector2(viewport_size.x - bar_width - bar_margin + 2, bar_margin + bar_height - 2)
	rage_bar.size = Vector2(bar_width - 4, 0)
	rage_bar.color = Color(1.0, 0.15, 0.05)
	add_child(rage_bar)
	
	# Текст "RAGE"
	rage_label = Label.new()
	rage_label.name = "RageLabel"
	rage_label.text = "RAGE"
	rage_label.position = Vector2(viewport_size.x - bar_width - bar_margin - 5, bar_margin + bar_height + 5)
	rage_label.add_theme_font_size_override("font_size", 14)
	rage_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	add_child(rage_label)
	
	# --- ВРЕМЯ (снизу слева) ---
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Time: 0s"
	score_label.position = Vector2(20, viewport_size.y - 40)
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(score_label)
	
	# --- СТАТУС (центр экрана) ---
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = ""
	status_label.position = Vector2(viewport_size.x / 2 - 100, viewport_size.y / 2 - 50)
	status_label.add_theme_font_size_override("font_size", 72)
	status_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))
	status_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	status_label.add_theme_constant_override("outline_size", 6)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.visible = false
	add_child(status_label)
	
	# --- GAME OVER PANEL (скрыт изначально) ---
	game_over_panel = Panel.new()
	game_over_panel.name = "GameOverPanel"
	game_over_panel.position = Vector2(viewport_size.x / 2 - 150, viewport_size.y / 2 - 100)
	game_over_panel.size = Vector2(300, 200)
	game_over_panel.visible = false
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	game_over_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(game_over_panel)
	
	# Заголовок Game Over
	var game_over_title = Label.new()
	game_over_title.name = "GameOverTitle"
	game_over_title.text = "GAME OVER"
	game_over_title.position = Vector2(50, 20)
	game_over_title.add_theme_font_size_override("font_size", 36)
	game_over_title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1))
	game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_panel.add_child(game_over_title)
	
	# Финальные деньги
	final_money_label = Label.new()
	final_money_label.name = "FinalMoneyLabel"
	final_money_label.text = "Money: $0"
	final_money_label.position = Vector2(50, 70)
	final_money_label.add_theme_font_size_override("font_size", 24)
	final_money_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	final_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_panel.add_child(final_money_label)
	
	# Финальное время
	final_time_label = Label.new()
	final_time_label.name = "FinalTimeLabel"
	final_time_label.text = "Time: 0s"
	final_time_label.position = Vector2(50, 100)
	final_time_label.add_theme_font_size_override("font_size", 24)
	final_time_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	final_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_panel.add_child(final_time_label)
	
	# Кнопка рестарта
	restart_button = Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "PLAY AGAIN"
	restart_button.position = Vector2(75, 140)
	restart_button.size = Vector2(150, 40)
	restart_button.pressed.connect(_restart_game)
	game_over_panel.add_child(restart_button)


# ============================================================
# ОБНОВЛЕНИЕ RAGE BAR
# value: 0.0 - 1.0
# ============================================================
func update_rage(value: float):
	if not is_instance_valid(rage_bar) or not is_instance_valid(rage_bar_bg):
		return
	
	var bar_height = rage_bar_bg.size.y - 4
	var filled_height = bar_height * clamp(value, 0.0, 1.0)
	
	# Заполняем снизу вверх
	rage_bar.size.y = filled_height
	rage_bar.position.y = rage_bar_bg.position.y + bar_height - filled_height
	
	# Меняем цвет в зависимости от уровня
	if value < 0.3:
		rage_bar.color = Color(0.2, 0.8, 0.2)
	elif value < 0.6:
		rage_bar.color = Color(1.0, 0.7, 0.1)
	else:
		rage_bar.color = Color(1.0, 0.1, 0.05)


# ============================================================
# ОБНОВЛЕНИЕ ДЕНЕГ
# ============================================================
func update_money(value: int):
	if not is_instance_valid(money_label):
		return
	
	money_label.text = "$" + str(value)


# ============================================================
# ОБНОВЛЕНИЕ ВРЕМЕНИ
# ============================================================
func update_score(value: int):
	if not is_instance_valid(score_label):
		return
	
	score_label.text = "Time: " + str(value) + "s"


# ============================================================
# ПОКАЗ СТАТУСА (67!, MISS!, MISSED 67!)
# ============================================================
func show_status(text: String):
	if not is_instance_valid(status_label):
		return
	
	status_label.text = text
	status_label.visible = true
	status_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# Анимация появления и исчезновения
	var tween = get_tree().create_tween()
	tween.tween_property(status_label, "modulate:a", 1.0, 0.1)
	tween.tween_interval(0.8)
	tween.tween_property(status_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): status_label.visible = false)
	
	# Для 67 делаем особый цвет
	if text == "67!":
		status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	elif "MISS" in text:
		status_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))


# ============================================================
# GAME OVER ЭКРАН
# ============================================================
func show_game_over(final_money: int, final_time: int):
	if not is_instance_valid(game_over_panel):
		return
	
	if is_instance_valid(final_money_label):
		final_money_label.text = "Money: $" + str(final_money)
	
	if is_instance_valid(final_time_label):
		final_time_label.text = "Time: " + str(final_time) + "s"
	
	game_over_panel.visible = true


# ============================================================
# РЕСТАРТ ИГРЫ
# ============================================================
func _restart_game():
	# Перезагружаем сцену
	get_tree().reload_current_scene()
