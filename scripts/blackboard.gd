# ============================================================
# BLACKBOARD.GD - Система генерации чисел на доске
#
# Создает 3D доску с мелом, генерирует числа,
# обрабатывает клики мышкой по числам,
# испускает сигналы для GameManager
# ============================================================

extends Node3D


# ---- Сигналы ----
signal number_clicked(number_value: int, button_ref)
signal number_expired(number_value: int, button_ref)
signal number_spawned(number_value: int)


# ---- Параметры доски ----
var board_width: float = 5.0
var board_height: float = 2.2
var max_numbers: int = 12

# ---- Текущие числа на доске ----
var active_buttons = []

# ---- Параметры генерации ----
var spawn_interval: float = 2.5
var number_lifetime: float = 3.5
var sixtyseven_chance: float = 0.1

# ---- Таймеры ----
var spawn_timer: float = 0.0
var generation_active: bool = true

# ---- Reference to GameManager ----
var game_manager: Node

# ---- Ссылка на тело доски (числа крепятся сюда) ----
var board_body: Node3D


# ============================================================
# ПОСТРОЕНИЕ ДОСКИ
# ============================================================
func build():
	# Создаем физическое тело доски (чтобы был коллайдер)
	board_body = StaticBody3D.new()
	board_body.name = "BoardBody"
	
	var board_collision = CollisionShape3D.new()
	var board_shape = BoxShape3D.new()
	board_shape.size = Vector3(board_width, board_height, 0.1)
	board_collision.shape = board_shape
	board_body.add_child(board_collision)
	
	# Визуальная часть доски
	var board_mesh = MeshInstance3D.new()
	board_mesh.name = "BoardMesh"
	board_mesh.mesh = BoxMesh.new()
	board_mesh.mesh.size = Vector3(board_width, board_height, 0.05)
	var board_mat = StandardMaterial3D.new()
	board_mat.albedo_color = Color(0.08, 0.12, 0.06)
	board_mat.metallic = 0.0
	board_mat.roughness = 0.9
	board_mesh.mesh.material = board_mat
	board_body.add_child(board_mesh)
	
	# Рамка доски
	var frame_mesh = MeshInstance3D.new()
	frame_mesh.name = "BoardFrame"
	frame_mesh.mesh = BoxMesh.new()
	frame_mesh.mesh.size = Vector3(board_width + 0.3, 0.08, 0.08)
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.5, 0.3, 0.1)
	frame_mesh.mesh.material = frame_mat
	
	# Верхняя и нижняя рамка
	var frame_top = frame_mesh.duplicate()
	frame_top.position = Vector3(0.0, board_height / 2.0 + 0.04, 0.03)
	board_body.add_child(frame_top)
	
	var frame_bottom = frame_mesh.duplicate()
	frame_bottom.position = Vector3(0.0, -board_height / 2.0 - 0.04, 0.03)
	board_body.add_child(frame_bottom)
	
	# Боковые рамки
	var side_frame_mesh = BoxMesh.new()
	side_frame_mesh.size = Vector3(0.08, board_height + 0.16, 0.08)
	side_frame_mesh.material = frame_mat
	
	var frame_left = MeshInstance3D.new()
	frame_left.mesh = side_frame_mesh
	frame_left.position = Vector3(-board_width / 2.0 - 0.04, 0.0, 0.03)
	board_body.add_child(frame_left)
	
	var frame_right = MeshInstance3D.new()
	frame_right.mesh = side_frame_mesh
	frame_right.position = Vector3(board_width / 2.0 + 0.04, 0.0, 0.03)
	board_body.add_child(frame_right)
	
	# Позиция доски в классе
	board_body.position = Vector3(0.0, 1.7, -2.8)
	add_child(board_body)
	
	# Находим GameManager (создается позже, используем or_null)
	game_manager = get_node_or_null("/root/Main/GameManager")


# ============================================================
# ИГРОВОЙ ЦИКЛ ГЕНЕРАЦИИ (каждый кадр)
# ============================================================
func _process(delta):
	if not generation_active:
		return
	
	# Накапливаем время и спавним числа
	# Используем while чтобы не терять время при больших delta
	spawn_timer += delta
	while spawn_timer >= spawn_interval and generation_active:
		spawn_timer -= spawn_interval
		_spawn_number()


