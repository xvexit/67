# ============================================================
# STUDENT.GD - Ученик
#
# Анимации:
# - Idle: ерзает, смотрит по сторонам, скучает
# - 67: резко вскакивает, руки вверх, хаотично
# - Смех: трясется, показывает пальцем
#
# Каждый ученик — unique personality:
# speed, chaos, reaction delay
# ============================================================

extends Node3D


# ---- Части тела ----
var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D

# ---- Пивоты для анимации ----
var torso_pivot: Node3D
var head_pivot: Node3D

# ---- Состояние ----
var student_index: int = 0
var default_position: Vector3
var default_rotation: Vector3
var sitting_y_offset: float = 0.35

# ---- Personality (рандом на каждого ученика) ----
var speed_mod: float = 1.0
var chaos_mod: float = 1.0
var reaction_delay: float = 0.0
var is_panic_type: bool = false
var is_slow_type: bool = false

# ---- Idle animation ----
var idle_timer: float = 0.0
var next_idle_time: float = 2.0
var is_animating: bool = false
var is_standing: bool = false

# ---- 67 pump system (continuous arm pumping while standing) ----
var pump_active: bool = false
var pump_timer: float = 0.0
var pump_speed: float = 3.0
var pump_amp: float = 0.3
var pump_base_left: float = 0.0
var pump_base_right: float = 0.0
var pump_offset_r: float = 0.0

# ---- Тело ученика: цвета ----
var body_colors = [
	Color(0.82, 0.62, 0.42),
	Color(0.72, 0.52, 0.32),
	Color(0.88, 0.68, 0.48),
	Color(0.62, 0.42, 0.28),
	Color(0.78, 0.58, 0.38),
	Color(0.68, 0.48, 0.35),
	Color(0.92, 0.72, 0.52),
	Color(0.55, 0.38, 0.28),
	Color(0.85, 0.65, 0.45),
	Color(0.75, 0.55, 0.38),
	Color(0.9, 0.7, 0.5),
	Color(0.58, 0.4, 0.3),
]


# ============================================================
# ПОСТРОЕНИЕ УЧЕНИКА
# ============================================================
func build(index: int):
	student_index = index
	default_position = position
	default_rotation = rotation
	
	# ---- Personality ----
	speed_mod = randf_range(0.6, 1.4)
	chaos_mod = randf_range(0.7, 1.8)
	reaction_delay = randf_range(0.0, 0.4) * speed_mod
	is_panic_type = randf() < 0.25
	is_slow_type = randf() < 0.15
	
	# Цвет тела
	var body_color = body_colors[index % body_colors.size()]
	var sit = sitting_y_offset
	
	# ---- TORSO PIVOT (центр вращения туловища) ----
	torso_pivot = Node3D.new()
	torso_pivot.name = "TorsoPivot"
	torso_pivot.position = Vector3(0.0, 0.15 + sit, 0.0)
	add_child(torso_pivot)
	
	# ---- ТЕЛО (туловище) ----
	var body = BoxMesh.new()
	body.size = Vector3(0.25, 0.3, 0.18)
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = body_color
	body.material = body_mat
	
	body_mesh = MeshInstance3D.new()
	body_mesh.name = "Body"
	body_mesh.mesh = body
	torso_pivot.add_child(body_mesh)
	
	# ---- HEAD PIVOT (поворот головы) ----
	head_pivot = Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0.0, 0.23, 0.0)
	torso_pivot.add_child(head_pivot)
	
	# ---- ГОЛОВА ----
	var head = SphereMesh.new()
	head.radius = 0.1
	head.height = 0.2
	var head_mat = StandardMaterial3D.new()
	var head_color = Color(
		min(1.0, body_color.r * 1.2),
		min(1.0, body_color.g * 1.15),
		min(1.0, body_color.b * 1.1)
	)
	head_mat.albedo_color = head_color
	head.material = head_mat
	
	head_mesh = MeshInstance3D.new()
	head_mesh.name = "Head"
	head_mesh.mesh = head
	head_pivot.add_child(head_mesh)
	
	# ---- РУКИ (прикреплены к TorsoPivot) ----
	var arm_mat = StandardMaterial3D.new()
	arm_mat.albedo_color = body_color
	
	var arm_mesh = BoxMesh.new()
	arm_mesh.size = Vector3(0.04, 0.22, 0.04)
	arm_mesh.material = arm_mat
	
	# Левая рука
	left_arm = MeshInstance3D.new()
	left_arm.name = "LeftArm"
	left_arm.mesh = arm_mesh
	left_arm.position = Vector3(-0.18, 0.2, 0.0)
	torso_pivot.add_child(left_arm)
	
	# Правая рука
	right_arm = MeshInstance3D.new()
	right_arm.name = "RightArm"
	right_arm.mesh = arm_mesh
	right_arm.position = Vector3(0.18, 0.2, 0.0)
	torso_pivot.add_child(right_arm)
	
	# Сброс анимации
	idle_timer = randf_range(0.0, 2.0)
	next_idle_time = randf_range(1.0, 4.0)


