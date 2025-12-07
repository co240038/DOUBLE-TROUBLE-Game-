extends Node

var Battle_Timer
var empty_opponent_card_slot = []
var empty_player_card_slot = []
var opponent_spell_on_slot = []
var player_spell_on_slot = []
var player_hand = []
var player_deck = []
var opponent_hand = []
var opponent_deck = []
var first_opp_turn

var player_health
var opponent_health
var player_mana
var opponent_mana
var player_block
var opponent_block
var drained
var blocked
var funds


const SMALL_CARD_SCALE = 0.6
const CARD_MOVE_SPEED = 0.2
const STARTING_HEALTH = 100
const MANA_PER_TURN = 3
const MAX_MANA = 10


# ---------------------------------------------------------
# READY
# ---------------------------------------------------------
func _on_player_ready_for_battle(_player):
	print("Auto-starting battle...")
	await player_turn()
	await opponent_turn()



func _ready() -> void:
	Battle_Timer = $"../BattleTimer"
	Battle_Timer.one_shot = true
	Battle_Timer.wait_time = 1.0
	
	empty_opponent_card_slot.append($"../CardSlotOppenent")
	empty_player_card_slot.append($"../CardSlotPlayer")
	opponent_hand = $"../OpponentHand".opponent_hand
	player_hand = $"../PlayerHand".player_hand
	opponent_deck = $"../OppenentDeck".opponent_deck
	player_deck = $"../Deck".player_deck
	
	
	player_health = STARTING_HEALTH
	$"../Player_Health".text = str(player_health)
	player_mana = MANA_PER_TURN
	$"../Player_Mana".text = str(player_mana)
	
	opponent_health = STARTING_HEALTH
	$"../Opponent_Health".text = str(opponent_health)
	opponent_mana = 3
	$"../Opponent_Mana".text = str(opponent_mana)
	
	player_block = 0
	$"../Player_Block".text = str(player_block)
	$"../Player_Block".visible = false
	
	opponent_block = 0
	$"../Opponent_Block".text = str(opponent_block)
	$"../Opponent_Block".visible = false
	
	funds = 0
	drained = false
	blocked = false
	first_opp_turn = false
	print("Battle Started!")
	await player_turn()
	await opponent_turn()
# ---------------------------------------------------------
# BUTTON
# ---------------------------------------------------------
func _on_button_pressed() -> void:
	await player_turn()
	if opponent_health <= 0:
		$"../CastButton".disabled = true
		print("Player wins")
		return
	
	await opponent_turn()
	if player_health <= 0:
		$"../CastButton".disabled = true
		print("Opponent wins")
		return
	
	
	if player_deck.size() == 0 and opponent_deck.size() == 0:
		if player_hand.size() and opponent_hand.size() == 0:
			if player_health > opponent_health:
				print("Player wins")
			else:
				print("Opponent wins")
		else:
			return
		return

func player_turn():
	if player_spell_on_slot.size() != 0:
		var player_spell_to_cast = player_spell_on_slot.duplicate()
		for card in player_spell_to_cast:
			# Pass the card and specify the attacker as "Player"
			await AttackSpell(card, "Player")
	
	if opponent_block > 0:
		if blocked == false:
			opponent_block -= 1
			$"../Opponent_Block".text = str(opponent_block)
			if opponent_block == 0:
				$"../Opponent_Block".visible = false
		else:
			blocked = false
		


# ---------------------------------------------------------
# OPPONENT TURN LOGIC
# ---------------------------------------------------------
func opponent_turn():
	if first_opp_turn == false:
		drained = true
		first_opp_turn = true
	
	if drained == false:
		opponent_mana += MANA_PER_TURN + funds
		opponent_mana = min(opponent_mana, MAX_MANA)
	else:
		drained = false
	
	funds = 0
	
	$"../Opponent_Mana".text = str(opponent_mana)
	$"../CastButton".disabled = true
	$"../CastButton".visible = false
	
	Battle_Timer.start()
	await Battle_Timer.timeout
	
	# Draw card
	if $"../OppenentDeck".opponent_deck.size() != 0:
		$"../OppenentDeck".draw_card()
		await wait(1.0)
	
		await wait(1.0)
	
	# Play a card
	if empty_opponent_card_slot.size() != 0:
		await try_play_opponent_card()
	
	# Cast card(s)
	if opponent_spell_on_slot.size() != 0:
		var opponent_spell_to_cast = opponent_spell_on_slot.duplicate()
		for card in opponent_spell_to_cast:
			await AttackSpell(card, "Opponent")
	
	end_opponent_turn()


