# ============================================================
# CLASSROOM.GD - Российский школьный класс начала 2010-х
#
# Атмосфера:
# - Холодный флуоресцентный свет (зимнее утро)
# - Потертый линолеум, обшарпанные стены
# - Тесные проходы, старая мебель
# -awkward energy — сейчас произойдет что-то глупое
#
# Всё из примитивных мешей, 0 внешних ассетов
# ============================================================

extends Node


# ============================================================
# РАЗМЕРЫ КОМНАТЫ
# ============================================================
const ROOM_W := 8.0
const ROOM_D := 7.0
const ROOM_H := 3.0

# Позиции парт: 4 колонки x 3 ряда (24 места, 12 парт по 2)
const DESK_X := [-2.4, -0.7, 0.7, 2.4]
const DESK_Z := [0.3, 1.6, 2.9]
const NUM_COLS := 4
const NUM_ROWS := 3

# Позиции учеников (слегка позади и правее каждой парты)
var _student_positions := []


# ============================================================
# ССЫЛКИ НА ОБЪЕКТЫ
# ============================================================
var teacher_node: Node3D
var teacher_body_mesh: MeshInstance3D
var students := []
var desk_nodes := []
var fluorescent_lights := []

# Счетчик для мерцания ламп
var _flicker_time := 0.0

# ---- АНИМАЦИЯ УЧИТЕЛЯ ----
enum TeacherState { IDLE, REACTING }
var teacher_state = TeacherState.IDLE
var teacher_head_pivot: Node3D
var teacher_right_arm: MeshInstance3D
var teacher_left_eyebrow: MeshInstance3D
var teacher_right_eyebrow: MeshInstance3D
var teacher_mouth: MeshInstance3D
var teacher_left_eye: MeshInstance3D
var teacher_right_eye: MeshInstance3D
var teacher_pointer: MeshInstance3D
var teacher_reaction_tween: Tween = null
var teacher_idle_timer := 0.0
var teacher_blink_timer := 0.0


# ============================================================
# ПОСТРОЕНИЕ КЛАССА
# ============================================================
func build():
	_create_walls()
	_create_floor()
	_create_ceiling()
	_create_windows()
	_create_cabinets()
	_create_teacher_desk()
	_create_teacher()
	_create_desks()
	_create_student_positions()
	_create_students()
	_create_fluorescent_lights()
	_create_posters()
	_create_dust()
	_create_details()
	
	print("Класс построен: ", NUM_COLS * NUM_ROWS, " парт, ", \
		_student_positions.size(), " учеников")


# ============================================================
# ПРОЦЕСС — МЕРЦАНИЕ ЛАМП
# ============================================================
func _process(delta):
	_flicker_time += delta
	
	for i in fluorescent_lights.size():
		var light = fluorescent_lights[i]
		if not is_instance_valid(light):
			continue
		
		var t = _flicker_time + i * 2.3
		var flicker = 0.0
		
		flicker += sin(t * 47.0) * 0.015
		flicker += sin(t * 103.0) * 0.008
		flicker += sin(t * 7.3) * 0.025
		
		if sin(t * 0.7 + i) > 0.95:
			flicker -= 0.08
		if sin(t * 1.3 + i * 0.5) > 0.97:
			flicker -= 0.12
		
		light.light_energy = 0.32 + flicker
	
	# Анимация учителя (только если не в реакции)
	if teacher_state == TeacherState.IDLE:
		_update_teacher_idle(delta)


# ============================================================
# СТЕНЫ
# ============================================================
func _create_walls():
	# Материал стен — потертая масляная краска, разные оттенки
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.82, 0.78, 0.7)
	wall_mat.roughness = 0.9
	wall_mat.metallic = 0.0
	
	var wall_mat_dark = StandardMaterial3D.new()
	wall_mat_dark.albedo_color = Color(0.73, 0.68, 0.6)
	wall_mat_dark.roughness = 0.95
	wall_mat_dark.metallic = 0.0
	
	# Передняя стена (со стороны доски)
	var front = MeshInstance3D.new()
	front.name = "FrontWall"
	front.mesh = BoxMesh.new()
	front.mesh.size = Vector3(ROOM_W + 0.5, ROOM_H, 0.1)
	front.mesh.material = wall_mat_dark
	front.position = Vector3(0.0, ROOM_H * 0.5, -ROOM_D * 0.5)
	add_child(front)
	
	# Левая стена
	var left = MeshInstance3D.new()
	left.name = "LeftWall"
	left.mesh = BoxMesh.new()
	left.mesh.size = Vector3(0.1, ROOM_H, ROOM_D)
	var left_mat = wall_mat.duplicate()
	left_mat.albedo_color = Color(0.78, 0.74, 0.67)
	left.mesh.material = left_mat
	left.position = Vector3(-ROOM_W * 0.5, ROOM_H * 0.5, 0.0)
	add_child(left)
	
	# Правая стена
	var right = MeshInstance3D.new()
	right.name = "RightWall"
	right.mesh = BoxMesh.new()
	right.mesh.size = Vector3(0.1, ROOM_H, ROOM_D)
	var right_mat = wall_mat.duplicate()
	right_mat.albedo_color = Color(0.8, 0.76, 0.68)
	right.mesh.material = right_mat
	right.position = Vector3(ROOM_W * 0.5, ROOM_H * 0.5, 0.0)
	add_child(right)
	
	# Задняя стена (сзади класса)
	var back = MeshInstance3D.new()
	back.name = "BackWall"
	back.mesh = BoxMesh.new()
	back.mesh.size = Vector3(ROOM_W + 0.5, ROOM_H, 0.1)
	back.mesh.material = wall_mat
	back.position = Vector3(0.0, ROOM_H * 0.5, ROOM_D * 0.5)
	add_child(back)