# ============================================================
# IDLE АНИМАЦИЯ (каждый кадр)
# Ерзает, смотрит по сторонам, скучает
# ============================================================
func _process(delta):
	if pump_active:
		pump_timer += delta * pump_speed
		var pump = sin(pump_timer * TAU) * pump_amp
		if is_instance_valid(left_arm):
			left_arm.rotation.x = pump_base_left + pump
		if is_instance_valid(right_arm):
			right_arm.rotation.x = pump_base_right + pump * 0.7 + sin(pump_timer * TAU * 1.37 + pump_offset_r) * pump_amp * 0.35
	
	if is_animating or is_standing:
		return
	
	idle_timer += delta
	if idle_timer >= next_idle_time:
		idle_timer = 0.0
		next_idle_time = randf_range(1.0, 4.0)
		_play_idle_movement()


# ============================================================
# СЛУЧАЙНОЕ IDLE ДВИЖЕНИЕ
# ============================================================
func _play_idle_movement():
	if is_animating or is_standing:
		return
	
	var action = randi() % 5
	var dur = randf_range(0.2, 0.5) * speed_mod
	
	match action:
		0:  # Посмотреть влево
			_head_look(Vector3(randf_range(0.3, 0.6), 0.0, 0.0), dur)
		1:  # Посмотреть вправо
			_head_look(Vector3(randf_range(-0.6, -0.3), 0.0, 0.0), dur)
		2:  # Посмотреть вниз (скучает)
			_head_look(Vector3(0.0, randf_range(0.2, 0.4), 0.0), dur)
		3:  # Почесаться / повертеться
			_torso_sway(randf_range(-0.08, 0.08), dur)
		4:  # Резко посмотреть в сторону (как будто что-то услышал)
			_head_look(Vector3(randf_range(-0.8, 0.8), 0.0, 0.0), dur * 0.4)


func _head_look(target: Vector3, duration: float):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(head_pivot, "rotation", target, duration)
	tween.tween_interval(randf_range(0.5, 1.5))
	var return_tween = create_tween()
	return_tween.set_ease(Tween.EASE_IN_OUT)
	return_tween.set_trans(Tween.TRANS_SINE)
	return_tween.tween_property(head_pivot, "rotation", Vector3.ZERO, duration * 0.7)


func _torso_sway(amount: float, duration: float):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(torso_pivot, "rotation:z", amount, duration)
	tween.tween_interval(randf_range(0.3, 0.8))
	var return_tween = create_tween()
	return_tween.set_ease(Tween.EASE_IN_OUT)
	return_tween.set_trans(Tween.TRANS_SINE)
	return_tween.tween_property(torso_pivot, "rotation:z", 0.0, duration * 0.5)