func AttackSpell(casted_card, attacker: String):
	var target_y: float
	
	var dmg = casted_card.InstantDamage
	var mana_cost = casted_card.ManaCost
	var healing = casted_card.InstantHeal
	var block = casted_card.Shield
	var drain = casted_card.Mana_Drain
	var draw = casted_card.Draw
	
	if attacker == "Opponent":
		target_y = 1080
	else:
		target_y = 100
	
	var cast_target = Vector2(casted_card.position.x, target_y)
	casted_card.z_index = 5
	
	await wait(0.2) # Reduced wait time for a snappier feel
	
	if attacker == "Opponent":
		if dmg != 0:
			#For animation of cards moving to the target
			var tween = get_tree().create_tween()
			tween.tween_property(casted_card, "position", cast_target, CARD_MOVE_SPEED)
			await tween.finished
			
			await wait(0.5)
			
			# Wait briefly after damage is dealt
			if player_block > 0:
				blocked = true
				player_block -= 1
				$"../Player_Block".text = str(player_block)
				if player_block == 0:
					$"../Player_Block".visible = false
			
			else:
				# No block → apply damage
				player_health = max(0, player_health - dmg)
				$"../Player_Health".text = str(player_health)
			
			 # Mana deduction REMOVED: It is handled in try_play_opponent_card()
			await wait(0.5) # Wait for fade effect to complete
			
			var return_tween = get_tree().create_tween()
			return_tween.tween_property(casted_card, "position", casted_card.card_is_in_card_slot.position, CARD_MOVE_SPEED)
			await return_tween.finished # Wait for card to return to slot position
			await wait(0.1) # Final brief pause
			
			opponent_spell_on_slot.erase(casted_card)
			casted_card.queue_free()
			
		elif healing != 0:
			# No attack animation needed
			
			# Opponent heals THEMSELVES
			opponent_health = min(STARTING_HEALTH, opponent_health + healing)
			
			# Update OPPONENT'S health text
			$"../Opponent_Health".text = str(opponent_health)
			
			# Mana deduction REMOVED: It is handled in try_play_opponent_card()
			
			await wait(0.5)
			
			casted_card.get_node("cardfade").play("card_fade")
			await wait(0.5) # Wait for fade effect to complete
			
			var return_tween = get_tree().create_tween()
			return_tween.tween_property(casted_card, "position", casted_card.card_is_in_card_slot.position, CARD_MOVE_SPEED)
			await return_tween.finished # Wait for card to return to slot position
			await wait(0.1) # Final brief pause
			
			opponent_spell_on_slot.erase(casted_card)
			casted_card.queue_free()
			return
		elif drain != 0:
			if drain == 3:
				opponent_mana = max(0, opponent_mana - mana_cost)
				$"../Opponent_Mana".text = str(opponent_mana)
				
				drained = true
				
				opponent_spell_on_slot.erase(casted_card)
				casted_card.queue_free()
			
			else:
				var gained = 0
				for i in range(opponent_hand.size() - 1, -1, -1):
					var card = opponent_hand[i]
					opponent_hand.erase(card)
					if is_instance_valid(card):
						card.queue_free()
					gained += 1
				
				# Add mana immediately (clamped)
				opponent_mana += gained
				opponent_mana = min(opponent_mana, MAX_MANA)
				$"../Opponent_Mana".text = str(opponent_mana)
				
				# cleanup
				opponent_spell_on_slot.erase(casted_card)
				casted_card.queue_free()
				return
			
		elif block != 0:
			opponent_block += block
			$"../Opponent_Block".text = str(opponent_block)
			
			$"../Opponent_Block".visible = true
			
			opponent_spell_on_slot.erase(casted_card)
			casted_card.queue_free()
			return
		
		elif draw != 0:
			if draw == 2:
				for i in draw:
					if $"../OppenentDeck".opponent_deck.size() != 0:
						$"../OppenentDeck".draw_card()
				
				opponent_spell_on_slot.erase(casted_card)
				casted_card.queue_free()
				return
			
			elif draw == 3:
				discard_random_opponent_card()
				
				if $"../OppenentDeck".opponent_deck.size() != 0:
					$"../OppenentDeck".draw_card()
				
				opponent_spell_on_slot.erase(casted_card)
				casted_card.queue_free()
				return
			
			elif draw == 1:
				var exchange = 0
				for i in 3:
					if opponent_hand.size() != 0:
						discard_random_opponent_card()
						exchange += 1
				
				for d in exchange:
					if $"../OppenentDeck".opponent_deck.size() != 0:
						$"../OppenentDeck".draw_card()
				
				opponent_spell_on_slot.erase(casted_card)
				casted_card.queue_free()
				return
			
		else:
			# If a non-damage/non-heal card is cast, deduct mana anyway
			# Mana deduction REMOVED: It is handled in try_play_opponent_card()
			
			await wait(0.5) # Wait briefly to show cast
			
			# --- Cleanup and delete the non-action card ---
			casted_card.get_node("cardfade").play("card_fade")
			await wait(0.5) # Wait for fade effect to complete
			
			var return_tween = get_tree().create_tween()
			return_tween.tween_property(casted_card, "position", casted_card.card_is_in_card_slot.position, CARD_MOVE_SPEED)
			await return_tween.finished # Wait for card to return to slot position
			await wait(0.1) # Final brief pause
			
			if opponent_block == 0:
				$"../Opponent_Block".visible = false
			
			opponent_spell_on_slot.erase(casted_card)
			casted_card.queue_free()
			return
		
	
	
	# --- PLAYER LOGIC --- 
	else:
		# 1. Apply Damage (if any)
		if dmg != 0:
			 #For animation of cards moving to the target
			var tween = get_tree().create_tween()
			tween.tween_property(casted_card, "position", cast_target, CARD_MOVE_SPEED)
			await tween.finished
			
			if opponent_block > 0:
				blocked = true
				opponent_block -= 1
				$"../Opponent_Block".text = str(opponent_block)
				if opponent_block == 0:
					$"../Opponent_Block".visible = false
			
			else:
			# No block → apply damage
				opponent_health = max(0, opponent_health - dmg)
				$"../Opponent_Health".text = str(opponent_health)
				await wait(0.5)
			
			await wait(0.5)
			
			var return_tween = get_tree().create_tween()
			return_tween.tween_property(casted_card, "position", casted_card.card_is_in_card_slot.position, CARD_MOVE_SPEED)
			await return_tween.finished
			await wait(0.1)
		
		# 2. Apply Healing (if any)
		# Uses 'if' so it runs even if damage was applied.
		elif healing != 0:
			# Simple addition logic
			player_health = min(STARTING_HEALTH, player_health + healing)
			print(player_health)
			# FIX: Use call_deferred to ensure the UI update runs safely on the next frame.
			$"../Player_Health".text = str(player_health)
			
			await wait(0.5)
			
		
		elif drain != 0:
			if drain == 3:
				drained = true
				 # 2. Deduct Player Mana (MUST be done here for non-animated cards)
				player_mana = max(0, player_mana - mana_cost)
				$"../Player_Mana".text = str(player_mana)
				
			
			elif drain == 4:
				var gained = 0
				for i in range(player_hand.size() - 1, -1, -1):
					var card = player_hand[i]
					player_hand.erase(card)
					if is_instance_valid(card):
						card.queue_free()
						gained += 1
				
				# Add mana to player immediately and clamp properly
				player_mana += gained
				player_mana = min(player_mana, MAX_MANA)
				$"../Player_Mana".text = str(player_mana)
				
			
			
		elif block != 0:
			player_block += block
			$"../Player_Block".text = str(player_block)
			$"../Player_Block".visible = true
			
			# 2. Deduct Player Mana (MUST be done here for non-animated cards)
			player_mana = max(0, player_mana - mana_cost)
			$"../Player_Mana".text = str(player_mana)
			
			 # 3. Cleanup and Exit
			if is_instance_valid(casted_card.card_is_in_card_slot):
				casted_card.card_is_in_card_slot.card_in_slot = false
			
			player_spell_on_slot.erase(casted_card)
			casted_card.queue_free()
			return
		elif draw != 0:
			if draw == 2:
				for i in draw:
					$"../Deck".reset_draw()
					$"../Deck".draw_card()
			
			elif draw == 3:
				discard_random_player_card()
				
				if $"../Deck".player_deck.size() != 0:
					$"../Deck".reset_draw()
					$"../Deck".draw_card()
			
			elif draw == 1:
				var exchange = 0
				for i in 3:
					if player_hand.size() != 0:
						discard_random_player_card()
						exchange += 1
				
				for d in exchange:
					if $"../Deck".player_deck.size() != 0:
						$"../Deck".reset_draw()
						$"../Deck".draw_card()
		
			
		# --- Catch-all for non-damage/non-heal cards (e.g., buffs/defends) ---
		# This 'elif' ensures a wait happens if the card had no damage/heal effect
		elif dmg == 0 and healing == 0:
			await wait(0.5) # Wait briefly to show cast
			
		
		# --- APPLY MANA DEDUCTION ONCE AFTER ALL EFFECTS ARE CALCULATED ---
		player_mana = max(0, player_mana - mana_cost)
		$"../Player_Mana".text = str(player_mana)
		
		# --- CLEANUP (This section runs for ALL cards cast by the player) ---
		
		casted_card.get_node("cardfade").play("card_fade")
		await wait(0.5)
		
		if is_instance_valid(casted_card.card_is_in_card_slot):
			casted_card.card_is_in_card_slot.card_in_slot = false
		
		if player_block == 0:
			$"../Player_Block".visible = false
		
		player_spell_on_slot.erase(casted_card)
		casted_card.queue_free()

