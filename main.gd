# ============================================================
# MAIN.GD - Главная точка входа
# Создает 3D сцену класса, камеру, освещение,
# доску, UI и запускает игровой менеджер
# ============================================================

extends Node


func _ready():
	# Включаем физический рейкастинг для кликов по 3D объектам
	get_viewport().physics_object_picking = true
	
	# Холодный clear color — зимнее утро, легкий зеленый оттенок
	RenderingServer.set_default_clear_color(Color(0.55, 0.58, 0.6, 1.0))
	
	# Создаем окружение, класс, доску, UI и менеджер игры
	_create_environment()
	_create_classroom()
	_create_blackboard()
	_create_ui()
	_create_event_manager()
	_create_game_manager()


# ============================================================
# СОЗДАНИЕ ОКРУЖЕНИЯ
# Камера в стиле found footage / мемных видео
# Холодное флуоресцентное освещение
# ============================================================
func _create_environment():
	
	# --- КАМЕРА: found footage стиль ---
	# Позиция: за последними партами, справа, на уровне глаз сидящего
	# FOV 78° — широкий угол как на мемных видосах
	var camera = Camera3D.new()
	camera.name = "Camera"
	camera.fov = 78.0
	camera.h_offset = 0.01
	camera.v_offset = -0.005
	add_child(camera)
	camera.current = true
	camera.position = Vector3(1.5, 1.65, 3.0)
	camera.look_at(Vector3(-0.3, 1.6, -1.0))
	
	# --- DirectionalLight: холодный утренний свет из окна ---
	# Зимнее утро, солнце низко, свет холодный синеватый
	var main_light = DirectionalLight3D.new()
	main_light.name = "MainLight"
	main_light.light_energy = 0.8
	main_light.light_color = Color(0.6, 0.65, 0.9)
	main_light.shadow_enabled = true
	main_light.shadow_bias = 0.02
	add_child(main_light)
	main_light.position = Vector3(5.0, 7.0, 3.0)
	main_light.look_at(Vector3(0.0, 0.0, -1.0))
	
	# --- WorldEnvironment: ambient light (чтобы не было черных пятен) ---
	var world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env = Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.48, 0.55)
	env.ambient_light_energy = 0.6
	world_env.environment = env
	add_child(world_env)


# ============================================================
# СОЗДАНИЕ КЛАССА
# Учитель, парты, ученики
# ============================================================
func _create_classroom():
	var classroom_script = load("res://scripts/classroom.gd")
	var classroom_node = Node.new()
	classroom_node.set_script(classroom_script)
	classroom_node.name = "Classroom"
	add_child(classroom_node)
	classroom_node.build()


# ============================================================
# СОЗДАНИЕ ДОСКИ
# Генерация чисел, клики
# ============================================================
func _create_blackboard():
	var blackboard_script = load("res://scripts/blackboard.gd")
	var blackboard_node = Node3D.new()
	blackboard_node.set_script(blackboard_script)
	blackboard_node.name = "Blackboard"
	add_child(blackboard_node)
	blackboard_node.build()


# ============================================================
# СОЗДАНИЕ UI
# Rage meter, деньги, статус
# ============================================================
func _create_ui():
	var ui_script = load("res://scripts/ui.gd")
	var ui_node = CanvasLayer.new()
	ui_node.set_script(ui_script)
	ui_node.name = "UI"
	add_child(ui_node)
	ui_node.build()


# ============================================================
# СОЗДАНИЕ EVENT MANAGER
# Система внезапных событий
# ============================================================
func _create_event_manager():
	var em_script = load("res://scripts/event_manager.gd")
	var em_node = Node.new()
	em_node.set_script(em_script)
	em_node.name = "EventManager"
	add_child(em_node)

# ============================================================
# СОЗДАНИЕ GAME MANAGER
# Игровой цикл, сложность, экономика
# ============================================================
func _create_game_manager():
	var gm_script = load("res://scripts/game_manager.gd")
	var gm_node = Node.new()
	gm_node.set_script(gm_script)
	gm_node.name = "GameManager"
	add_child(gm_node)
	
	# Передаем ссылки на остальные системы
	var found_blackboard = get_node("Blackboard")
	var found_classroom = get_node("Classroom")
	var found_ui = get_node("UI")
	var found_event_manager = get_node("EventManager")
	gm_node.init(found_blackboard, found_classroom, found_ui, found_event_manager)
	gm_node.start_game()