# ============================================================
# 67 ПОЗА — MEME GESTURE
#
# Резкое вставание + exaggerated pumping arms (ладони вверх,
# локти подсогнуты, ритмичные дерганые движения)
#
# Каждый ученик: random timing, speed, chaos
# ============================================================
func do_sixtyseven_pose(rage_ratio: float = 0.5):
	is_standing = true
	is_animating = true
	
	# Rage усиливает хаос
	var rage_chaos = 1.0 + rage_ratio * 0.6
	
	# ---- RANDOM DELAY BEFORE REACTION ----
	var delay = reaction_delay * randf_range(0.3, 2.0) / rage_chaos
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	
	if not is_instance_valid(self):
		return
	
	# ========================================================
	# 1. STAND UP — резко, стул отъезжает, random offset
	# ========================================================
	var stand_height = 0.4 + randf_range(0.25, 0.45) * chaos_mod
	var chair_slide = randf_range(0.03, 0.1) * chaos_mod
	
	var rise = create_tween()
	rise.set_ease(Tween.EASE_OUT)
	rise.set_trans(Tween.TRANS_BACK)
	rise.tween_property(self, "position:y", stand_height, 0.08 / speed_mod)
	rise.parallel().tween_property(self, "position:z", default_position.z + chair_slide, 0.1 / speed_mod)
	
	# Лёгкий рывок корпуса вперёд (lurch)
	var lurch = create_tween()
	lurch.set_ease(Tween.EASE_OUT)
	lurch.set_trans(Tween.TRANS_BACK)
	lurch.tween_property(torso_pivot, "rotation:x", randf_range(0.04, 0.12) * chaos_mod, 0.06 / speed_mod)
	
	# ========================================================
	# 2. ARMS — резкий выброс в позицию pumping
	# ========================================================
	var arm_speed = 0.06 / speed_mod
	
	# Левая и правая руки получают slightly разные углы
	var left_target = -1.2 + randf_range(-0.3, 0.3) * chaos_mod * rage_chaos
	var right_target = -0.9 + randf_range(-0.4, 0.4) * chaos_mod * rage_chaos
	
	# Локти наружу
	var left_elbow = 0.25 + randf_range(-0.1, 0.15) * chaos_mod
	var right_elbow = -0.25 + randf_range(-0.15, 0.1) * chaos_mod
	
	var arms_out = create_tween()
	arms_out.set_ease(Tween.EASE_OUT)
	arms_out.set_trans(Tween.TRANS_BACK)
	arms_out.tween_property(left_arm, "rotation:x", left_target, arm_speed)
	arms_out.parallel().tween_property(left_arm, "rotation:z", left_elbow, arm_speed)
	arms_out.tween_property(right_arm, "rotation:x", right_target, arm_speed * 1.2)  # slight offset
	arms_out.parallel().tween_property(right_arm, "rotation:z", right_elbow, arm_speed)
	
	# ========================================================
	# 3. SET UP PUMPING (continuous в _process)
	# ========================================================
	pump_base_left = left_target
	pump_base_right = right_target
	pump_amp = 0.2 * chaos_mod * rage_chaos + randf_range(0.0, 0.15)
	pump_speed = 2.5 + randf_range(0.0, 2.5) / speed_mod
	pump_offset_r = randf_range(0.0, 1.0)
	pump_timer = 0.0
	pump_active = true
	
	# Для slow type — pump_speed ниже
	if is_slow_type:
		pump_speed *= 0.5
	
	# ========================================================
	# 4. CHAOTIC EXTRAS
	# ========================================================
	
	# WOBBLE корпуса (все ученики)
	var wobble_loops = 2 + randi() % int(3 * rage_chaos)
	var wobble = create_tween()
	wobble.set_loops(wobble_loops)
	var wobble_amp = 0.06 * chaos_mod * rage_chaos
	wobble.tween_property(torso_pivot, "rotation:z", wobble_amp, 0.05)
	wobble.tween_property(torso_pivot, "rotation:z", -wobble_amp * 0.7, 0.06)
	wobble.tween_property(torso_pivot, "rotation:z", wobble_amp * 0.4, 0.04)
	wobble.tween_property(torso_pivot, "rotation:z", 0.0, 0.05)
	
	# HEAD — запрокидывание / поворот
	var head_tilt = create_tween()
	head_tilt.set_ease(Tween.EASE_OUT)
	head_tilt.set_trans(Tween.TRANS_BACK)
	head_tilt.tween_property(head_pivot, "rotation:x", randf_range(0.05, 0.18) * chaos_mod, 0.08)
	if randf() < 0.6:
		var head_turn = create_tween()
		head_turn.set_ease(Tween.EASE_OUT)
		head_turn.set_trans(Tween.TRANS_BACK)
		head_turn.tween_property(head_pivot, "rotation:y", randf_range(-0.2, 0.2) * chaos_mod, 0.1)
	
	# ARM SHAKE (panic type или случайно)
	if is_panic_type or randf() < 0.35 * rage_chaos:
		var shake_loops = 3 + randi() % int(4 * rage_chaos)
		var shake = create_tween()
		shake.set_loops(shake_loops)
		var s = 0.12 * chaos_mod * rage_chaos
		shake.tween_property(left_arm, "rotation:z", s, 0.03)
		shake.tween_property(right_arm, "rotation:z", -s, 0.03)
		shake.tween_property(left_arm, "rotation:z", -s, 0.03)
		shake.tween_property(right_arm, "rotation:z", s, 0.03)
	
	# Некоторые резко дёргают головой в сторону класса
	if randf() < 0.2:
		var glance = create_tween()
		glance.set_ease(Tween.EASE_OUT)
		glance.set_trans(Tween.TRANS_BACK)
		glance.tween_property(head_pivot, "rotation:y", randf_range(-0.5, 0.5), 0.04)
	
	# ========================================================
	# 5. LABEL "67"
	# ========================================================
	var label = Label3D.new()
	label.name = "SixtySevenLabel"
	label.text = "67"
	label.font_size = 28
	label.modulate = Color(1.0, 0.2, 0.1)
	label.outline_size = 2
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.005
	label.position = Vector3(0.0, 0.65 + sitting_y_offset, 0.0)
	add_child(label)
	
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(label):
			label.queue_free()
	)
	
	is_animating = false


