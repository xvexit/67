extends Node

enum EventType {
	NONE,
	TEST,
	SIXTYSEVEN_RAIN,
	TEACHER_TURN,
	EVERYONE_STAND,
}

const EVENT_NAMES = {
	EventType.TEST: "КОНТРОЛЬНАЯ РАБОТА",
	EventType.SIXTYSEVEN_RAIN: "67 ДОЖДЬ",
	EventType.TEACHER_TURN: "УЧИТЕЛЬ ОБЕРНУЛАСЬ",
	EventType.EVERYONE_STAND: "ВСЕ ВСТАЛИ",
}

const EVENT_COLORS = {
	EventType.TEST: Color(1.0, 0.1, 0.0),
	EventType.SIXTYSEVEN_RAIN: Color(0.0, 1.0, 0.2),
	EventType.TEACHER_TURN: Color(1.0, 0.0, 0.6),
	EventType.EVERYONE_STAND: Color(1.0, 0.8, 0.0),
}

const MIN_EVENT_INTERVAL := 20.0
const MAX_EVENT_INTERVAL := 40.0
const WARNING_DURATION := 1.5

var current_event: int = EventType.NONE
var pending_event: int = EventType.NONE
var event_timer: float = 0.0
var next_event_time: float = 0.0
var event_duration: float = 0.0
var warning_phase: bool = false
var warning_time: float = 0.0
var game_active: bool = false

var game_manager: Node
var blackboard_node: Node
var classroom_node: Node
var ui_node: Node

var camera_node: Camera3D
var _original_camera_pos: Vector3
var _shake_intensity: float = 0.0
var _shake_decay: float = 5.0

signal event_started(event_type)
signal event_ended()

func init(gm, bb, cr, ui):
	game_manager = gm
	blackboard_node = bb
	classroom_node = cr
	ui_node = ui

	var main = get_parent()
	camera_node = main.get_node_or_null("Camera")
	if camera_node:
		_original_camera_pos = camera_node.position

func start():
	game_active = true
	warning_phase = false
	current_event = EventType.NONE
	pending_event = EventType.NONE
	_schedule_next()

func stop():
	game_active = false
	if current_event != EventType.NONE:
		_end_event()
	current_event = EventType.NONE
	pending_event = EventType.NONE
	warning_phase = false
	_shake_intensity = 0.0
	if camera_node and is_instance_valid(camera_node):
		camera_node.position = _original_camera_pos
	ui_node.hide_event_warning()
	ui_node.hide_event_overlay()

func _schedule_next():
	next_event_time = randf_range(MIN_EVENT_INTERVAL, MAX_EVENT_INTERVAL)
	event_timer = 0.0
	warning_phase = false
	pending_event = EventType.NONE

func _process(delta):
	if not game_active:
		return

	if _shake_intensity > 0.0:
		_shake_intensity = max(0.0, _shake_intensity - _shake_decay * delta)
		if camera_node and is_instance_valid(camera_node):
			camera_node.position = _original_camera_pos + Vector3(
				randf_range(-_shake_intensity, _shake_intensity),
				randf_range(-_shake_intensity, _shake_intensity),
				0.0
			)

	if current_event != EventType.NONE:
		event_duration -= delta
		if event_duration <= 0.0:
			_end_event()
		return

	if warning_phase:
		warning_time -= delta
		if warning_time <= 0.0:
			warning_phase = false
			_start_pending_event()
		return

	event_timer += delta
	if event_timer >= next_event_time - WARNING_DURATION:
		_trigger_warning()

func _trigger_warning():
	var events = [
		EventType.TEST,
		EventType.SIXTYSEVEN_RAIN,
		EventType.TEACHER_TURN,
		EventType.EVERYONE_STAND,
	]
	pending_event = events[randi() % events.size()]
	warning_phase = true
	warning_time = WARNING_DURATION

	_shake_intensity = 0.015
	ui_node.show_event_warning(EVENT_NAMES[pending_event], EVENT_COLORS[pending_event])

func _start_pending_event():
	if not game_active or pending_event == EventType.NONE:
		return

	current_event = pending_event
	pending_event = EventType.NONE
	event_duration = _get_event_duration(current_event)
	event_timer = 0.0

	ui_node.hide_event_warning()
	_start_event_effects(current_event)
	event_started.emit(current_event)

func _get_event_duration(event_type: int) -> float:
	match event_type:
		EventType.TEST:
			return 10.0
		EventType.SIXTYSEVEN_RAIN:
			return 8.0
		EventType.TEACHER_TURN:
			return 6.0
		EventType.EVERYONE_STAND:
			return 8.0
	return 8.0

func _start_event_effects(event_type: int):
	match event_type:
		EventType.TEST:
			_start_test()
		EventType.SIXTYSEVEN_RAIN:
			_start_sixtyseven_rain()
		EventType.TEACHER_TURN:
			_start_teacher_turn()
		EventType.EVERYONE_STAND:
			_start_everyone_stand()

func _end_event():
	var ended_type = current_event
	current_event = EventType.NONE

	_end_event_effects(ended_type)

	_schedule_next()
	event_ended.emit()

func _end_event_effects(event_type: int):
	match event_type:
		EventType.TEST:
			_end_test()
		EventType.SIXTYSEVEN_RAIN:
			_end_sixtyseven_rain()
		EventType.TEACHER_TURN:
			_end_teacher_turn()
		EventType.EVERYONE_STAND:
			_end_everyone_stand()

	_shake_intensity = 0.0
	if camera_node and is_instance_valid(camera_node):
		camera_node.position = _original_camera_pos
	pending_event = EventType.NONE

func _start_test():
	ui_node.show_event_overlay(Color(1.0, 0.0, 0.0), 0.15)
	_shake_intensity = 0.05
	blackboard_node.set_spawn_speed_multiplier(2.0)
	blackboard_node.set_number_lifetime_multiplier(0.5)
	game_manager.set_rage_gain_multiplier(2.0)
	classroom_node.do_class_laugh(0.8)
	classroom_node.teacher_increase_rage(0.7)

func _end_test():
	ui_node.hide_event_overlay()
	blackboard_node.set_spawn_speed_multiplier(1.0)
	blackboard_node.set_number_lifetime_multiplier(1.0)
	game_manager.set_rage_gain_multiplier(1.0)

func _start_sixtyseven_rain():
	ui_node.show_event_overlay(Color(0.0, 1.0, 0.2), 0.1)
	_shake_intensity = 0.04
	blackboard_node.start_sixtyseven_rain()
	classroom_node.do_sixtyseven_moment(0.9)

func _end_sixtyseven_rain():
	ui_node.hide_event_overlay()
	blackboard_node.end_sixtyseven_rain()

func _start_teacher_turn():
	ui_node.show_event_overlay(Color(1.0, 0.0, 0.6), 0.08)
	game_manager.set_miss_penalty_multiplier(3.0)
	blackboard_node.set_spawn_speed_multiplier(0.3)
	classroom_node.teacher_stare_at_class(5.0)

func _end_teacher_turn():
	ui_node.hide_event_overlay()
	game_manager.set_miss_penalty_multiplier(1.0)
	blackboard_node.set_spawn_speed_multiplier(1.0)

func _start_everyone_stand():
	ui_node.show_event_overlay(Color(1.0, 0.8, 0.0), 0.12)
	_shake_intensity = 0.08
	classroom_node.all_students_stand_up()
	game_manager.set_bonus_money_rate(5.0)

func _end_everyone_stand():
	ui_node.hide_event_overlay()
	classroom_node.all_students_reset()
	game_manager.set_bonus_money_rate(0.0)
