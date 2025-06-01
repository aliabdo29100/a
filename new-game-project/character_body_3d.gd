extends CharacterBody3D

@onready var head: Node3D = $head
@onready var camera: Camera3D = $head/Camera3D
@onready var fps: Label = $fps

# Movement parameters
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 6.0
@export var sensitivity: float = 0.002
@export var acceleration: float = 10.0
@export var deceleration: float = 15.0

# Bullet parameters
var bullets_left = 40

# Head bobbing parameters
var bobbing_amount = 0.07
var bobbing_speed_walk = 9.0
var bobbing_speed_sprint = 13.0
var bobbing_timer = 0.0
var original_head_position = Vector3.ZERO

# Camera FOV for sprinting effect
var normal_fov: float = 70.0
var sprint_fov: float = 90.0
var fov_transition_speed: float = 5.0

# Physics
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var direction = Vector3.ZERO
var current_speed = walk_speed
var is_sprinting = false

func _ready():
	# Check if nodes exist
	if not head:
		push_error("Player: head node not found!")
		return
	if not camera:
		push_error("Player: camera node not found!")
		return
	
	original_head_position = head.position
	camera.fov = normal_fov
	
	# اظهار الماوس للاختبار على الكومبيوتر
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	# تعطيل حركة الماوس للكاميرا عشان نجرب الجويستيك
	# if event is InputEventMouseMotion:
	# 	if head:
	# 		head.rotate_y(-event.relative.x * sensitivity)
	# 	if camera:
	# 		var current_rotation = camera.rotation.x
	# 		current_rotation -= event.relative.y * sensitivity
	# 		current_rotation = clamp(current_rotation, deg_to_rad(-89), deg_to_rad(89))
	# 		camera.rotation.x = current_rotation
	
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Sprinting
	is_sprinting = Input.is_action_pressed("sprint")
	current_speed = sprint_speed if is_sprinting else walk_speed
	
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	# Input direction
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	direction = Vector3.ZERO
	
	if head:
		var h_rotation = head.global_transform.basis.get_euler().y
		direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, h_rotation).normalized()
	
	# Movement
	if direction:
		velocity.x = lerp(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, deceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, deceleration * delta)
	
	# Move
	move_and_slide()
	
	# Head bobbing
	update_head_bobbing(delta)

func update_head_bobbing(delta):
	if not head:
		return
		
	if is_on_floor() and (abs(velocity.x) > 0.1 or abs(velocity.z) > 0.1):
		var bobbing_speed = bobbing_speed_sprint if is_sprinting else bobbing_speed_walk
		bobbing_timer += delta * bobbing_speed
		var bob_offset = sin(bobbing_timer) * bobbing_amount
		head.position.y = original_head_position.y + bob_offset
	else:
		bobbing_timer = 0.0
		head.position.y = lerp(head.position.y, original_head_position.y, 10 * delta)
