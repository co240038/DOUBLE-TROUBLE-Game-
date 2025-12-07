extends Area2D

@onready var label_not_enough = $Label_NotEnough
@onready var label_ready = $Label_Ready

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return

	if body.cards >= 12:
		label_not_enough.visible = false
		label_ready.visible = true
		# Load the battle scene
		get_tree().change_scene_to_file("res://Scenes/main.tscn")
	else:
		label_ready.visible = false
		label_not_enough.visible = true
