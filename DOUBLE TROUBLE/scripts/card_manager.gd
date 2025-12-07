extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVEMENT_SPEED = 0.1

var screen_size
var card_being_Dragged
var is_hovering_on_card
var player_hand_reference
var drag_offset = Vector2.ZERO
var battle_manager_reference

func _ready() -> void:
	battle_manager_reference = $"../BattleSystem"
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released",
	 on_left_cleaked_released)

func _process(delta: float) -> void:
	if card_being_Dragged:
		var mouse_pos = get_global_mouse_position()
		var clamped_global = Vector2(
			clamp(mouse_pos.x, 0, screen_size.x),
			clamp(mouse_pos.y, 0, screen_size.y)
		)

		var parent = card_being_Dragged.get_parent()
		var local_pos = parent.to_local(clamped_global - drag_offset)
		card_being_Dragged.position = local_pos

func card_clicked(card):
	if card.card_is_in_card_slot:
		return
	else:
		start_drag(card)

func start_drag(card):
	card_being_Dragged = card
	# Remember offset so dragging is smooth even if not clicked at the center
	var mouse_pos = get_global_mouse_position()
	drag_offset = mouse_pos - card.get_global_position()

func finish_drag():
	var card_slot_found = cardslotCheck()
	
	if card_slot_found and not card_slot_found.card_in_slot:
		if card_being_Dragged.ManaCost > battle_manager_reference.player_mana:
		
			player_hand_reference.add_card_to_hand(card_being_Dragged, DEFAULT_CARD_MOVEMENT_SPEED)
			card_being_Dragged = null
			print("Not enough mana to place this card.")
			return
		card_being_Dragged.reparent(card_slot_found.get_parent()) 
		player_hand_reference.remove_card_from_hand(card_being_Dragged)
		card_being_Dragged.position = card_slot_found.position
		card_slot_found.card_in_slot = true
		card_being_Dragged.card_is_in_card_slot = card_slot_found
		battle_manager_reference.player_spell_on_slot.append(card_being_Dragged)
	
	else:
		player_hand_reference.add_card_to_hand(card_being_Dragged, DEFAULT_CARD_MOVEMENT_SPEED)
	
	card_being_Dragged = null

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_left_cleaked_released():
	if card_being_Dragged:
		finish_drag()

func on_hovered_over_card(card):
	if card.card_is_in_card_slot:
		return
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)

func on_hovered_off_card(card):
	is_hovering_on_card = false
	highlight_card(card, false)
	var new_card_hovered = cardCheck()
	if new_card_hovered:
		highlight_card(new_card_hovered, true)
	else:
		is_hovering_on_card = false


func highlight_card(card, hovered):
	var visual = card.get_node("CardIMG")
	var back_visual = card.get_node("BackCardIMG")
	var labels = card.get_node("LabelContainer")
	
	var tween = card.create_tween()
	tween.set_parallel(true)

	if hovered:
		tween.tween_property(visual, "scale", Vector2(0.158, 0.169), 0.1)
		tween.tween_property(visual, "rotation_degrees", 10, 0.1)
		
		tween.tween_property(back_visual, "scale", Vector2(0.158, 0.169), 0.1)
		tween.tween_property(back_visual, "rotation_degrees", 10, 0.1)
		
		tween.parallel().tween_property(labels, "scale", Vector2(1.15, 1.15), 0.1)
		tween.parallel().tween_property(labels, "rotation_degrees", 10, 0.1)
		
		card.z_index = 2
	else:
		tween.tween_property(visual, "scale", Vector2(0.138, 0.149), 0.1)
		tween.tween_property(visual, "rotation_degrees", 0, 0.1)
		
		tween.tween_property(back_visual, "scale", Vector2(0.138, 0.149), 0.1)
		tween.tween_property(back_visual, "rotation_degrees", 0, 0.1)
		
		tween.parallel().tween_property(labels, "scale", Vector2(1, 1), 0.1)
		tween.parallel().tween_property(labels, "rotation_degrees", 0, 0.1)
		
		card.z_index = 1

func cardslotCheck():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()  # ✅ global coordinates
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT

	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null


func cardCheck():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()  # ✅ global coordinates
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD

	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		#return result[0].collider.get_parent()
		return get_card_with_highest_z_index(result)
	return null

func get_card_with_highest_z_index(card):
	var highest_z_card = card[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	for i in range(1, card.size()):
		var current_card = card[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	
	return highest_z_card
