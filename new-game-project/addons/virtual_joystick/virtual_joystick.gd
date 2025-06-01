class_name VirtualJoystick
extends Control

# EXPORTED VARIABLES
@export var pressed_color := Color.GRAY
@export_range(0, 200, 1) var deadzone_size : float = 10
@export_range(0, 500, 1) var clampzone_size : float = 75

enum Joystick_mode {
	FIXED,
	DYNAMIC,
	FOLLOWING
}
@export var joystick_mode := Joystick_mode.FIXED

enum Visibility_mode {
	ALWAYS,
	TOUCHSCREEN_ONLY,
	WHEN_TOUCHED
}
@export var visibility_mode := Visibility_mode.ALWAYS

@export var use_input_actions := true
@export var action_left := "ui_left"
@export var action_right := "ui_right"
@export var action_up := "ui_up"
@export var action_down := "ui_down"

# PUBLIC VARIABLES
var is_pressed := false
var output := Vector2.ZERO

# PRIVATE VARIABLES
var _touch_index : int = -1

# Fixed node references with proper error checking
@onready var _base: TextureRect = get_node_or_null("Base")
@onready var _tip: TextureRect = get_node_or_null("Base/Tip")
@onready var _default_color : Color = Color.WHITE

var _base_default_position : Vector2
var _tip_default_position : Vector2

# FUNCTIONS
func _ready() -> void:
	# Check if nodes exist before proceeding
	if not _base:
		push_error("VirtualJoystick: Base node not found! Make sure you have a TextureRect child named 'Base'")
		return
	
	if not _tip:
		push_error("VirtualJoystick: Tip node not found! Make sure Base has a TextureRect child named 'Tip'")
		return
	
	# Set default color only if tip exists
	_default_color = _tip.modulate
	
	if ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"):
		printerr("The Project Setting 'emulate_mouse_from_touch' should be set to False")
	if not ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse"):
		printerr("The Project Setting 'emulate_touch_from_mouse' should be set to True")
	
	if not DisplayServer.is_touchscreen_available() and visibility_mode == Visibility_mode.TOUCHSCREEN_ONLY:
		hide()
	
	if visibility_mode == Visibility_mode.WHEN_TOUCHED:
		hide()

	_base_default_position = _base.position
	_tip_default_position = _tip.position

func _input(event: InputEvent) -> void:
	# Return early if nodes don't exist
	if not _base or not _tip:
		return
		
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_point_inside_joystick_area(event.position) and _touch_index == -1:
				if joystick_mode == Joystick_mode.DYNAMIC or joystick_mode == Joystick_mode.FOLLOWING or (joystick_mode == Joystick_mode.FIXED and _is_point_inside_base(event.position)):
					if joystick_mode == Joystick_mode.DYNAMIC or joystick_mode == Joystick_mode.FOLLOWING:
						_move_base(event.position)
					if visibility_mode == Visibility_mode.WHEN_TOUCHED:
						show()
					_touch_index = event.index
					_tip.modulate = pressed_color
					_update_joystick(event.position)
					get_viewport().set_input_as_handled()
		elif event.index == _touch_index:
			_reset()
			if visibility_mode == Visibility_mode.WHEN_TOUCHED:
				hide()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_joystick(event.position)
			get_viewport().set_input_as_handled()

func _move_base(new_position: Vector2) -> void:
	if not _base:
		return
	_base.global_position = new_position - _base.pivot_offset * get_global_transform_with_canvas().get_scale()

func _move_tip(new_position: Vector2) -> void:
	if not _tip:
		return
	_tip.global_position = new_position - _tip.pivot_offset * _base.get_global_transform_with_canvas().get_scale()

func _is_point_inside_joystick_area(point: Vector2) -> bool:
	var x: bool = point.x >= global_position.x and point.x <= global_position.x + (size.x * get_global_transform_with_canvas().get_scale().x)
	var y: bool = point.y >= global_position.y and point.y <= global_position.y + (size.y * get_global_transform_with_canvas().get_scale().y)
	return x and y

func _get_base_radius() -> Vector2:
	if not _base:
		return Vector2.ZERO
	return _base.size * _base.get_global_transform_with_canvas().get_scale() / 2

func _is_point_inside_base(point: Vector2) -> bool:
	if not _base:
		return false
	var _base_radius = _get_base_radius()
	var center : Vector2 = _base.global_position + _base_radius
	var vector : Vector2 = point - center
	return vector.length_squared() <= _base_radius.x * _base_radius.x

func _update_joystick(touch_position: Vector2) -> void:
	if not _base or not _tip:
		return
		
	var _base_radius = _get_base_radius()
	var center : Vector2 = _base.global_position + _base_radius
	var vector : Vector2 = touch_position - center
	vector = vector.limit_length(clampzone_size)
	
	if joystick_mode == Joystick_mode.FOLLOWING and touch_position.distance_to(center) > clampzone_size:
		_move_base(touch_position - vector)
	
	_move_tip(center + vector)
	
	if vector.length_squared() > deadzone_size * deadzone_size:
		is_pressed = true
		output = (vector - (vector.normalized() * deadzone_size)) / (clampzone_size - deadzone_size)
	else:
		is_pressed = false
		output = Vector2.ZERO
	
	if use_input_actions:
		# Release actions
		if output.x >= 0 and Input.is_action_pressed(action_left):
			Input.action_release(action_left)
		if output.x <= 0 and Input.is_action_pressed(action_right):
			Input.action_release(action_right)
		if output.y >= 0 and Input.is_action_pressed(action_up):
			Input.action_release(action_up)
		if output.y <= 0 and Input.is_action_pressed(action_down):
			Input.action_release(action_down)
		# Press actions
		if output.x < 0:
			Input.action_press(action_left, -output.x)
		if output.x > 0:
			Input.action_press(action_right, output.x)
		if output.y < 0:
			Input.action_press(action_up, -output.y)
		if output.y > 0:
			Input.action_press(action_down, output.y)

func _reset():
	if not _base or not _tip:
		return
		
	is_pressed = false
	output = Vector2.ZERO
	_touch_index = -1
	_tip.modulate = _default_color
	_base.position = _base_default_position
	_tip.position = _tip_default_position
	# Release actions
	if use_input_actions:
		for action in [action_left, action_right, action_down, action_up]:
			if Input.is_action_pressed(action):
				Input.action_release(action)