# ============================================================
# ПОЛ — СТАРЫЙ ЛИНОЛЕУМ
# ============================================================
func _create_floor():
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.32, 0.28, 0.22)
	floor_mat.roughness = 0.95
	floor_mat.metallic = 0.0
	
	var floor = MeshInstance3D.new()
	floor.name = "Floor"
	floor.mesh = BoxMesh.new()
	floor.mesh.size = Vector3(ROOM_W, 0.03, ROOM_D)
	floor.mesh.material = floor_mat
	floor.position = Vector3(0.0, 0.0, 0.0)
	add_child(floor)


# ============================================================
# ПОТОЛОК — ПОБЕЛКА
# ============================================================
func _create_ceiling():
	var ceil_mat = StandardMaterial3D.new()
	ceil_mat.albedo_color = Color(0.88, 0.85, 0.8)
	ceil_mat.roughness = 1.0
	ceil_mat.metallic = 0.0
	
	var ceiling = MeshInstance3D.new()
	ceiling.name = "Ceiling"
	ceiling.mesh = BoxMesh.new()
	ceiling.mesh.size = Vector3(ROOM_W, 0.03, ROOM_D)
	ceiling.mesh.material = ceil_mat
	ceiling.position = Vector3(0.0, ROOM_H, 0.0)
	add_child(ceiling)


# ============================================================
# ОКНА — ХОЛОДНЫЙ СВЕТ С УЛИЦЫ
# Прямоугольники на левой стене (зимнее утро)
# ============================================================
func _create_windows():
	var window_mat = StandardMaterial3D.new()
	window_mat.albedo_color = Color(0.7, 0.75, 0.9, 0.3)
	window_mat.roughness = 0.2
	window_mat.metallic = 0.0
	window_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.7, 0.65, 0.55)
	frame_mat.roughness = 0.8
	
	# Два окна на левой стене
	for i in range(2):
		var win_x = -ROOM_W * 0.5 - 0.01
		var win_z = -1.0 + i * 3.5
		
		# Стекло
		var glass = MeshInstance3D.new()
		glass.name = "Window_" + str(i)
		glass.mesh = QuadMesh.new()
		glass.mesh.size = Vector2(1.2, 1.5)
		glass.mesh.material = window_mat
		glass.position = Vector3(win_x, 1.6, win_z)
		glass.rotation.y = PI * 0.5
		add_child(glass)
		
		# Рама (горизонтальная)
		var frame_h = MeshInstance3D.new()
		frame_h.mesh = BoxMesh.new()
		frame_h.mesh.size = Vector3(0.04, 0.04, 1.2)
		frame_h.mesh.material = frame_mat
		frame_h.position = Vector3(win_x, 1.6 + 0.75, win_z)
		frame_h.rotation.y = PI * 0.5
		add_child(frame_h)
		
		var frame_h2 = frame_h.duplicate()
		frame_h2.position = Vector3(win_x, 1.6 - 0.75, win_z)
		add_child(frame_h2)
		
		# Рама (вертикальная)
		var frame_v = MeshInstance3D.new()
		frame_v.mesh = BoxMesh.new()
		frame_v.mesh.size = Vector3(0.04, 1.5, 0.04)
		frame_v.mesh.material = frame_mat
		frame_v.position = Vector3(win_x, 1.6, win_z)
		add_child(frame_v)


# ============================================================
# ШКАФЫ — СТАРЫЕ ДЕРЕВЯННЫЕ
# ============================================================
func _create_cabinets():
	var cabinet_mat = StandardMaterial3D.new()
	cabinet_mat.albedo_color = Color(0.55, 0.4, 0.2)
	cabinet_mat.roughness = 0.85
	cabinet_mat.metallic = 0.0
	
	var cabinet_positions = [
		Vector3(-ROOM_W * 0.5 + 0.5, 0.0, ROOM_D * 0.5 - 0.5),
		Vector3(ROOM_W * 0.5 - 0.5, 0.0, ROOM_D * 0.5 - 0.5),
	]
	
	for pos in cabinet_positions:
		var cabinet = Node3D.new()
		cabinet.name = "Cabinet_" + str(cabinet_positions.find(pos))
		cabinet.position = pos
		
		# Основной корпус
		var body = MeshInstance3D.new()
		body.mesh = BoxMesh.new()
		body.mesh.size = Vector3(0.9, 2.0, 0.5)
		body.mesh.material = cabinet_mat
		body.position = Vector3(0.0, 1.0, 0.0)
		cabinet.add_child(body)
		
		# Дверцы (две вертикальные панели)
		var door_mat = StandardMaterial3D.new()
		door_mat.albedo_color = Color(0.6, 0.45, 0.25)
		door_mat.roughness = 0.7
		
		for side in [-1, 1]:
			var door = MeshInstance3D.new()
			door.mesh = BoxMesh.new()
			door.mesh.size = Vector3(0.35, 1.8, 0.02)
			door.mesh.material = door_mat
			door.position = Vector3(side * 0.25, 1.0, 0.26)
			cabinet.add_child(door)
		
		# Ручки
		var handle_mat = StandardMaterial3D.new()
		handle_mat.albedo_color = Color(0.7, 0.6, 0.4)
		handle_mat.roughness = 0.5
		
		for side in [-1, 1]:
			var handle = MeshInstance3D.new()
			handle.mesh = CylinderMesh.new()
			handle.mesh.top_radius = 0.015
			handle.mesh.bottom_radius = 0.015
			handle.mesh.height = 0.08
			handle.mesh.material = handle_mat
			handle.position = Vector3(side * 0.25, 1.0, 0.3)
			handle.rotation.x = PI * 0.5
			cabinet.add_child(handle)
		
		add_child(cabinet)


