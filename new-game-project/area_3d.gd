extends Area3D

const RESET_POSITION := Vector3(57.478, 1.005, -14.563)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.global_position = RESET_POSITION
