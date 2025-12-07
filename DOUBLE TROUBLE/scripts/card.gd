extends Node2D

signal hovered
signal hovered_off

var starting_hand_position
var card_is_in_card_slot
var InstantDamage = 0
var InstantHeal = 0
var Mana_Drain = 0
var Shield = 0
var ManaCost = 0
var Draw = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#All cards must be child of card manager
	get_parent().connect_card_signals(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