# ============================================================
# СТОЛ УЧИТЕЛЯ
# ============================================================
func _create_teacher_desk():
	var desk_mat = StandardMaterial3D.new()
	desk_mat.albedo_color = Color(0.6, 0.45, 0.25)
	desk_mat.roughness = 0.75
	
	var desk = Node3D.new()
	desk.name = "TeacherDesk"
	desk.position = Vector3(0.0, 0.0, -0.8)
	
	# Столешница
	var top = MeshInstance3D.new()
	top.mesh = BoxMesh.new()
	top.mesh.size = Vector3(1.2, 0.04, 0.6)
	top.mesh.material = desk_mat
	top.position = Vector3(0.0, 0.74, 0.0)
	desk.add_child(top)
	
	# Ножки
	var leg_mat = StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.5, 0.35, 0.15)
	leg_mat.roughness = 0.8
	
	for lx in [-0.5, 0.5]:
		for lz in [-0.2, 0.2]:
			var leg = MeshInstance3D.new()
			leg.mesh = CylinderMesh.new()
			leg.mesh.top_radius = 0.02
			leg.mesh.bottom_radius = 0.025
			leg.mesh.height = 0.72
			leg.mesh.material = leg_mat
			leg.position = Vector3(lx, 0.36, lz)
			desk.add_child(leg)
	
	add_child(desk)


