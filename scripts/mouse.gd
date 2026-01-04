extends Node

var rng = RandomNumberGenerator.new()

@onready var game = get_tree().get_root().get_node("Game")
@onready var players = $Players
var local_player

@onready var timer = $Timer
@onready var deck = $Deck
@onready var pile = $Pile
@onready var camera = $Camera
var hover_card = null
var drag = false

var base_player = preload("res://scenes/player.tscn")
var base_card = preload("res://scenes/card.tscn")
var outline_shader = preload("res://shaders/outline.gdshader")
@onready var viewport = get_viewport()
@onready var screen = viewport.get_visible_rect()

func sort_cards(a, b):
	return a.get_meta("card_id") < b.get_meta("card_id")

func hand_repos(player):
	var player_cards = player.get_meta("cards")
	var rot = player.get_meta("rotation")
	var scale = player.get_meta("scale")
	for i in player_cards.size():
		var icard = player_cards[i]
		var x = (i * scale * 480.0) - ((player_cards.size() - 1) * scale * 480.0)/2.0
		icard.set_meta("target", player.position + Vector2(-(-x * cos(rot)) + (-150.0 * sin(rot)), (-x * sin(rot)) + (-150.0 * cos(rot))))
		icard.set_meta("rotation", -rot)

func new_card(card_id, player):
	var card = base_card.instantiate()
	card.set_meta("card_id", card_id)
	card.position = deck.position
	deck.add_child(card, true)
	var player_cards = player.get_meta("cards")
	player_cards.append(card)
	player_cards.sort_custom(sort_cards)
	
	if player == local_player:
		card.set_meta("flip", false)
	else:
		card.set_meta("scale", 0.15)
	card.set_meta("float", true)
	
	hand_repos(player)

func play_card(card, player):
	card.remove_from_group("Idle")
	for idle_card in get_tree().get_nodes_in_group("Idle"):
		if idle_card.get_meta("card_id") <= card.get_meta("card_id"):
			var losing_cards = players.get_meta("losing_cards")
			losing_cards.append(idle_card)
			idle_card.set_meta("flip", false)
			idle_card.set_meta("losing", true)
	
	card.z_index = card.get_meta("card_id")
	card.set_meta("flip", false)
	card.set_meta("float", false)
	card.set_meta("selected", false)
	card.set_meta("scale", 0.25)
	card.set_meta("rotation", rng.randf_range(-0.15, 0.15))
	card.set_meta("target", pile.position)
	#card.reparent(pile)
	
	var player_cards = player.get_meta("cards")
	player_cards.erase(card)
	hand_repos(player)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed() and hover_card:
				hover_card.set_meta("selected", not hover_card.get_meta("selected"))
				
				var selected_cards = local_player.get_meta("selected_cards")
				if hover_card.get_meta("selected"):
					selected_cards.append(hover_card)
				elif selected_cards.has(hover_card):
					selected_cards.erase(hover_card)
		
		#elif event.button_index == MOUSE_BUTTON_RIGHT:
			#if event.is_pressed() and hover_card:
				#hover_card.set_meta("flip", not hover_card.get_meta("flip"))
		
		#elif event.button_index == MOUSE_BUTTON_MIDDLE:
			#if event.is_pressed():
				#new_card(rng.randi_range(1, 52), local_player)
			#if event.is_pressed() and hover_card:
				#hover_card.set_meta("float", not hover_card.get_meta("float"))
	
	elif event is InputEventKey:
		var player_cards = local_player.get_meta("cards")
		var selected_cards = local_player.get_meta("selected_cards")
		
		if event.is_action_pressed("play") and selected_cards.size() > 0:
			local_player.set_meta("selected_cards", [])
			selected_cards.sort_custom(sort_cards)
			
			for card in player_cards:
				card.set_meta("interactable", false)
			
			timer.start()
			for card in selected_cards:
				play_card(card, local_player)
				if players.get_meta("losing_cards"):
					break
				await timer.timeout
			timer.stop()
			
			if not players.get_meta("losing_cards"):
				for card in player_cards:
					card.set_meta("interactable", true)

func card_exists(card_id):
	for card in get_tree().get_nodes_in_group("Cards"):
		if card.get_meta("card_id") == card_id:
			return true
	return false

func _ready():
	if not is_multiplayer_authority():
		return
	
	var players_amt = game.get_meta("players").size()
	
	for i in range(players_amt):
		var player = base_player.instantiate()
		players.add_child(player, true)
		player.set_meta("id", game.get_meta("players")[i])
		player.set_meta("cards", player.get_meta("cards").duplicate())
		player.set_meta("selected_cards", player.get_meta("selected_cards").duplicate())
		var rot = i/(players_amt/TAU)
		
		if players_amt < 7 and (players_amt != 2 and players_amt != 5 and players_amt != 4):
			if PI/2 < rot and rot < PI:
				rot = (PI/2) * sin(rot - (PI/2)) + (PI/2)
			elif PI < rot and rot < (3 * PI)/2:
				rot = (PI/2) * sin(rot + (PI/2)) + (3 * PI)/2
		
		player.set_meta("rotation", -rot)
		player.set_meta("scale", 0.25 if (i == 0) else 0.15)
		rot += PI/2
		player.position = ((screen.size/2) * Vector2(cos(rot), sin(rot))) + Vector2(screen.size.x/2, screen.size.y/2)
	
	local_player = players.get_child(0)
	
	timer.start()
	for i in range(game.get_meta("cards_amount")):
		for player in players.get_children():
			var card_id = randi_range(1, 52)
			while card_exists(card_id):
				card_id = randi_range(1, 52)
			new_card(card_id, player)
			
			await timer.timeout
	timer.stop()
	
	for card in local_player.get_meta("cards"):
				card.set_meta("interactable", true)

func _process(_delta):
	var mouse = viewport.get_mouse_position()
	mouse = mouse.clamp(screen.position, screen.end) + camera.position
	
	#if drag:
		#hover_card.set_meta("position", mouse + drag)
		#
		#for node in nodes.get_children():
			#if node.get_node("Collision").get_shape().get_rect().has_point(node.to_local(mouse)):
				#hover_card.set_meta("target", node)
		#
	#else:
	if local_player:
		var card_nodes = local_player.get_meta("cards")
		hover_card = null
		for card in card_nodes:
			if card.get_meta("interactable") and card.get_rect().has_point(card.to_local(mouse)):
				hover_card = card
		
		for card in card_nodes:
			card.set_meta("hover", card == hover_card)
