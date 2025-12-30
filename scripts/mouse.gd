extends Node

var rng = RandomNumberGenerator.new()

@onready var cards = $Cards
@onready var nodes = $Nodes
@onready var camera = $Camera
var hover_card = null
var drag = false

var base_card = preload("res://scenes/card.tscn")
@onready var viewport = get_viewport()
@onready var screen = viewport.get_visible_rect()

func hand_repos(player):
	var player_cards = player.get_meta("cards")
	for i in player_cards.size():
		var icard = player_cards[i]
		icard.set_meta("target", Vector2((screen.size.x - ((player_cards.size() - 1) * 115))/2 + (i * 115), screen.size.y - 150))

func new_card(card_id, player):
	var card = base_card.instantiate()
	card.set_meta("card_id", card_id)
	card.set_meta("interactable", true)
	card.position = cards.position
	#card.position = screen.size - (card.get_rect().size * card.scale)/2 - Vector2(40.0 - (i/10), 40.0 - (i/10))
	#card.set_meta("rotation", rng.randf_range(-0.02, 0.02))
	cards.add_child(card)
	var player_cards = player.get_meta("cards")
	player_cards.append(card)
	
	card.set_meta("flip", false)
	hand_repos(player)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed() and hover_card:
				drag = hover_card.position - get_viewport().get_mouse_position()
				hover_card.set_meta("drag", true)
			elif event.is_released() and drag:
				hover_card.set_meta("drag", false)
				drag = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed() and hover_card:
				hover_card.set_meta("flip", not hover_card.get_meta("flip"))
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.is_pressed():
				new_card(rng.randi_range(1, 52), get_tree().get_root().get_node("World").get_node("Players").get_node("Player"))
			#if event.is_pressed() and hover_card:
				#hover_card.set_meta("float", not hover_card.get_meta("float"))

func _process(_delta):
	var mouse = viewport.get_mouse_position()
	
	mouse = mouse.clamp(screen.position, screen.end) + camera.position
	
	if drag:
		hover_card.set_meta("position", mouse + drag)
		
		for node in nodes.get_children():
			if node.get_node("Collision").get_shape().get_rect().has_point(node.to_local(mouse)):
				hover_card.set_meta("target", node)
		
	else:
		var card_nodes = get_tree().get_nodes_in_group("Cards")
		hover_card = null
		for card in card_nodes:
			if card.get_meta("interactable") and card.get_rect().has_point(card.to_local(mouse)):
				hover_card = card
		
		for card in card_nodes:
			card.set_meta("hover", card == hover_card)