# ============================================================
# УЧИТЕЛЬ — строгая учительница математики
# Очки, собранные волосы, tired face, указка
# ============================================================
func _create_teacher():
	teacher_node = Node3D.new()
	teacher_node.name = "Teacher"
	teacher_node.position = Vector3(0.0, 0.0, -1.5)
	
	var dark_mat = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.18, 0.18, 0.22)
	dark_mat.roughness = 0.75
	
	var darkblue_mat = StandardMaterial3D.new()
	darkblue_mat.albedo_color = Color(0.15, 0.18, 0.25)
	darkblue_mat.roughness = 0.7
	
	var skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.85, 0.73, 0.62)
	skin_mat.roughness = 0.6
	
	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.93, 0.9, 0.87)
	white_mat.roughness = 0.6
	
	# --- НОГИ / ЮБКА ---
	var skirt_mat = dark_mat.duplicate()
	skirt_mat.albedo_color = Color(0.12, 0.1, 0.14)
	
	var skirt = MeshInstance3D.new()
	skirt.name = "Skirt"
	skirt.mesh = BoxMesh.new()
	skirt.mesh.size = Vector3(0.4, 0.22, 0.22)
	skirt.mesh.material = skirt_mat
	skirt.position = Vector3(0.0, 0.13, 0.0)
	teacher_node.add_child(skirt)
	
	# --- ТОРС (пиджак) ---
	var blazer_mat = darkblue_mat.duplicate()
	
	teacher_body_mesh = MeshInstance3D.new()
	teacher_body_mesh.name = "Torso"  
	teacher_body_mesh.mesh = BoxMesh.new()
	teacher_body_mesh.mesh.size = Vector3(0.45, 0.48, 0.24)
	teacher_body_mesh.mesh.material = blazer_mat
	teacher_body_mesh.position = Vector3(0.0, 0.5, 0.0)
	teacher_node.add_child(teacher_body_mesh)
	
	# Воротник (белая рубашка)
	var collar = MeshInstance3D.new()
	collar.name = "Collar"
	collar.mesh = BoxMesh.new()
	collar.mesh.size = Vector3(0.22, 0.08, 0.16)
	collar.mesh.material = white_mat
	collar.position = Vector3(0.0, 0.78, 0.0)
	teacher_node.add_child(collar)
	
	# --- ПИВОТ ГОЛОВЫ (для анимации поворота) ---
	teacher_head_pivot = Node3D.new()
	teacher_head_pivot.name = "HeadPivot"
	teacher_head_pivot.position = Vector3(0.0, 0.9, 0.0)
	
	# --- ГОЛОВА ---
	var head_mesh = MeshInstance3D.new()
	head_mesh.name = "HeadMesh"
	head_mesh.mesh = SphereMesh.new()
	head_mesh.mesh.radius = 0.14
	head_mesh.mesh.height = 0.28
	head_mesh.mesh.material = skin_mat
	head_mesh.position = Vector3(0.0, 0.08, 0.0)
	teacher_head_pivot.add_child(head_mesh)
	
	# --- ВОЛОСЫ (собраны назад, пучок) ---
	var hair_mat = StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.1, 0.07, 0.05)
	hair_mat.roughness = 0.9
	
	# Волосы сверху
	var hair_top = MeshInstance3D.new()
	hair_top.name = "HairTop"
	hair_top.mesh = SphereMesh.new()
	hair_top.mesh.radius = 0.15
	hair_top.mesh.height = 0.16
	hair_top.mesh.material = hair_mat
	hair_top.position = Vector3(0.0, 0.1, -0.02)
	teacher_head_pivot.add_child(hair_top)
	
	# Пучок
	var bun = MeshInstance3D.new()
	bun.name = "HairBun"
	bun.mesh = SphereMesh.new()
	bun.mesh.radius = 0.07
	bun.mesh.height = 0.1
	bun.mesh.material = hair_mat
	bun.position = Vector3(0.0, 0.2, 0.07)
	teacher_head_pivot.add_child(bun)
	
	# --- ГЛАЗА ---
	var eye_white_mat = StandardMaterial3D.new()
	eye_white_mat.albedo_color = Color(0.95, 0.93, 0.9)
	
	var pupil_mat = StandardMaterial3D.new()
	pupil_mat.albedo_color = Color(0.12, 0.1, 0.08)
	
	for side in [-1, 1]:
		var eye = MeshInstance3D.new()
		eye.name = "Eye_" + str(side)
		eye.mesh = SphereMesh.new()
		eye.mesh.radius = 0.03
		eye.mesh.height = 0.04
		eye.mesh.material = eye_white_mat
		eye.position = Vector3(side * 0.06, 0.045, 0.14)
		teacher_head_pivot.add_child(eye)
		
		if side == -1:
			teacher_left_eye = eye
		else:
			teacher_right_eye = eye
		
		# Зрачок
		var pupil = MeshInstance3D.new()
		pupil.name = "Pupil_" + str(side)
		pupil.mesh = SphereMesh.new()
		pupil.mesh.radius = 0.012
		pupil.mesh.height = 0.015
		pupil.mesh.material = pupil_mat
		pupil.position = Vector3(side * 0.06, 0.04, 0.165)
		teacher_head_pivot.add_child(pupil)
	
	# --- БРОВИ ---
	var brow_mat = hair_mat.duplicate()
	
	for side in [-1, 1]:
		var brow = MeshInstance3D.new()
		brow.name = "Brow_" + str(side)
		brow.mesh = BoxMesh.new()
		brow.mesh.size = Vector3(0.055, 0.01, 0.02)
		brow.mesh.material = brow_mat
		brow.position = Vector3(side * 0.06, 0.095, 0.14)
		
		if side == -1:
			teacher_left_eyebrow = brow
		else:
			teacher_right_eyebrow = brow
		
		teacher_head_pivot.add_child(brow)
	
	# --- ТЕНИ ПОД ГЛАЗАМИ (уставший вид) ---
	var bag_mat = StandardMaterial3D.new()
	bag_mat.albedo_color = Color(0.5, 0.42, 0.38)
	bag_mat.roughness = 0.8
	
	for side in [-1, 1]:
		var bag = MeshInstance3D.new()
		bag.name = "EyeBag_" + str(side)
		bag.mesh = BoxMesh.new()
		bag.mesh.size = Vector3(0.04, 0.008, 0.015)
		bag.mesh.material = bag_mat
		bag.position = Vector3(side * 0.06, 0.01, 0.14)
		teacher_head_pivot.add_child(bag)
	
	# --- РОТ ---
	var mouth_mat = StandardMaterial3D.new()
	mouth_mat.albedo_color = Color(0.45, 0.3, 0.25)
	
	teacher_mouth = MeshInstance3D.new()
	teacher_mouth.name = "Mouth"
	teacher_mouth.mesh = BoxMesh.new()
	teacher_mouth.mesh.size = Vector3(0.035, 0.006, 0.015)
	teacher_mouth.mesh.material = mouth_mat
	teacher_mouth.position = Vector3(0.0, -0.06, 0.14)
	teacher_head_pivot.add_child(teacher_mouth)
	
	# --- ОЧКИ ---
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.12, 0.12, 0.12)
	frame_mat.roughness = 0.4
	frame_mat.metallic = 0.3
	
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.75, 0.78, 0.85, 0.15)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.1
	glass_mat.metallic = 0.2
	
	for side in [-1, 1]:
		var lens_ring = MeshInstance3D.new()
		lens_ring.name = "GlassesRing_" + str(side)
		lens_ring.mesh = TorusMesh.new()
		lens_ring.mesh.inner_radius = 0.04
		lens_ring.mesh.outer_radius = 0.048
		lens_ring.mesh.material = frame_mat
		lens_ring.position = Vector3(side * 0.075, 0.05, 0.165)
		teacher_head_pivot.add_child(lens_ring)
		
		var lens = MeshInstance3D.new()
		lens.name = "GlassesLens_" + str(side)
		lens.mesh = BoxMesh.new()
		lens.mesh.size = Vector3(0.078, 0.07, 0.005)
		lens.mesh.material = glass_mat
		lens.position = Vector3(side * 0.075, 0.05, 0.165)
		teacher_head_pivot.add_child(lens)
	
	# Дужка очков
	var bridge = MeshInstance3D.new()
	bridge.name = "GlassesBridge"
	bridge.mesh = BoxMesh.new()
	bridge.mesh.size = Vector3(0.035, 0.006, 0.01)
	bridge.mesh.material = frame_mat
	bridge.position = Vector3(0.0, 0.05, 0.165)
	teacher_head_pivot.add_child(bridge)
	
	teacher_node.add_child(teacher_head_pivot)
	
	# --- ПРАВАЯ РУКА (с указкой) ---
	var arm_mat = darkblue_mat.duplicate()
	
	teacher_right_arm = MeshInstance3D.new()
	teacher_right_arm.name = "RightArm"
	teacher_right_arm.mesh = CylinderMesh.new()
	teacher_right_arm.mesh.top_radius = 0.025
	teacher_right_arm.mesh.bottom_radius = 0.03
	teacher_right_arm.mesh.height = 0.38
	teacher_right_arm.mesh.material = arm_mat
	teacher_right_arm.position = Vector3(0.28, 0.65, -0.05)
	teacher_right_arm.rotation.z = -0.1
	teacher_node.add_child(teacher_right_arm)
	
	# Левая рука
	var left_arm = MeshInstance3D.new()
	left_arm.name = "LeftArm"
	left_arm.mesh = CylinderMesh.new()
	left_arm.mesh.top_radius = 0.025
	left_arm.mesh.bottom_radius = 0.03
	left_arm.mesh.height = 0.38
	left_arm.mesh.material = arm_mat
	left_arm.position = Vector3(-0.28, 0.65, -0.05)
	left_arm.rotation.z = 0.1
	teacher_node.add_child(left_arm)
	
	# --- УКАЗКА ---
	var pointer_mat = StandardMaterial3D.new()
	pointer_mat.albedo_color = Color(0.5, 0.32, 0.12)
	pointer_mat.roughness = 0.6
	
	teacher_pointer = MeshInstance3D.new()
	teacher_pointer.name = "Pointer"
	teacher_pointer.mesh = CylinderMesh.new()
	teacher_pointer.mesh.top_radius = 0.006
	teacher_pointer.mesh.bottom_radius = 0.01
	teacher_pointer.mesh.height = 0.5
	teacher_pointer.mesh.material = pointer_mat
	teacher_pointer.position = Vector3(0.36, 0.58, -0.22)
	teacher_pointer.rotation = Vector3(0.4, 0.0, 0.15)
	teacher_node.add_child(teacher_pointer)
	
	add_child(teacher_node)
	
	# Инициализация анимации
	teacher_state = TeacherState.IDLE
	teacher_idle_timer = randf_range(0.0, 1.5)
	teacher_blink_timer = randf_range(1.0, 3.0)


