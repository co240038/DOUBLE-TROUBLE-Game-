extends Node2D

const CARD_SCENE_PATH = "res://Scenes/card.tscn"
const DRAW_SPEED = .4
const STARTING_HAND_SIZE = 4

var player_set_deck = ["Attack", "Iron_Fortress", "Mana_Drain", "Heal", "Defend", "Lightning", "Greed_Pot", "Emergency_Funds", "Draw_of_Destiny", "Gamble", "Determination", "Arrow_Barrage"] #acts as the cards selected by player for battle
var player_deck = [] #deck used in game
var card_database_reference
var drawn_card__this_turn = false



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#doubles the amount of cards in player_set_deck which will act as the deck made by player in game
	for card in player_set_deck:
		player_deck.append(card)
		player_deck.append(card)
	
	player_deck.shuffle()
	$RichTextLabel.text = str(player_deck.size())
	card_database_reference = preload("res://scripts/CardDatabase.gd") #takes all data of cards in carddatabase script
	
	for i in range(STARTING_HAND_SIZE):
		draw_card()
		drawn_card__this_turn = false




# Called every frame. 'delta' is the elapsed time since the previous frame.
func draw_card():
	if drawn_card__this_turn:
		return
	
	if player_deck.size() == 0:
		return
	
	drawn_card__this_turn = true
	
	var card_drawn_name = player_deck[0] #the card on top of deck
	player_deck.erase(card_drawn_name)
	
	$RichTextLabel.text = str(player_deck.size()) #text of number of cards in deck
	var card_scene = preload(CARD_SCENE_PATH) #takes cards scene
	var new_card = card_scene.instantiate() #makes a card
	var card_image_path = str("res://Cards/" + card_drawn_name + ".png") #takes name of card in deck
	new_card.get_node("CardIMG").texture = load(card_image_path) #changes img depending of name matching with card
	
	# --- START OF FIX (Step 2 Implementation) ---
	
	# Retrieve the card data from the database
	var card_data = card_database_reference.CARDS[card_drawn_name]
	
	# 1. ASSIGN INSTANT DAMAGE and MANA COST TO THE CARD OBJECT
	# We are assuming the structure of your CardDatabase.CARDS[card_drawn_name] is an array.
	# Based on the stat_map below, InstantDamage is at index 0, and ManaCost is at index 2.
	
	new_card.InstantDamage = card_data[0] # Assign Damage from index 0
	new_card.InstantHeal = card_data[1]
	new_card.Mana_Drain = card_data[2]
	new_card.Shield = card_data[3]
	new_card.Draw = card_data[4] 
	new_card.ManaCost = card_data[5]      # Assign Mana Cost from index 2
	
	# NOTE: If your CardDatabase stores values by name (e.g., card_data.instant_damage), 
	# you must use that name instead of the index (e.g., card_data["InstantDamage"]).
	
	# --- END OF FIX ---

	#Shows card stats /still needs improvement and effieciency/
	var stat_map = {
	0: "LabelContainer/InstantDamage",
	1: "LabelContainer/InstantHeal",
	5: "LabelContainer/ManaCost"}
	
	# CRITICAL CHECK: This loop must ensure the values are non-zero!
	for index in stat_map.keys():
		var value = card_data[index] # Use card_data variable
		var label = new_card.get_node(stat_map[index])
		label.text = str(value)
		label.visible = value != 0
	
	new_card.global_position = global_position
	
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, DRAW_SPEED)
	new_card.get_node("cardflip").play("card_flip")

func reset_draw():
	drawn_card__this_turn = false
