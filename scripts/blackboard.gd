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

# ---- Пул поп-апов (lightweight reuse) ----
var _popup_pool := []
const MAX_POOL_SIZE := 20


# ============================================================
# ПОСТРОЕНИЕ ДОСКИ
# ============================================================
func build():
	board_body = StaticBody3D.new()
	board_body.name = "BoardBody"
	
	var board_collision = CollisionShape3D.new()
	var board_shape = BoxShape3D.new()
	board_shape.size = Vector3(board_width, board_height, 0.1)
	board_collision.shape = board_shape
	board_body.add_child(board_collision)
	
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
	
	var frame_mesh = MeshInstance3D.new()
	frame_mesh.name = "BoardFrame"
	frame_mesh.mesh = BoxMesh.new()
	frame_mesh.mesh.size = Vector3(board_width + 0.3, 0.08, 0.08)
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.5, 0.3, 0.1)
	frame_mesh.mesh.material = frame_mat
	
	var frame_top = frame_mesh.duplicate()
	frame_top.position = Vector3(0.0, board_height / 2.0 + 0.04, 0.03)
	board_body.add_child(frame_top)
	
	var frame_bottom = frame_mesh.duplicate()
	frame_bottom.position = Vector3(0.0, -board_height / 2.0 - 0.04, 0.03)
	board_body.add_child(frame_bottom)
	
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
	
	board_body.position = Vector3(0.0, 1.7, -2.8)
	add_child(board_body)
	
	game_manager = get_node_or_null("/root/Main/GameManager")


func _process(delta):
	if not generation_active:
		return
	
	spawn_timer += delta
	while spawn_timer >= spawn_interval and generation_active:
		spawn_timer -= spawn_interval
		_spawn_number()


func _spawn_number():
	if active_buttons.size() >= max_numbers:
		var oldest = active_buttons.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	
	var is_sixtyseven = randf() < sixtyseven_chance
	
	var number_value: int
	if is_sixtyseven:
		number_value = 67
	else:
		number_value = randi() % 98 + 1
		if number_value == 67:
			number_value = 68
	
	var number_button = _create_number_button(number_value)
	
	var pos = _get_random_board_position()
	number_button.position = pos
	
	board_body.add_child(number_button)
	active_buttons.append(number_button)
	
	number_spawned.emit(number_value)
	
	if is_sixtyseven and game_manager:
		game_manager.on_sixtyseven_appeared(number_button, number_lifetime)
	
	var lifetime_timer = get_tree().create_timer(number_lifetime)
	lifetime_timer.timeout.connect(_on_number_timeout.bind(number_button, number_value))


# ============================================================
# СОЗДАНИЕ КНОПКИ-ЧИСЛА
# ============================================================
func _create_number_button(value: int) -> Node3D:
	var button = Node3D.new()
	button.name = "Number_" + str(value)
	
	# ---- Label3D с числом ----
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
	
	# ---- Клик (multi-click для 67) ----
	var captured_value = value
	var captured_button = button
	var already_clicked = false
	
	area.input_event.connect(func(_cam, event, _pos, _normal, _shape_idx):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if value == 67:
				# Multi-click: каждый клик по 67 работает
				var click_count = button.get_meta("click_count", 0)
				click_count += 1
				button.set_meta("click_count", click_count)
				
				_apply_click_effect(button, click_count)
				_spawn_money_popup(button.position, click_count)
				number_clicked.emit(value, button)
			elif not already_clicked:
				already_clicked = true
				number_clicked.emit(value, button)
	)
	
	button.add_child(area)
	
	if value == 67:
		button.set_meta("click_count", 0)
	
	return button


# ============================================================
# ВИЗУАЛЬНЫЙ ЭФФЕКТ КЛИКА ПО 67
# Тряска, пульс, flash — интенсивность растёт с click_count
# ============================================================
func _apply_click_effect(button: Node3D, click_count: int):
	var intensity = min(click_count, 8)
	var shake = 0.02 + intensity * 0.012
	var scale_pulse = 1.0 + 0.06 * intensity
	
	# Тряска
	var shake_tween = create_tween()
	shake_tween.set_ease(Tween.EASE_OUT)
	shake_tween.set_trans(Tween.TRANS_BACK)
	shake_tween.tween_property(button, "rotation:z", shake * randf_range(-1, 1), 0.04)
	if intensity > 3:
		shake_tween.parallel().tween_property(button, "rotation:x", shake * 0.4 * randf_range(-1, 1), 0.04)
	shake_tween.tween_property(button, "rotation", Vector3.ZERO, 0.06)
	
	# Пульс масштаба
	var pulse_tween = create_tween()
	pulse_tween.set_ease(Tween.EASE_OUT)
	pulse_tween.set_trans(Tween.TRANS_BACK)
	pulse_tween.tween_property(button, "scale", Vector3(scale_pulse, scale_pulse, scale_pulse), 0.04)
	pulse_tween.tween_property(button, "scale", Vector3.ONE, 0.08)
	
	# Flash на Label
	var label = button.get_node("Label")
	if label:
		var flash = create_tween()
		flash.tween_property(label, "modulate", Color(1, 0.5, 0.5), 0.03)
		flash.tween_property(label, "modulate", Color(1.0, 0.25, 0.1), 0.07)