# ============================================================
# ПАРТЫ — 4 КОЛОНКИ x 3 РЯДА
# ============================================================
func _create_desks():
	var desk_mat = StandardMaterial3D.new()
	desk_mat.albedo_color = Color(0.52, 0.38, 0.18)
	desk_mat.roughness = 0.8
	
	var leg_mat = StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.45, 0.35, 0.3)
	leg_mat.roughness = 0.7
	leg_mat.metallic = 0.3
	
	for row in range(NUM_ROWS):
		for col in range(NUM_COLS):
			var desk = Node3D.new()
			desk.name = "Desk_R" + str(row) + "_C" + str(col)
			desk.position = Vector3(DESK_X[col], 0.0, DESK_Z[row])
			
			# Столешница
			var top = MeshInstance3D.new()
			top.mesh = BoxMesh.new()
			top.mesh.size = Vector3(0.5, 0.03, 0.45)
			top.mesh.material = desk_mat
			top.position = Vector3(0.0, 0.76, 0.0)
			desk.add_child(top)
			
			# Ящик под столешницей (полка для книг)
			var shelf = MeshInstance3D.new()
			shelf.mesh = BoxMesh.new()
			shelf.mesh.size = Vector3(0.46, 0.02, 0.41)
			var shelf_mat = desk_mat.duplicate()
			shelf_mat.albedo_color = Color(0.45, 0.32, 0.15)
			shelf.mesh.material = shelf_mat
			shelf.position = Vector3(0.0, 0.5, 0.0)
			desk.add_child(shelf)
			
			# Ножки
			for lx in [-0.2, 0.2]:
				for lz in [-0.18, 0.18]:
					var leg = MeshInstance3D.new()
					leg.mesh = CylinderMesh.new()
					leg.mesh.top_radius = 0.015
					leg.mesh.bottom_radius = 0.018
					leg.mesh.height = 0.5
					leg.mesh.material = leg_mat
					leg.position = Vector3(lx, 0.25, lz)
					desk.add_child(leg)
			
			add_child(desk)
			desk_nodes.append(desk)


# ============================================================
# ПОЗИЦИИ УЧЕНИКОВ (вычисляются, затем создаются студенты)
# ============================================================
func _create_student_positions():
	_student_positions.clear()
	
	for row in range(NUM_ROWS):
		for col in range(NUM_COLS):
			# Каждый ученик позади своей парты, слегка правее
			var pos = Vector3(
				DESK_X[col] + 0.1,
				0.0,
				DESK_Z[row] + 0.25
			)
			_student_positions.append(pos)


# ============================================================
# УЧЕНИКИ
# ============================================================
func _create_students():
	var student_script = load("res://scripts/student.gd")
	
	for i in range(_student_positions.size()):
		var student = Node3D.new()
		student.set_script(student_script)
		student.name = "Student_" + str(i)
		student.position = _student_positions[i]
		
		# Небольшой разброс в повороте (живой вид)
		student.rotation.y = randf_range(-0.06, 0.06)
		
		add_child(student)
		student.build(i)
		students.append(student)


# ============================================================
# ФЛУОРЕСЦЕНТНЫЕ ЛАМПЫ НА ПОТОЛКЕ
# ============================================================
func _create_fluorescent_lights():
	var light_positions = [
		Vector3(-1.5, ROOM_H - 0.05, 1.0),
		Vector3(1.5, ROOM_H - 0.05, 1.0),
		Vector3(-1.5, ROOM_H - 0.05, -0.5),
		Vector3(1.5, ROOM_H - 0.05, -0.5),
	]
	
	var tube_mat = StandardMaterial3D.new()
	tube_mat.albedo_color = Color(0.85, 0.88, 1.0)
	tube_mat.emission_enabled = true
	tube_mat.emission = Color(0.7, 0.78, 1.0)
	tube_mat.emission_energy_multiplier = 0.5
	tube_mat.roughness = 0.3
	
	var mount_mat = StandardMaterial3D.new()
	mount_mat.albedo_color = Color(0.6, 0.6, 0.6)
	mount_mat.roughness = 0.7
	
	for pos in light_positions:
		var light_group = Node3D.new()
		light_group.name = "FluorescentLight_" + str(light_positions.find(pos))
		light_group.position = pos
		
		# Лампа (трубка)
		var tube = MeshInstance3D.new()
		tube.mesh = CylinderMesh.new()
		tube.mesh.top_radius = 0.03
		tube.mesh.bottom_radius = 0.03
		tube.mesh.height = 1.2
		tube.mesh.material = tube_mat
		tube.rotation.x = PI * 0.5
		light_group.add_child(tube)
		
		# Корпус
		var housing = MeshInstance3D.new()
		housing.mesh = BoxMesh.new()
		housing.mesh.size = Vector3(1.2, 0.03, 0.08)
		housing.mesh.material = mount_mat
		housing.position = Vector3(0.0, 0.01, 0.0)
		light_group.add_child(housing)
		
		# OmniLight для освещения
		var omni = OmniLight3D.new()
		omni.name = "Light"
		omni.light_color = Color(0.72, 0.78, 1.0)
		omni.light_energy = 0.35
		omni.omni_range = 4.5
		omni.position = Vector3(0.0, -0.1, 0.0)
		light_group.add_child(omni)
		fluorescent_lights.append(omni)
		
		add_child(light_group)


