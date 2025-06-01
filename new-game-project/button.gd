extends Button

# يمكنك تغيير مسار المشهد هنا
@export var target_scene: String = "res://main.tscn"

func _ready():
	# ربط إشارة الضغط على الزر بالدالة
	pressed.connect(_on_button_pressed)

func _on_button_pressed():
	# الانتقال إلى المشهد المحدد
	get_tree().change_scene_to_file("res://main.tscn")