# ---------------------------------------------------------
# OPPONENT PLAYS CARD
# ---------------------------------------------------------
func try_play_opponent_card():
	if opponent_hand.size() == 0:
		return
	
	var affordable_cards = []
	for c in opponent_hand:
		if c.ManaCost <= opponent_mana:
			affordable_cards.append(c)
	
	if affordable_cards.size() == 0:
		return # No cards can be played, opponent skips
	
	# Choose the card with the highest priority based on game state
	var best_card = affordable_cards[0]
	
	# Priority 1: Draw cards if hand is small
	if opponent_hand.size() < 4:
		# FIX: Corrected property access to match case used elsewhere (e.g., InstantHeal, InstantDamage)
		# Assuming the property is 'Draw'
		for c in affordable_cards:
			if c.Draw > best_card.Draw:
				best_card = c
	
	# Priority 2: Heal if health is low
	elif opponent_health < 70:
		# FIX: Corrected typo 'IntstantHeal' -> 'InstantHeal'
		for c in affordable_cards:
			if c.InstantHeal > best_card.InstantHeal:
				best_card = c
	
	# Priority 3: Mana drain if player has high mana
	elif player_mana > 4:
		for c in affordable_cards:
			if c.Mana_Drain > best_card.Mana_Drain:
				best_card = c
	
	# Priority 4: Default to high damage
	else:
		for c in affordable_cards:
			if c.InstantDamage > best_card.InstantDamage:
				best_card = c
	
	var slot = empty_opponent_card_slot[0]
	
	# Move hand → slot
	var tween = get_tree().create_tween()
	tween.tween_property(best_card, "position", slot.position, CARD_MOVE_SPEED)
	
	best_card.get_node("cardflip").play("card_flip")
	
	$"../OpponentHand".remove_card_from_hand(best_card)
	best_card.card_is_in_card_slot = slot
	opponent_spell_on_slot.append(best_card)
	
	# Deduct mana
	opponent_mana -= best_card.ManaCost
	$"../Opponent_Mana".text = str(opponent_mana)
	
	await wait(0.2)

