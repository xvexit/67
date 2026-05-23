# ============================================================
# GAME_MANAGER.GD - Главный игровой менеджер
# 
# Управляет:
# - Игровым циклом и сложностью
# - Rage meter учителя
# - Деньгами игрока
# - Связью между доской, классом и UI
# - Обработкой 67 moment и промахов
# ============================================================

extends Node


# ---- Ссылки на другие системы ----
var blackboard_node: Node
var classroom_node: Node
var ui_node: Node

# ---- Игровые параметры ----
var money: int = 0
var rage: float = 0.0
var max_rage: float = 100.0
var game_time: float = 0.0
var game_active: bool = false
var difficulty_level: int = 1

# ---- Параметры сложности (базовые) ----
var base_spawn_interval: float = 2.5
var base_number_lifetime: float = 3.5
var base_sixtyseven_chance: float = 0.1

# ---- Таймеры ----
var difficulty_timer: float = 0.0
var difficulty_interval: float = 15.0  # каждые 15 секунд сложность растет

# ---- 67 moment состояние ----
var current_sixtyseven_button = null
var sixtyseven_timer: float = 0.0
var sixtyseven_timeout: float = 0.0
var is_waiting_for_sixtyseven: bool = false


# ============================================================
# ИНИЦИАЛИЗАЦИЯ
# Сохраняем ссылки на компоненты
# ============================================================
func init(blackboard, classroom, ui):
	blackboard_node = blackboard
	classroom_node = classroom
	ui_node = ui
	
	# Пробрасываем ссылку (blackboard.build() не нашёл GameManager — он ещё не существовал)
	blackboard_node.game_manager = self
	
	# Подключаем сигналы от доски
	blackboard_node.connect("number_clicked", _on_number_clicked)
	blackboard_node.connect("number_expired", _on_number_expired)
	blackboard_node.connect("number_spawned", _on_number_spawned)
	
	# Обновляем UI начальными значениями
	ui_node.update_money(money)
	ui_node.update_rage(0)
	ui_node.update_score(0)


# ============================================================
# ЗАПУСК ИГРЫ
# ============================================================
func start_game():
	game_active = true
	game_time = 0.0
	difficulty_timer = 0.0
	money = 0
	rage = 0.0
	difficulty_level = 1
	
	# Запускаем генерацию чисел на доске с начальными параметрами
	_apply_difficulty()
	
	print("=== ИГРА НАЧАТА! ===")


# ============================================================
# ИГРОВОЙ ЦИКЛ (каждый кадр)
# ============================================================
func _process(delta):
	if not game_active:
		return
	
	# Считаем время игры
	game_time += delta
	difficulty_timer += delta
	
	# Обновляем UI время
	ui_node.update_score(int(game_time))
	
	# Каждые difficulty_interval секунд повышаем сложность
	if difficulty_timer >= difficulty_interval:
		difficulty_timer = 0.0
		difficulty_level += 1
		_apply_difficulty()
		print("Сложность повышена до уровня ", difficulty_level)
	
	# Обновляем таймер ожидания клика по 67
	if is_waiting_for_sixtyseven and current_sixtyseven_button != null:
		sixtyseven_timer += delta
		if sixtyseven_timer >= sixtyseven_timeout:
			# Время вышло - игрок не кликнул 67
			_missed_sixtyseven()
	
	# Очень медленный пассивный прирост (чтобы шкала не пустовала)
	rage += delta * 0.15
	rage = clamp(rage, 0.0, max_rage)
	ui_node.update_rage(rage / max_rage)


# ============================================================
# ПРИМЕНЕНИЕ СЛОЖНОСТИ
# С каждым уровнем увеличивается скорость и шанс 67
# ============================================================
func _apply_difficulty():
	var spawn_interval = max(0.5, base_spawn_interval - (difficulty_level - 1) * 0.15)
	var number_lifetime = max(1.5, base_number_lifetime - (difficulty_level - 1) * 0.15)
	var sixtyseven_chance = min(0.5, base_sixtyseven_chance + (difficulty_level - 1) * 0.03)
	
	blackboard_node.update_difficulty(spawn_interval, number_lifetime, sixtyseven_chance)


# ============================================================
# НОВОЕ ЧИСЛО НА ДОСКЕ — учитель пишет мелом
# ============================================================
func _on_number_spawned(_number_value: int):
	if not game_active:
		return
	classroom_node.teacher_write_number()


