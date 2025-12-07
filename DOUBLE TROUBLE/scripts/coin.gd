extends Area2D

@onready var game_manager = %GameManager
@onready var animation_player = $AnimationPlayer

# ONCE PLAYER BODY COLLIDES WITH CARD
func _on_body_entered(body):
	game_manager.add_point()
	animation_player.play("pickup")
	body.cards += 1