# ============================================================
# СМЕХ — реакция на промах игрока
# Кто-то трясется, кто-то показывает пальцем
# ============================================================
func do_laugh():
	is_animating = true
	
	var laugh_type = randi() % 3
	
	match laugh_type:
		0:  # Тряска (тело вперед-назад)
			var tween = create_tween()
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.set_loops(4)
			tween.tween_property(torso_pivot, "rotation:x", 0.12 * chaos_mod, 0.08)
			tween.tween_property(torso_pivot, "rotation:x", -0.08 * chaos_mod, 0.08)
			tween.tween_property(torso_pivot, "rotation:x", 0.0, 0.08)
		
		1:  # Показывает пальцем + трясется
			var point_tween = create_tween()
			point_tween.set_ease(Tween.EASE_OUT)
			point_tween.set_trans(Tween.TRANS_BACK)
			
			if randf() > 0.5:
				point_tween.tween_property(left_arm, "rotation:x", -1.2, 0.1)
			else:
				point_tween.tween_property(right_arm, "rotation:x", 1.2, 0.1)
			
			var shake_tween = create_tween()
			shake_tween.set_loops(3)
			shake_tween.tween_property(torso_pivot, "rotation:x", 0.1, 0.07)
			shake_tween.tween_property(torso_pivot, "rotation:x", 0.0, 0.07)
		
		2:  # Откидывается назад + трясет головой
			var tween = create_tween()
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(torso_pivot, "rotation:z", -0.1 * chaos_mod, 0.12)
			tween.parallel().tween_property(head_pivot, "rotation:x", 0.2, 0.12)
			
			var shake_tween = create_tween()
			shake_tween.set_loops(4)
			shake_tween.tween_property(head_pivot, "rotation:y", 0.15, 0.06)
			shake_tween.tween_property(head_pivot, "rotation:y", -0.15, 0.06)
	
	# Подпрыгивание (все типы)
	var bounce_tween = create_tween()
	bounce_tween.set_loops(3)
	bounce_tween.tween_property(self, "position:y", 0.04, 0.08)
	bounce_tween.tween_property(self, "position:y", 0.0, 0.08)
	
	# Возврат в исходное положение через 1.5 сек
	var reset_timer = get_tree().create_timer(1.5)
	reset_timer.timeout.connect(_reset_laugh)


# ============================================================
# СБРОС ПОСЛЕ СМЕХА
# ============================================================
func _reset_laugh():
	if not is_instance_valid(self):
		return
	_reset_arms_and_torso()
	is_animating = false


# ============================================================
# СБРОС ПОЗЫ (после 67 moment)
# ============================================================
func reset_pose():
	is_standing = false
	pump_active = false
	is_animating = true
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# Опускаемся + стул на место
	tween.parallel().tween_property(self, "position", default_position, 0.3)
	tween.parallel().tween_property(self, "rotation", default_rotation, 0.2)
	
	# Почти падают при возврате (чаще и сильнее чем раньше)
	if randf() < 0.5 * chaos_mod:
		var stumble = create_tween()
		stumble.set_ease(Tween.EASE_IN_OUT)
		var s = 0.1 * chaos_mod
		stumble.tween_property(torso_pivot, "rotation:z", s, 0.06)
		stumble.tween_property(torso_pivot, "rotation:z", -s * 0.5, 0.08)
		stumble.tween_property(torso_pivot, "rotation:z", 0.0, 0.06)
	
	_reset_arms_and_torso()
	
	for child in get_children():
		if child.name == "SixtySevenLabel":
			child.queue_free()
	
	await get_tree().create_timer(0.4).timeout
	
	if is_instance_valid(self):
		is_animating = false


# ============================================================
# ВСПОМОГАТЕЛЬНЫЕ
# ============================================================
func _reset_arms_and_torso():
	if is_instance_valid(left_arm):
		var tween_l = create_tween()
		tween_l.set_ease(Tween.EASE_OUT)
		tween_l.set_trans(Tween.TRANS_SINE)
		tween_l.tween_property(left_arm, "rotation", Vector3.ZERO, 0.2)
	
	if is_instance_valid(right_arm):
		var tween_r = create_tween()
		tween_r.set_ease(Tween.EASE_OUT)
		tween_r.set_trans(Tween.TRANS_SINE)
		tween_r.tween_property(right_arm, "rotation", Vector3.ZERO, 0.2)
	
	if is_instance_valid(torso_pivot):
		var tween_t = create_tween()
		tween_t.set_ease(Tween.EASE_OUT)
		tween_t.set_trans(Tween.TRANS_SINE)
		tween_t.tween_property(torso_pivot, "rotation", Vector3.ZERO, 0.2)
	
	if is_instance_valid(head_pivot):
		var tween_h = create_tween()
		tween_h.set_ease(Tween.EASE_OUT)
		tween_h.set_trans(Tween.TRANS_SINE)
		tween_h.tween_property(head_pivot, "rotation", Vector3.ZERO, 0.2)