# ============================================================
# КЛИК ПО ЧИСЛУ НА ДОСКЕ
# ============================================================
func _on_number_clicked(number_value: int, button_ref):
	if not game_active:
		return
	
	# Защита от повторной обработки одного и того же числа
	if not is_instance_valid(button_ref):
		return
	
	print("Клик по числу: ", number_value)
	
	if number_value == 67:
		# Дополнительная проверка - кликаем только по активному 67
		if not is_waiting_for_sixtyseven or button_ref != current_sixtyseven_button:
			return
		# УСПЕХ! Игрок кликнул 67
		_successful_sixtyseven(button_ref)
	else:
		# ПРОМАХ! Игрок кликнул не то число
		_wrong_number_clicked(button_ref)


# ============================================================
# УСПЕШНЫЙ 67 MOMENT
# ============================================================
func _successful_sixtyseven(button_ref):
	print("=== 67 MOMENT! ===")
	
	# Сбрасываем ожидание 67
	is_waiting_for_sixtyseven = false
	current_sixtyseven_button = null
	
	# Награда деньгами
	var reward = 50 + difficulty_level * 10
	money += reward
	ui_node.update_money(money)
	
	# Повышаем rage meter (+20 за каждый клик по 67)
	rage += 20.0
	rage = clamp(rage, 0.0, max_rage)
	ui_node.update_rage(rage / max_rage)
	
	# Визуальный эффект 67 moment
	ui_node.show_status("67!")
	classroom_node.do_sixtyseven_moment(rage / max_rage)
	classroom_node.teacher_on_sixtyseven_clicked()
	classroom_node.teacher_increase_rage(rage / max_rage)
	
	# Удаляем кнопку 67 с доски
	if button_ref and is_instance_valid(button_ref):
		button_ref.queue_free()
	
	# Проверка на максимальный rage
	if rage >= max_rage:
		_game_over()


# ============================================================
# ПРОМАХ - НЕ ТО ЧИСЛО
# ============================================================
func _wrong_number_clicked(button_ref):
	print("Промах! Не то число.")
	
	# Наказываем убиранием rage
	rage -= 8.0
	rage = clamp(rage, 0.0, max_rage)
	ui_node.update_rage(rage / max_rage)
	
	# Визуальный эффект
	ui_node.show_status("MISS!")
	classroom_node.do_class_laugh(rage / max_rage)
	classroom_node.teacher_on_miss()
	classroom_node.teacher_increase_rage(rage / max_rage)
	
	# Удаляем кнопку
	if button_ref and is_instance_valid(button_ref):
		button_ref.queue_free()


# ============================================================
# ПРОМАХ - НЕ УСПЕЛ КЛИКНУТЬ 67 (таймер истек)
# ============================================================
func _missed_sixtyseven():
	print("Промах! 67 пропущено.")
	
	is_waiting_for_sixtyseven = false
	current_sixtyseven_button = null
	
	# Наказываем
	rage -= 15.0
	rage = clamp(rage, 0.0, max_rage)
	ui_node.update_rage(rage / max_rage)
	
	# Визуальный эффект
	ui_node.show_status("MISSED 67!")
	classroom_node.do_class_laugh(rage / max_rage)
	classroom_node.teacher_on_miss()
	classroom_node.teacher_increase_rage(rage / max_rage)


# ============================================================
# ПОЯВЛЕНИЕ ЧИСЛА 67 НА ДОСКЕ
# Вызывается из blackboard.gd когда появляется 67
# ============================================================
func on_sixtyseven_appeared(button_ref, timeout: float):
	current_sixtyseven_button = button_ref
	sixtyseven_timer = 0.0
	sixtyseven_timeout = timeout
	is_waiting_for_sixtyseven = true


# ============================================================
# ЧИСЛО ИСТЕКЛО (само исчезло)
# ============================================================
func _on_number_expired(number_value: int, button_ref):
	if number_value == 67 and is_waiting_for_sixtyseven and button_ref == current_sixtyseven_button:
		_missed_sixtyseven()


# ============================================================
# GAME OVER
# ============================================================
func _game_over():
	game_active = false
	blackboard_node.stop_generation()
	ui_node.show_game_over(money, int(game_time))
	print("=== GAME OVER! Денег: %d, Время: %dс ===" % [money, int(game_time)])
