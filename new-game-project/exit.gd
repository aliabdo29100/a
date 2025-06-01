extends Button

func _ready():
	# ربط إشارة الضغط على الزر بالدالة
	pressed.connect(_on_quit_button_pressed)

func _on_quit_button_pressed():
	# إغلاق اللعبة
	get_tree().quit()
