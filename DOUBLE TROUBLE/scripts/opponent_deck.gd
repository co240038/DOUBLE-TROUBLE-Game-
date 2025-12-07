extends Node2D

const CARD_SCENE_PATH = "res://Scenes/opponent_card.tscn"
const DRAW_SPEED = .4
const STARTING_HAND_SIZE = 4

var opponent_set_deck = ["Attack", "Iron_Fortress", "Mana_Drain", "Heal", "Defend", "Lightning", "Greed_Pot", "Emergency_Funds", "Draw_of_Destiny", "Gamble", "Determination", "Arrow_Barrage"] #acts as the cards selected by player for battle
var opponent_deck = [] #deck used in game
var card_database_reference



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#doubles the amount of cards in player_set_deck which will act as the deck made by player in game
	for card in opponent_set_deck:
		opponent_deck.append(card)
		opponent_deck.append(card)
	
	opponent_deck.shuffle()
	$Deck/RichTextLabel.text = str(opponent_deck.size())
	card_database_reference = preload("res://scripts/CardDatabase.gd") #takes all data of cards in carddatabase script
	
	for i in range(STARTING_HAND_SIZE):
		draw_card()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func draw_card():
	var card_drawn_name = opponent_deck[0] #the card on top of deck
	opponent_deck.erase(card_drawn_name)  #deletes the card on top when drawn
	
	$Deck/RichTextLabel.text = str(opponent_deck.size()) #text of number of cards in deck
	var card_scene = preload(CARD_SCENE_PATH) #takes cards scene
	var new_card = card_scene.instantiate() #makes a card
	var card_image_path = str("res://Cards/" + card_drawn_name + ".png") #takes name of card in deck
	new_card.get_node("CardIMG").texture = load(card_image_path) #changes img depending of name matching with card
	new_card.InstantDamage = card_database_reference.CARDS[card_drawn_name][0]
	new_card.InstantHeal = card_database_reference.CARDS[card_drawn_name][1]
	new_card.Mana_Drain = card_database_reference.CARDS[card_drawn_name][2]
	new_card.Shield = card_database_reference.CARDS[card_drawn_name][3]
	new_card.Draw = card_database_reference.CARDS[card_drawn_name][4]
	new_card.ManaCost = card_database_reference.CARDS[card_drawn_name][5]
	#Shows card stats /still needs improvement and effieciency/
	var stat_map = {
	0: "LabelContainer/InstantDamage",
	1: "LabelContainer/InstantHeal",
	5: "LabelContainer/ManaCost"}
	
	for index in stat_map.keys():
		var value = card_database_reference.CARDS[card_drawn_name][index]
		var label = new_card.get_node(stat_map[index])
		label.text = str(value)
		label.visible = value != 0
	
	new_card.global_position = global_position
	
	$"../CardManager".add_child(new_card) 
	new_card.name = "Card"
	$"../OpponentHand".add_card_to_hand(new_card, DRAW_SPEED)