# ============================================================
# ПЛАКАТЫ НА СТЕНАХ
# ============================================================
func _create_posters():
	# Плакат 1: "67" мемный
	_create_poster(
		"67",
		Vector3(-3.0, 2.0, ROOM_D * 0.5 - 0.01),
		Color(0.9, 0.15, 0.1),
		Color(1.0, 1.0, 1.0),
		0.5, 0.6
	)
	
	# Плакат 2: "КЛАССНЫЙ УГОЛОК"
	_create_poster(
		"КЛАССНЫЙ\nУГОЛОК",
		Vector3(3.0, 2.2, ROOM_D * 0.5 - 0.01),
		Color(0.9, 0.85, 0.6),
		Color(0.2, 0.2, 0.2),
		0.5, 0.7
	)
	
	# Плакат 3: Расписание (слегка криво)
	_create_poster(
		"РАСПИСАНИЕ",
		Vector3(3.5, 1.6, ROOM_D * 0.5 - 0.01),
		Color(0.95, 0.95, 0.85),
		Color(0.15, 0.15, 0.2),
		0.4, 0.5
	)
	
	# Плакат 4: советский стиль "МОЙКА РУК"
	_create_poster(
		"МОЙ\nРУКИ",
		Vector3(-2.5, 1.3, -ROOM_D * 0.5 + 0.01),
		Color(0.8, 0.9, 0.75),
		Color(0.1, 0.15, 0.1),
		0.3, 0.4
	)


# ============================================================
# СОЗДАНИЕ ОДНОГО ПЛАКАТА
# QuadMesh + Label3D, процедурно
# ============================================================
func _create_poster(text: String, pos: Vector3, bg: Color, fg: Color, w: float, h: float):
	var poster = Node3D.new()
	poster.name = "Poster"
	
	# Фон
	var bg_mesh = MeshInstance3D.new()
	bg_mesh.mesh = QuadMesh.new()
	bg_mesh.mesh.size = Vector2(w, h)
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = bg
	bg_mat.roughness = 0.9
	bg_mesh.mesh.material = bg_mat
	
	# Рамка
	var border_mat = StandardMaterial3D.new()
	border_mat.albedo_color = Color(0.15, 0.15, 0.15)
	
	var border_top = MeshInstance3D.new()
	border_top.mesh = QuadMesh.new()
	border_top.mesh.size = Vector2(w + 0.04, 0.02)
	border_top.mesh.material = border_mat
	border_top.position = Vector3(0.0, h * 0.5 + 0.01, 0.001)
	poster.add_child(border_top)
	
	var border_bottom = border_top.duplicate()
	border_bottom.position = Vector3(0.0, -h * 0.5 - 0.01, 0.001)
	poster.add_child(border_bottom)
	
	var border_left = MeshInstance3D.new()
	border_left.mesh = QuadMesh.new()
	border_left.mesh.size = Vector2(0.02, h + 0.04)
	border_left.mesh.material = border_mat
	border_left.position = Vector3(-w * 0.5 - 0.01, 0.0, 0.001)
	poster.add_child(border_left)
	
	var border_right = border_left.duplicate()
	border_right.position = Vector3(w * 0.5 + 0.01, 0.0, 0.001)
	poster.add_child(border_right)
	
	poster.add_child(bg_mesh)
	
	# Текст
	var label = Label3D.new()
	label.text = text
	label.font_size = 18
	label.modulate = fg
	label.position = Vector3(0.0, 0.0, 0.005)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.pixel_size = 0.005
	poster.add_child(label)
	
	# Случайный небольшой перекос (криво висящие плакаты)
	if randf() > 0.5:
		poster.rotation.z = randf_range(-0.03, 0.03)
	
	poster.position = pos
	
	# Плакат на стену: поворот в зависимости от стены
	# Если плакат на задней стене (z большой положительный)
	if pos.z > 0.0:
		pass  # уже смотрит в класс
	# Если на передней стене
	elif pos.z < 0.0:
		poster.rotation.y = PI  # повернуть к классу
	
	add_child(poster)


# ============================================================
# ПЫЛЬ В ВОЗДУХЕ (легкие парящие частицы)
# ============================================================
func _create_dust():
	var particles = GPUParticles3D.new()
	particles.name = "DustParticles"
	particles.position = Vector3(0.0, 1.5, 0.0)
	particles.amount = 40
	particles.lifetime = 12.0
	particles.one_shot = false
	particles.emitting = true
	particles.fixed_fps = 10  # экономим производительность
	
	var process_mat = ParticleProcessMaterial.new()
	process_mat.spread = 180.0
	process_mat.initial_velocity_min = 0.0
	process_mat.initial_velocity_max = 0.015
	process_mat.gravity = Vector3(0.0, -0.005, 0.0)
	process_mat.lifetime_randomness = 0.5
	process_mat.scale_min = 0.003
	process_mat.scale_max = 0.015
	process_mat.color = Color(0.85, 0.85, 0.8, 0.25)
	process_mat.angle_min = 0.0
	process_mat.angle_max = 360.0
	
	# Альфа-кривая (появление и растворение)
	var grad = Gradient.new()
	grad.add_point(0.0, Color(0.85, 0.85, 0.8, 0.0))
	grad.add_point(0.1, Color(0.85, 0.85, 0.8, 0.3))
	grad.add_point(0.5, Color(0.85, 0.85, 0.8, 0.15))
	grad.add_point(0.9, Color(0.85, 0.85, 0.8, 0.2))
	grad.add_point(1.0, Color(0.85, 0.85, 0.8, 0.0))
	process_mat.color = Color(0.85, 0.85, 0.8, 0.2)
	
	particles.process_material = process_mat
	
	# Меш для частиц (крошечный квадрат)
	var quad = QuadMesh.new()
	quad.size = Vector2(0.01, 0.01)
	quad.material = StandardMaterial3D.new()
	quad.material.albedo_color = Color(1.0, 1.0, 1.0, 0.3)
	quad.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	
	particles.draw_pass_1 = quad
	
	add_child(particles)
	
	# Симуляция для заполнения пространства с первого кадра
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func():
		if is_instance_valid(particles):
			particles.restart()
	)


