extends Node2D

const CARD_WIDTH = 100
const HAND_Y_POSITION = 10
const DEFAULT_CARD_MOVEMENT_SPEED = 0.1

var opponent_hand: Array = []
var center_screen_x: float

# store starting positions keyed by card instance (avoids needing a property on card nodes)
var card_start_positions: Dictionary = {}

# Initialize screen center BEFORE other nodes try to add cards
func _enter_tree() -> void:
	center_screen_x = get_viewport().size.x / 2.0

func _ready() -> void:
	pass


func add_card_to_hand(card: Node2D, speed: float) -> void:
	if card not in opponent_hand:
		opponent_hand.insert(0, card)
		# ensure we have some entry for this card (will be overwritten in update_hand_positions anyway)
		card_start_positions[card] = card.position
		update_hand_positions(speed)
	else:
		var target = card_start_positions.get(card, card.position)
		animate_card_to_position(card, target, DEFAULT_CARD_MOVEMENT_SPEED)


func update_hand_positions(speed: float) -> void:
	for i in range(opponent_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = opponent_hand[i]
		# store the starting/target position in the manager's dictionary
		card_start_positions[card] = new_position
		animate_card_to_position(card, new_position, speed)


func calculate_card_position(index: int) -> float:
	var total_width = (opponent_hand.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2.0
	return x_offset


func animate_card_to_position(card: Node2D, new_position: Vector2, speed: float) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, speed)


func remove_card_from_hand(card: Node2D) -> void:
	if card in opponent_hand:
		opponent_hand.erase(card)
		# also clear stored position for cleanliness
		if card_start_positions.has(card):
			card_start_positions.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVEMENT_SPEED)
