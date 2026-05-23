# ============================================================
# STUDENT.GD - Поведение ученика
#
# Каждый ученик - это 3D персонаж из примитивов.
# Умеет:
# - Сидеть за партой (idle)
# - Делать 67 позу (вставать, поднимать руки)
# - Смеяться (качаться)
# - Возвращаться в исходное положение
# ============================================================

extends Node3D


# ---- Ссылки на части тела ----
var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D

# ---- Состояние ----
var student_index: int = 0
var default_position: Vector3
var default_rotation: Vector3
var sitting_y_offset: float = 0.35  # высота стула над полом
var is_standing: bool = false

# ---- Параметры ----
var body_colors = [
	Color(0.8, 0.6, 0.4),  # светлый
	Color(0.7, 0.5, 0.3),  # средний
	Color(0.9, 0.7, 0.5),  # светлый 2
	Color(0.6, 0.4, 0.3),  # темный
	Color(0.85, 0.65, 0.45), # светлый 3
]


# ============================================================
# ПОСТРОЕНИЕ УЧЕНИКА
# ============================================================
func build(index: int):
	student_index = index
	default_position = position
	default_rotation = rotation
	
	# Выбираем цвет тела
	var body_color = body_colors[index % body_colors.size()]
	
	# --- ТЕЛО (сидит, поэтому тело короче) ---
	var body = BoxMesh.new()
	body.size = Vector3(0.25, 0.3, 0.18)
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = body_color
	body.material = body_mat
	
	body_mesh = MeshInstance3D.new()
	body_mesh.name = "Body"
	body_mesh.mesh = body
	body_mesh.position = Vector3(0.0, 0.15 + sitting_y_offset, 0.0)
	add_child(body_mesh)
	
	# --- ГОЛОВА ---
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
	head_mesh.position = Vector3(0.0, 0.38 + sitting_y_offset, 0.0)
	add_child(head_mesh)
	
	# --- РУКИ ---
	var arm_mat = StandardMaterial3D.new()
	arm_mat.albedo_color = body_color
	
	var arm_mesh = BoxMesh.new()
	arm_mesh.size = Vector3(0.04, 0.22, 0.04)
	arm_mesh.material = arm_mat
	
	# Левая рука
	left_arm = MeshInstance3D.new()
	left_arm.name = "LeftArm"
	left_arm.mesh = arm_mesh
	left_arm.position = Vector3(-0.18, 0.2 + sitting_y_offset, 0.0)
	add_child(left_arm)
	
	# Правая рука
	right_arm = MeshInstance3D.new()
	right_arm.name = "RightArm"
	right_arm.mesh = arm_mesh
	right_arm.position = Vector3(0.18, 0.2 + sitting_y_offset, 0.0)
	add_child(right_arm)


# ============================================================
# 67 ПОЗА
# Ученик встает и поднимает руки вверх
# ============================================================
func do_sixtyseven_pose():
	is_standing = true
	
	# Поднимаем ученика вверх (встает)
	var tween_up = get_tree().create_tween()
	tween_up.tween_property(self, "position:y", 0.4, 0.3)
	tween_up.set_ease(Tween.EASE_OUT)
	tween_up.set_trans(Tween.TRANS_BACK)
	
	# Поднимаем руки вверх (вращаем)
	var tween_l = get_tree().create_tween()
	tween_l.tween_property(left_arm, "rotation:x", -1.8, 0.25)
	tween_l.set_ease(Tween.EASE_OUT)
	tween_l.set_trans(Tween.TRANS_BACK)
	
	var tween_r = get_tree().create_tween()
	tween_r.tween_property(right_arm, "rotation:x", 1.8, 0.25)
	tween_r.set_ease(Tween.EASE_OUT)
	tween_r.set_trans(Tween.TRANS_BACK)
	
	# Создаем Label3D "67" над головой
	var label = Label3D.new()
	label.name = "SixtySevenLabel"
	label.text = "67"
	label.font_size = 28
	label.modulate = Color(1.0, 0.2, 0.1)
	label.outline_size = 2
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.005
	label.position = Vector3(0.0, 0.65, 0.0)
	add_child(label)
	
	# Удаляем label через 2 секунды
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func():
		if is_instance_valid(label):
			label.queue_free()
	)


# ============================================================
# СМЕХ
# Ученик качается взад-вперед
# ============================================================
func do_laugh():
	# Создаем эффект покачивания
	var original_rot = rotation.x
	var tween = get_tree().create_tween()
	tween.set_loops(3)
	tween.tween_property(self, "rotation:x", 0.15, 0.1)
	tween.tween_property(self, "rotation:x", -0.1, 0.1)
	tween.tween_property(self, "rotation:x", 0.0, 0.1)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Небольшое подпрыгивание
	var tween_y = get_tree().create_tween()
	tween_y.set_loops(3)
	tween_y.tween_property(self, "position:y", 0.05, 0.1)
	tween_y.tween_property(self, "position:y", 0.0, 0.1)


# ============================================================
# СБРОС ПОЗЫ
# Возвращаем ученика в исходное положение
# ============================================================
func reset_pose():
	is_standing = false
	
	# Плавно опускаем
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(self, "position", default_position, 0.3)
	tween.parallel().tween_property(self, "rotation", Vector3.ZERO, 0.2)
	
	# Опускаем руки
	if is_instance_valid(left_arm):
		var tween_l = get_tree().create_tween()
		tween_l.tween_property(left_arm, "rotation:x", 0.0, 0.2)
	
	if is_instance_valid(right_arm):
		var tween_r = get_tree().create_tween()
		tween_r.tween_property(right_arm, "rotation:x", 0.0, 0.2)
	
	# Удаляем label если есть
	for child in get_children():
		if child.name == "SixtySevenLabel":
			child.queue_free()