# ============================================================
# ДЕТАЛИ: ТРЯПКА, МЕЛ, СМЯТАЯ БУМАГА
# ============================================================
func _create_details():
	# --- Тряпка для доски (на краю доски) ---
	var rag_mat = StandardMaterial3D.new()
	rag_mat.albedo_color = Color(0.5, 0.4, 0.35)
	rag_mat.roughness = 1.0
	
	var rag = MeshInstance3D.new()
	rag.name = "Rag"
	rag.mesh = BoxMesh.new()
	rag.mesh.size = Vector3(0.08, 0.02, 0.15)
	rag.mesh.material = rag_mat
	rag.position = Vector3(2.0, 0.6, -2.75)
	rag.rotation.z = randf_range(-0.1, 0.1)
	add_child(rag)
	
	# --- Мелок (на доске) ---
	var chalk_colors = [Color(1.0, 1.0, 1.0), Color(1.0, 0.9, 0.5), Color(0.8, 0.9, 0.6)]
	
	for i in range(3):
		var chalk_mat = StandardMaterial3D.new()
		chalk_mat.albedo_color = chalk_colors[i % chalk_colors.size()]
		chalk_mat.roughness = 0.9
		
		var chalk = MeshInstance3D.new()
		chalk.name = "Chalk_" + str(i)
		chalk.mesh = CylinderMesh.new()
		chalk.mesh.top_radius = 0.005
		chalk.mesh.bottom_radius = 0.006
		chalk.mesh.height = 0.05
		chalk.mesh.material = chalk_mat
		chalk.position = Vector3(-1.5 + i * 0.12, 0.12, -2.75)
		chalk.rotation.x = randf_range(-0.2, 0.2)
		chalk.rotation.z = randf_range(-0.2, 0.2)
		add_child(chalk)
	
	# --- Смятая бумажка на полу ---
	var paper_mat = StandardMaterial3D.new()
	paper_mat.albedo_color = Color(0.9, 0.88, 0.8)
	paper_mat.roughness = 0.9
	
	var paper = MeshInstance3D.new()
	paper.name = "CrumpledPaper"
	paper.mesh = BoxMesh.new()
	paper.mesh.size = Vector3(0.04, 0.02, 0.03)
	paper.mesh.material = paper_mat
	paper.position = Vector3(-1.8, 0.02, 2.0)
	paper.rotation = Vector3(randf_range(-0.5, 0.5), randf_range(0.0, PI), randf_range(-0.3, 0.3))
	add_child(paper)
	
	# --- Огрызок ручки на полу ---
	var pen_mat = StandardMaterial3D.new()
	pen_mat.albedo_color = Color(0.2, 0.3, 0.7)
	pen_mat.roughness = 0.5
	
	var pen = MeshInstance3D.new()
	pen.name = "Pen"
	pen.mesh = CylinderMesh.new()
	pen.mesh.top_radius = 0.004
	pen.mesh.bottom_radius = 0.005
	pen.mesh.height = 0.1
	pen.mesh.material = pen_mat
	pen.position = Vector3(2.2, 0.016, 1.5)
	pen.rotation.x = PI * 0.5
	pen.rotation.z = randf_range(-0.5, 0.5)
	add_child(pen)


# ============================================================
# РЕАКЦИЯ УЧИТЕЛЯ НА 67
# Вызывается из game_manager при успешном клике по 67
# ============================================================
func teacher_on_sixtyseven_clicked():
	if teacher_state == TeacherState.REACTING:
		return
	
	teacher_state = TeacherState.REACTING
	
	# Останавливаем idle анимацию
	if teacher_reaction_tween and teacher_reaction_tween.is_valid():
		teacher_reaction_tween.kill()
	
	# --- ПОСЛЕДОВАТЕЛЬНОСТЬ: FREEZE → SLOW TURN → ANGRY → RETURN ---
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	teacher_reaction_tween = tween
	
	# Фаза 1: FREEZE — резко останавливается, смотрит в доску (0.2s)
	tween.tween_callback(_teacher_expression_idle)
	tween.tween_interval(0.2)
	
	# Фаза 2: МЕДЛЕННЫЙ ПОВОРОТ головы к классу (0.7s)
	# Голова поворачивается вправо, слегка вниз (осуждающий взгляд)
	tween.tween_property(teacher_head_pivot, "rotation:y", 0.35, 0.7)
	tween.parallel().tween_property(teacher_head_pivot, "rotation:x", -0.04, 0.7)
	
	# Фаза 3: ЗЛОСТЬ — брови вниз, губы сжаты (0.15s)
	tween.tween_callback(_teacher_expression_angry)
	
	# Держит злой взгляд (1.2s)
	tween.tween_interval(1.2)
	
	# Фаза 4: ВОЗВРАТ к доске (0.4s)
	tween.tween_property(teacher_head_pivot, "rotation", Vector3.ZERO, 0.4)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Фаза 5: возврат в idle
	tween.tween_callback(_teacher_return_to_idle)


# ============================================================
# РЕАКЦИЯ УЧИТЕЛЯ НА ПРОМАХ (быстрое раздражение)
# ============================================================
func teacher_on_miss():
	if teacher_state == TeacherState.REACTING:
		return
	
	teacher_state = TeacherState.REACTING
	
	if teacher_reaction_tween and teacher_reaction_tween.is_valid():
		teacher_reaction_tween.kill()
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	teacher_reaction_tween = tween
	
	# Быстрый поворот головы + брови вниз
	tween.tween_property(teacher_head_pivot, "rotation:y", -0.15, 0.15)
	tween.parallel().tween_callback(_teacher_expression_angry)
	
	tween.tween_interval(0.5)
	
	tween.tween_property(teacher_head_pivot, "rotation", Vector3.ZERO, 0.2)
	tween.tween_callback(_teacher_return_to_idle)


