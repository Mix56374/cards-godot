extends Node

var rng = RandomNumberGenerator.new()

@onready var game = get_tree().get_root().get_node("Game")
@onready var players = $Players
@onready var data = game.get_node("UI").get_node("Data")
var local_player
var start_time = 0
var cards_played = 0

@onready var end_label = $EndLabel
@onready var timer = $Timer
@onready var fast_timer = $FastTimer
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

@rpc("authority", "call_local", "reliable")
func new_card(card_id, id):
	var player = get_player(id)
	var card = base_card.instantiate()
	card.set_meta("card_id", card_id)
	card.position = deck.position
	deck.add_child(card, true)
	var player_cards = player.get_meta("cards")
	player_cards.append(card)
	player_cards.sort_custom(sort_cards)
	
	if id == game.get_meta("id"):
		card.set_meta("flip", false)
	else:
		card.set_meta("scale", 0.15)
	card.set_meta("float", true)
	
	hand_repos(player)

func get_card(card_id):
	for card in get_tree().get_nodes_in_group("Cards"):
		if card.get_meta("card_id") == card_id:
			return card
	return null

func get_player(id):
	for player in players.get_children():
		if player.get_meta("id") == id:
			return player
	return null

@rpc("any_peer", "call_local", "reliable")
func play_card(card_id, id):
	if is_multiplayer_authority():
		if cards_played <= 0:
			start_time = int(Time.get_unix_time_from_system())
		cards_played += 1
	
	var player = get_player(id)
	var card = get_card(card_id)
	card.remove_from_group("Idle")
	for idle_card in get_tree().get_nodes_in_group("Idle"):
		if idle_card.get_meta("card_id") <= card.get_meta("card_id"):
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

@rpc("any_peer", "call_local", "reliable")
func select_card(card_id, select):
	var card = get_card(card_id)
	card.set_meta("selected", select)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed() and hover_card:
				select_card.rpc(hover_card.get_meta("card_id"), not hover_card.get_meta("selected"))
				
				var selected_cards = local_player.get_meta("selected_cards")
				if hover_card.get_meta("selected"):
					selected_cards.append(hover_card)
				elif selected_cards.has(hover_card):
					selected_cards.erase(hover_card)
		
	elif event is InputEventKey and event.is_action_pressed("play"):
		play_selected_cards()

func play_selected_cards():
	var selected_cards = local_player.get_meta("selected_cards")
		
	if selected_cards.size() > 0:
		local_player.set_meta("selected_cards", [])
		selected_cards.sort_custom(sort_cards)
		
		interact_local_cards.rpc(false)
		
		timer.start()
		for card in selected_cards:
			play_card.rpc(card.get_meta("card_id"), local_player.get_meta("id"))
			if is_losing():
				break
			await timer.timeout
		timer.stop()
		
		if is_losing():
			end_game.rpc(false)
		else:
			if get_tree().get_node_count_in_group("Idle") > 0:
				interact_local_cards.rpc(true)
			else:
				end_game.rpc(true)

func is_losing():
	for card in get_tree().get_nodes_in_group("Idle"):
		if card.get_meta("losing"):
			return true
	return false

@rpc("any_peer", "call_local", "reliable")
func end_game(win):
	pass
	if is_multiplayer_authority():
		data.hand = game.get_meta("cards_amount")
		data.play = cards_played
		data.time = int(Time.get_unix_time_from_system()) - start_time
		data.success = win
	
	if win:
		end_label.text = "You All Win!"
		end_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	else:
		for card in get_tree().get_nodes_in_group("Idle"):
			card.set_meta("flip", false)
		end_label.text = "You All Lose"
		end_label.add_theme_color_override("font_color", Color.LIGHT_CORAL)
	end_label.show()
	
	timer.start()
	for i in range(7):
		await timer.timeout
	timer.stop()
	game.get_node("UI").get_node("Menu").show()
	if is_multiplayer_authority():
		data.show()
		queue_free()

func card_exists(card_id):
	for card in get_tree().get_nodes_in_group("Cards"):
		if card.get_meta("card_id") == card_id:
			return true
	return false

@rpc("authority", "call_local", "reliable")
func set_local():
	local_player = get_player(multiplayer.get_unique_id())

@rpc("authority", "call_local", "reliable")
func player_repos(amt):
	var passthrough = false
	fast_timer.start()
	for i in range(20):
		if players.get_child_count() > 0:
			passthrough = true
			break
		await fast_timer.timeout
	fast_timer.stop()
	
	if passthrough:
		for i in range(amt):
			var player = get_player(game.get_meta("players")[i])
			player.set_meta("cards", player.get_meta("cards").duplicate())
			player.set_meta("selected_cards", player.get_meta("selected_cards").duplicate())
			
			i = (amt + (i - game.get_meta("players").find(game.get_meta("id"))))%amt
			
			var rot = i/(amt/TAU)
			
			if amt < 7 and (amt != 2 and amt != 5 and amt != 4):
				if PI/2 < rot and rot < PI:
					rot = (PI/2) * sin(rot - (PI/2)) + (PI/2)
				elif PI < rot and rot < (3 * PI)/2:
					rot = (PI/2) * sin(rot + (PI/2)) + (3 * PI)/2
			
			player.set_meta("rotation", -rot)
			player.set_meta("scale", 0.25 if (i == 0) else 0.15)
			rot += PI/2
			player.position = ((screen.size/2) * Vector2(cos(rot), sin(rot))) + Vector2(screen.size.x/2, screen.size.y/2)

@rpc("any_peer", "call_local", "reliable")
func interact_local_cards(type):
	for card in local_player.get_meta("cards"):
		card.set_meta("interactable", type)

func _ready():
	if is_multiplayer_authority():
		fast_timer.start()
		await fast_timer.timeout
		fast_timer.stop()
		
		var players_amt = game.get_meta("players").size()
		
		for i in range(players_amt):
			var player = base_player.instantiate()
			players.add_child(player, true)
			var id = game.get_meta("players")[i]
			player.set_meta("id", id)
		
		fast_timer.start()
		await fast_timer.timeout
		fast_timer.stop()
		
		player_repos.rpc(players_amt)
		set_local.rpc()
		
		timer.start()
		for i in range(game.get_meta("cards_amount")):
			for player in players.get_children():
				var card_id = randi_range(1, 52)
				while card_exists(card_id):
					card_id = randi_range(1, 52)
				
				new_card.rpc(card_id, player.get_meta("id"))
				
				await timer.timeout
		timer.stop()
		
		interact_local_cards.rpc(true)

func _process(_delta):
	var mouse = viewport.get_mouse_position()
	mouse = mouse.clamp(screen.position, screen.end) + camera.position
	
	if local_player:
		var card_nodes = local_player.get_meta("cards")
		hover_card = null
		for card in card_nodes:
			if card.get_meta("interactable") and card.get_rect().has_point(card.to_local(mouse)):
				hover_card = card
		
		for card in card_nodes:
			card.set_meta("hover", card == hover_card)

func _play_cards_pressed():
	play_selected_cards()