# ============================================================
# POPUP ДЕНЕГ — вылетают из числа
# Чем больше click_count, тем больше popup'ов и они крупнее
# ============================================================
func _spawn_money_popup(origin: Vector3, click_count: int):
	var intensity = min(click_count, 8)
	var count = 1 + intensity / 2
	
	for i in range(count):
		var popup = _get_popup()
		if popup == null:
			return
		
		var amount = 3 + randi() % (3 + intensity * 2)
		popup.text = "+" + str(amount)
		
		var font_size = 14 + intensity * 2
		popup.font_size = font_size
		popup.modulate = Color(
			randf_range(0.2, 0.6),
			randf_range(0.7, 1.0),
			randf_range(0.2, 0.5),
			1.0
		)
		
		var spread = 0.1 + intensity * 0.03
		popup.position = origin + Vector3(
			randf_range(-spread, spread),
			randf_range(0.0, spread * 0.5),
			randf_range(-spread, spread) * 0.3
		)
		popup.visible = true
		
		# Вылет + вращение + scale up + fade
		var fly = create_tween()
		fly.set_ease(Tween.EASE_OUT)
		fly.set_trans(Tween.TRANS_BACK)
		fly.parallel().tween_property(popup, "position:y", popup.position.y + 0.2 + intensity * 0.03, 0.5)
		fly.parallel().tween_property(popup, "rotation:z", randf_range(-0.4, 0.4), 0.5)
		fly.parallel().tween_property(popup, "scale", Vector3(1.4, 1.4, 1.4), 0.08)
		
		var fade = create_tween()
		fade.tween_interval(0.25)
		fade.tween_property(popup, "modulate:a", 0.0, 0.3)
		fade.tween_callback(func():
			_return_popup(popup)
		)


# ============================================================
# POPUP POOL (lightweight)
# ============================================================
func _get_popup() -> Label3D:
	for child in _popup_pool:
		if not child.visible:
			return child
	
	if _popup_pool.size() < MAX_POOL_SIZE:
		var label = Label3D.new()
		label.outline_size = 1
		label.outline_modulate = Color(0, 0, 0, 0.5)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.pixel_size = 0.005
		label.visible = false
		board_body.add_child(label)
		_popup_pool.append(label)
		return label
	
	return null


func _return_popup(popup: Label3D):
	popup.visible = false
	popup.scale = Vector3.ONE
	popup.rotation = Vector3.ZERO


# ============================================================
# СЛУЧАЙНАЯ ПОЗИЦИЯ НА ДОСКЕ
# ============================================================
func _get_random_board_position() -> Vector3:
	var margin = 0.5
	var x = randf_range(-board_width / 2.0 + margin, board_width / 2.0 - margin)
	var y = randf_range(-board_height / 2.0 + margin, board_height / 2.0 - margin)
	return Vector3(x, y, 0.08)


# ============================================================
# ЧИСЛО ИСЧЕЗЛО ПО ТАЙМЕРУ
# ============================================================
func _on_number_timeout(button_ref, number_value: int):
	if is_instance_valid(button_ref):
		active_buttons.erase(button_ref)
		number_expired.emit(number_value, button_ref)
		button_ref.queue_free()


func update_difficulty(new_interval: float, new_lifetime: float, new_chance: float):
	spawn_interval = new_interval
	number_lifetime = new_lifetime
	sixtyseven_chance = new_chance


func stop_generation():
	generation_active = false
	
	for button in active_buttons:
		if is_instance_valid(button):
			button.queue_free()
	active_buttons.clear()
	
	if is_instance_valid(board_body):
		for child in board_body.get_children():
			if child is Node3D and child.name.begins_with("Number_"):
				child.queue_free()