# ============================================================
# СОЗДАНИЕ НОВОГО ЧИСЛА НА ДОСКЕ
# ============================================================
func _spawn_number():
	# Проверяем, не превышен ли лимит чисел
	if active_buttons.size() >= max_numbers:
		# Удаляем самое старое число
		var oldest = active_buttons.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	
	# Определяем, будет ли это число 67
	var is_sixtyseven = randf() < sixtyseven_chance
	
	var number_value: int
	if is_sixtyseven:
		number_value = 67
	else:
		# Генерируем случайное число от 1 до 99, но не 67
		number_value = randi() % 98 + 1
		if number_value == 67:
			number_value = 68
	
	# Создаем визуальный элемент числа
	var number_button = _create_number_button(number_value)
	
	# Позиционируем на доске
	var pos = _get_random_board_position()
	number_button.position = pos
	
	# Добавляем как дочерний элемент доски (на её поверхность)
	board_body.add_child(number_button)
	active_buttons.append(number_button)
	
	# Сигнал о новом числе (для анимации учителя)
	number_spawned.emit(number_value)
	
	# Если это 67 - уведомляем GameManager
	if is_sixtyseven and game_manager:
		game_manager.on_sixtyseven_appeared(number_button, number_lifetime)
	
	# Удаляем через number_lifetime секунд
	var lifetime_timer = get_tree().create_timer(number_lifetime)
	lifetime_timer.timeout.connect(_on_number_timeout.bind(number_button, number_value))


# ============================================================
# СОЗДАНИЕ КНОПКИ-ЧИСЛА
# 3D объект с Label3D и Area3D для клика
# ============================================================
func _create_number_button(value: int) -> Node3D:
	var button = Node3D.new()
	button.name = "Number_" + str(value)
	
	# ---- Label3D с числом (стиль мела на доске) ----
	var label = Label3D.new()
	label.name = "Label"
	label.text = str(value)
	label.outline_size = 1
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.3)
	
	if value == 67:
		label.modulate = Color(1.0, 0.25, 0.1)
		label.font_size = 44
	else:
		label.modulate = Color(0.9, 0.92, 0.95)
		label.font_size = 34
	
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.pixel_size = 0.004
	button.add_child(label)
	
	# ---- Область для клика ----
	var area = Area3D.new()
	area.name = "ClickArea"
	area.input_ray_pickable = true
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.4, 0.2, 0.02)
	collision.shape = shape
	area.add_child(collision)
	
	# Подключаем сигнал клика
	var captured_value = value
	var captured_button = button
	var already_clicked = false
	area.input_event.connect(func(_cam, event, _pos, _normal, _shape_idx):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not already_clicked:
			already_clicked = true
			number_clicked.emit(captured_value, captured_button)
	)
	
	button.add_child(area)
	
	return button


# ============================================================
# СЛУЧАЙНАЯ ПОЗИЦИЯ НА ДОСКЕ
# ============================================================
func _get_random_board_position() -> Vector3:
	var margin = 0.5
	var x = randf_range(-board_width / 2.0 + margin, board_width / 2.0 - margin)
	var y = randf_range(-board_height / 2.0 + margin, board_height / 2.0 - margin)
	return Vector3(x, y, 0.05)


# ============================================================
# ЧИСЛО ИСЧЕЗЛО ПО ТАЙМЕРУ
# ============================================================
func _on_number_timeout(button_ref, number_value: int):
	if is_instance_valid(button_ref):
		# Удаляем из активного списка
		active_buttons.erase(button_ref)
		
		# Сигнализируем, что число истекло
		number_expired.emit(number_value, button_ref)
		
		# Удаляем с доски
		button_ref.queue_free()


# ============================================================
# ОБНОВЛЕНИЕ ПАРАМЕТРОВ СЛОЖНОСТИ
# ============================================================
func update_difficulty(new_interval: float, new_lifetime: float, new_chance: float):
	spawn_interval = new_interval
	number_lifetime = new_lifetime
	sixtyseven_chance = new_chance


# ============================================================
# ОСТАНОВКА ГЕНЕРАЦИИ (GAME OVER)
# ============================================================
func stop_generation():
	generation_active = false
	
	# Очищаем все числа
	for button in active_buttons:
		if is_instance_valid(button):
			button.queue_free()
	active_buttons.clear()
	
	# Очищаем все висячие числа (на случай если список рассинхронизирован)
	if is_instance_valid(board_body):
		for child in board_body.get_children():
			if child is Node3D and child.name.begins_with("Number_"):
				child.queue_free()
