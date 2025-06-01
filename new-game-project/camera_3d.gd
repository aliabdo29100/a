extends Camera3D
@onready var fps: Label = %FPS

# مكان الكاميرا الأساسي
var base_position := Vector3(0, 2.0, 6)
var base_look_at := Vector3(0, 1.2, 0)

# تحكم بالحركة المحسّنة
var orbit_radius := Vector2(0.8, 0.6)  # نصف قطر مختلف للمحاور X و Z
var vertical_amplitude := 0.2
var tilt_amplitude := 2.0  # ميلان خفيف للكاميرا

# سرعات متنوعة لحركة أكثر طبيعية
var orbit_speed := 0.5
var vertical_speed := 0.4
var tilt_speed := 0.25
var breathing_speed := 0.6  # تأثير التنفس

var time := 0.0
var smooth_time := 0.0

# متغيرات للحركة السلسة
var target_position := Vector3.ZERO
var target_look_at := Vector3.ZERO

func _ready():
	# بداية سلسة
	target_position = base_position
	target_look_at = base_look_at

func _process(delta):
	time += delta
	smooth_time += delta * 0.8  # حركة أبطأ وأنعم
	
	# حركة دورانية بيضاوية أكثر طبيعية
	var angle = smooth_time * orbit_speed
	var offset_x = cos(angle) * orbit_radius.x
	var offset_z = sin(angle * 0.7) * orbit_radius.y  # سرعة مختلفة للمحور Z
	
	# اهتزاز عمودي ناعم مع تأثير التنفس
	var breathing = sin(time * breathing_speed) * 0.1
	var gentle_float = sin(time * vertical_speed) * vertical_amplitude
	var offset_y = gentle_float + breathing
	
	# ميلان خفيف للكاميرا لإضافة ديناميكية
	var tilt_offset = sin(time * tilt_speed) * tilt_amplitude
	
	# موقع الكاميرا المستهدف
	target_position = base_position + Vector3(offset_x, offset_y, offset_z)
	
	# تحريك نقطة النظر قليلاً لمزيد من الحيوية
	var look_offset = Vector3(
		cos(time * 0.3) * 0.1,
		sin(time * 0.4) * 0.05,
		sin(time * 0.2) * 0.08
	)
	target_look_at = base_look_at + look_offset
	
	# تطبيق الحركة بسلاسة
	position = position.lerp(target_position, delta * 2.0)
	
	# النظر إلى الهدف مع ميلان خفيف
	var up_vector = Vector3.UP.rotated(Vector3.FORWARD, deg_to_rad(tilt_offset))
	look_at(target_look_at, up_vector)

# دالة لتغيير نمط الحركة (يمكن استدعاؤها من القائمة)
func set_movement_style(style: String):
	match style:
		"calm":
			orbit_speed = 0.1
			vertical_amplitude = 0.15
			orbit_radius = Vector2(0.6, 0.4)
		"dynamic":
			orbit_speed = 0.25
			vertical_amplitude = 0.3
			orbit_radius = Vector2(1.0, 0.8)
		"cinematic":
			orbit_speed = 0.08
			vertical_amplitude = 0.1
			orbit_radius = Vector2(1.2, 0.3)

# دالة للانتقال السلس لموقع جديد
func transition_to_position(new_base: Vector3, new_look_at: Vector3, duration: float = 2.0):
	var tween = create_tween()
	tween.parallel().tween_property(self, "base_position", new_base, duration)
	tween.parallel().tween_property(self, "base_look_at", new_look_at, duration)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
func update_fps_display():
	var fps_value = Engine.get_frames_per_second()
	fps.text = "FPS: %d" % fps_value