func discard_random_opponent_card():
	 # Nothing to discard
	if opponent_hand.size() == 0:
		return null
	
	# Pick random index
	var idx = randi_range(0, opponent_hand.size() - 1)
	var card = opponent_hand[idx]
	
	# Remove card from hand array
	opponent_hand.erase(card)
	
	# Free the card in scene
	if is_instance_valid(card):
		card.queue_free()


func wait(wait_time):
	Battle_Timer.wait_time = wait_time
	Battle_Timer.start()
	await Battle_Timer.timeout

func discard_random_player_card():
	if player_hand.size() == 0:
		return null
	
	# Pick random index
	var idx = randi_range(0, player_hand.size() - 1)
	var card = player_hand[idx]
	
	# Remove card from hand array
	player_hand.erase(card)
	
	# Free the card in the scene
	if is_instance_valid(card):
		card.queue_free()


func end_opponent_turn():
	if player_block > 0:
		if blocked == false:
			player_block -= 1
			$"../Player_Block".text = str(player_block)
			if player_block == 0:
				$"../Player_Block".visible = false
		else:
			blocked = false
	
	if drained == false:
		player_mana += MANA_PER_TURN + funds
		player_mana = min(player_mana, MAX_MANA)
	else:
		drained = false
	
	funds = 0
	
	# Update the UI
	$"../Player_Mana".text = str(player_mana)
	$"../Deck".reset_draw()
	$"../CastButton".disabled = false
	$"../CastButton".visible = true