# ============================================================
# ВЫРАЖЕНИЯ ЛИЦА
# ============================================================
func _teacher_expression_idle():
	if not is_instance_valid(teacher_left_eyebrow):
		return
	
	# Нейтральное положение бровей
	teacher_left_eyebrow.rotation = Vector3.ZERO
	teacher_right_eyebrow.rotation = Vector3.ZERO
	teacher_left_eyebrow.position.y = 0.095
	teacher_right_eyebrow.position.y = 0.095
	
	# Расслабленный рот
	if is_instance_valid(teacher_mouth):
		teacher_mouth.position.y = -0.06
		teacher_mouth.scale = Vector3(1.0, 1.0, 1.0)


func _teacher_expression_angry():
	if not is_instance_valid(teacher_left_eyebrow):
		return
	
	# Брови вниз и к центру (угрожающий взгляд)
	teacher_left_eyebrow.rotation.z = 0.25
	teacher_right_eyebrow.rotation.z = -0.25
	teacher_left_eyebrow.position.y = 0.08
	teacher_right_eyebrow.position.y = 0.08
	
	# Рот сжат
	if is_instance_valid(teacher_mouth):
		teacher_mouth.position.y = -0.05
		teacher_mouth.scale = Vector3(1.3, 0.5, 1.0)


func _teacher_expression_tired():
	if not is_instance_valid(teacher_left_eyebrow):
		return
	
	# Брови слегка приподняты, усталый вид
	teacher_left_eyebrow.rotation.z = -0.05
	teacher_right_eyebrow.rotation.z = 0.05
	teacher_left_eyebrow.position.y = 0.1
	teacher_right_eyebrow.position.y = 0.1


# ============================================================
# IDLE АНИМАЦИЯ УЧИТЕЛЯ (случайные движения)
# ============================================================
func _update_teacher_idle(delta):
	if not is_instance_valid(teacher_head_pivot):
		return
	
	# МОРГАНИЕ
	teacher_blink_timer += delta
	if teacher_blink_timer > 2.5:
		teacher_blink_timer = 0.0
		_blink_teacher_eyes()
	
	# СЛУЧАЙНЫЕ ПОВОРОТЫ ГОЛОВЫ
	teacher_idle_timer += delta
	if teacher_idle_timer > _next_idle_interval():
		teacher_idle_timer = 0.0
		_random_head_movement()


func _next_idle_interval() -> float:
	return randf_range(1.5, 4.0)


func _random_head_movement():
	if teacher_state != TeacherState.IDLE:
		return
	
	var target_rot = Vector3(
		randf_range(-0.02, 0.02),
		randf_range(-0.2, 0.2),
		0.0
	)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(teacher_head_pivot, "rotation", target_rot, randf_range(0.4, 0.8))
	
	# Через случайный интервал возвращаем голову
	var hold = randf_range(0.8, 2.5)
	var return_tween = create_tween()
	return_tween.set_ease(Tween.EASE_IN_OUT)
	return_tween.set_trans(Tween.TRANS_SINE)
	return_tween.tween_interval(hold)
	return_tween.tween_property(teacher_head_pivot, "rotation", Vector3.ZERO, 0.3)


func _blink_teacher_eyes():
	if teacher_state != TeacherState.IDLE:
		return
	
	if not is_instance_valid(teacher_left_eye):
		return
	
	# Быстро сжать глаза по Y, потом открыть
	var blink_tween = create_tween()
	blink_tween.set_ease(Tween.EASE_IN_OUT)
	blink_tween.tween_property(teacher_left_eye, "scale:y", 0.1, 0.03)
	blink_tween.parallel().tween_property(teacher_right_eye, "scale:y", 0.1, 0.03)
	blink_tween.tween_property(teacher_left_eye, "scale:y", 1.0, 0.04)
	blink_tween.parallel().tween_property(teacher_right_eye, "scale:y", 1.0, 0.04)


func _teacher_return_to_idle():
	teacher_state = TeacherState.IDLE
	_teacher_expression_tired()


# ============================================================
# 67 MOMENT — Ученики встают и делают мемный жест
# ============================================================
func do_sixtyseven_moment():
	print("Класс: 67 MOMENT!")
	
	var num_to_activate = randi() % 2 + 2
	var shuffled = students.duplicate()
	shuffled.shuffle()
	
	for i in range(min(num_to_activate, shuffled.size())):
		var student = shuffled[i]
		if is_instance_valid(student):
			student.do_sixtyseven_pose()
	
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(_reset_students)


# ============================================================
# СМЕХ КЛАССА
# ============================================================
func do_class_laugh():
	print("Класс: ХА-ХА!")
	
	for student in students:
		if is_instance_valid(student):
			student.do_laugh()


# ============================================================
# СБРОС ПОЗЫ УЧЕНИКОВ
# ============================================================
func _reset_students():
	for student in students:
		if is_instance_valid(student):
			student.reset_pose()


# ============================================================
# ОБНОВЛЕНИЕ RAGE ВИЗУАЛА УЧИТЕЛЯ
# ============================================================
func teacher_increase_rage(rage_ratio: float):
	if not is_instance_valid(teacher_body_mesh):
		return
	
	# Меняем цвет пиджака от темно-синего к красному
	var rage_mat = StandardMaterial3D.new()
	var color_r = lerp(0.15, 1.0, rage_ratio)
	var color_g = lerp(0.18, 0.1, rage_ratio)
	var color_b = lerp(0.25, 0.05, rage_ratio)
	rage_mat.albedo_color = Color(color_r, color_g, color_b)
	rage_mat.roughness = 0.7
	teacher_body_mesh.set_surface_override_material(0, rage_mat)
