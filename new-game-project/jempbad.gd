extends Area3D

@export var jump_force: float = 25.0  # عدّل حسب رغبتك

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body is CharacterBody3D:
		print("BOIIIIIING 🚀")  # Debug
		body.velocity.y = jump_force
