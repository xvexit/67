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
var difficulty_interval: float = 15.0

# ---- 67 момент: мульти-клик, штраф при истечении если 0 кликов ----
var is_waiting_for_sixtyseven: bool = false
var current_sixtyseven_button = null


func init(blackboard, classroom, ui):
	blackboard_node = blackboard
	classroom_node = classroom
	ui_node = ui
	
	blackboard_node.game_manager = self
	
	blackboard_node.connect("number_clicked", _on_number_clicked)
	blackboard_node.connect("number_expired", _on_number_expired)
	blackboard_node.connect("number_spawned", _on_number_spawned)
	
	ui_node.update_money(money)
	ui_node.update_rage(0)
	ui_node.update_score(0)


func start_game():
	game_active = true
	game_time = 0.0
	difficulty_timer = 0.0
	money = 0
	rage = 0.0
	difficulty_level = 1
	
	_apply_difficulty()
	
	print("=== ИГРА НАЧАТА! ===")


func _process(delta):
	if not game_active:
		return
	
	game_time += delta
	difficulty_timer += delta
	
	ui_node.update_score(int(game_time))
	
	if difficulty_timer >= difficulty_interval:
		difficulty_timer = 0.0
		difficulty_level += 1
		_apply_difficulty()
		print("Сложность повышена до уровня ", difficulty_level)
	
	rage -= delta * 0.05
	rage = clamp(rage, 0.0, max_rage)
	ui_node.update_rage(rage / max_rage)


func _apply_difficulty():
	var spawn_interval = max(0.5, base_spawn_interval - (difficulty_level - 1) * 0.15)
	var number_lifetime = max(1.5, base_number_lifetime - (difficulty_level - 1) * 0.15)
	var sixtyseven_chance = min(0.5, base_sixtyseven_chance + (difficulty_level - 1) * 0.03)
	
	blackboard_node.update_difficulty(spawn_interval, number_lifetime, sixtyseven_chance)


func _on_number_spawned(_number_value: int):
	if not game_active:
		return
	classroom_node.teacher_write_number()


# ============================================================
# КЛИК ПО ЧИСЛУ — мульти-клик для 67
# ============================================================
func _on_number_clicked(number_value: int, button_ref):
	if not game_active:
		return
	if not is_instance_valid(button_ref):
		return
	
	print("Клик по числу: ", number_value)
	
	if number_value == 67:
		_on_sixtyseven_clicked(button_ref)
	else:
		_wrong_number_clicked(button_ref)


# ============================================================
# КЛИК ПО 67 — ESCALATING REWARDS
# Каждый клик: +деньги +rage
# Чем больше кликов по одному 67, тем выше награда
# ============================================================
func _on_sixtyseven_clicked(button_ref):
	var click_count = button_ref.get_meta("click_count", 0)
	if click_count == 0:
		click_count = 1
	print("67 клик #", click_count)
	
# ---- Rage level (1-7) определяет множитель денег ----
	var segment = max_rage / 7.0
	var rage_level = min(floor(rage / segment), 6) + 1
	
# ---- Escalating money × rage level multiplier ----
	var base_gain = 5 + click_count * 5
	var money_gain = int(base_gain * rage_level)
	money += money_gain
	ui_node.update_money(money)
	
# ---- Slow escalating rage ----
	var rage_gain = 1.0 + click_count * 0.2
	rage += rage_gain
	rage = clamp(rage, 0.0, max_rage)
	ui_node.update_rage(rage / max_rage)
	
# ---- Визуальные реакции ----
	if click_count <= 2:
		classroom_node.do_sixtyseven_moment(rage / max_rage)
		classroom_node.teacher_on_sixtyseven_clicked()
	else:
		var intensity = min(click_count - 2, 5)
		for _i in range(intensity):
			classroom_node.do_class_laugh(rage / max_rage)
	
	classroom_node.teacher_increase_rage(rage / max_rage)
	
	ui_node.show_status("+" + str(money_gain))
	
	if rage >= max_rage:
		_game_over()


# ============================================================
# ПРОМАХ - НЕ ТО ЧИСЛО
# ============================================================
func _wrong_number_clicked(button_ref):
	print("Промах! Не то число.")
	
	rage -= 2.0
	rage = clamp(rage, 0.0, max_rage)
	ui_node.update_rage(rage / max_rage)
	
	ui_node.show_status("MISS!")
	classroom_node.do_class_laugh(rage / max_rage)
	classroom_node.teacher_on_miss()
	classroom_node.teacher_increase_rage(rage / max_rage)
	
	if button_ref and is_instance_valid(button_ref):
		button_ref.queue_free()


# ============================================================
# ПРОМАХ - 67 ИСТЕКЛО
# Штраф только если игрок ни разу не кликнул по этой 67
# ============================================================
func _missed_sixtyseven():
	if not is_waiting_for_sixtyseven:
		return
	print("Промах! 67 пропущено.")
	
	is_waiting_for_sixtyseven = false
	current_sixtyseven_button = null
	
	rage -= 3.0
	rage = clamp(rage, 0.0, max_rage)
	ui_node.update_rage(rage / max_rage)
	
	ui_node.show_status("MISSED 67!")
	classroom_node.do_class_laugh(rage / max_rage)
	classroom_node.teacher_on_miss()
	classroom_node.teacher_increase_rage(rage / max_rage)


func on_sixtyseven_appeared(button_ref, _timeout: float):
	current_sixtyseven_button = button_ref
	is_waiting_for_sixtyseven = true


func _on_number_expired(number_value: int, button_ref):
	if number_value == 67 and is_instance_valid(button_ref) and button_ref == current_sixtyseven_button:
		var clicks = button_ref.get_meta("click_count", 0)
		if clicks == 0:
			_missed_sixtyseven()


func _game_over():
	game_active = false
	blackboard_node.stop_generation()
	ui_node.show_game_over(money, int(game_time))
	print("=== GAME OVER! Денег: %d, Время: %dс ===" % [money, int(game_time)])
