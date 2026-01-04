extends CenterContainer

var peer
var online_id
var timeout_signal = false

var base_world = preload("res://scenes/world.tscn")
var base_player = preload("res://scenes/player_menu.tscn")
@onready var game = get_tree().get_root().get_node("Game")
@onready var toast = %Toast
@onready var back = %Back
@onready var timer = $Timer

@onready var main = $Main
@onready var main_host = $Main/Host
@onready var main_join = $Main/Join

@onready var joining = $Joining
@onready var joining_code = $Joining/Code

@onready var lobby = $Lobby
@onready var lobby_cards = $Lobby/Cards
@onready var lobby_players = $Lobby/Players/Container
@onready var lobby_code = $Lobby/Container/Code
@onready var lobby_copy = $Lobby/Container/Copy
@onready var lobby_start = $Lobby/Buttons/Container/Start

# Setup

func timeout_helper():
	print("shown")
	timeout_signal = true

func await_timeout(await_signal, time):
	timeout_signal = false
	
	await_signal.connect(timeout_helper)
	timer.start()
	for i in range(time/0.05):
		if timeout_signal:
			timer.stop()
			await_signal.disconnect(timeout_helper)
			return true
		await timer.timeout
	timer.stop()
	await_signal.disconnect(timeout_helper)
	return false

func update_players():
	var players = game.get_meta("players")
	var lobby_ids = []
	
	for player in lobby_players.get_children():
		var player_id = player.get_meta("id")
		if not players.has(player_id):
			player.queue_free()
		else:
			lobby_ids.append(player_id)
	
	for id in players:
		if not lobby_ids.has(id):
			var player = base_player.instantiate()
			player.set_meta("id", id)
			lobby_players.add_child(player, true)

func _ready():
	peer = NodeTunnelPeer.new()
	multiplayer.multiplayer_peer = peer
	
	peer.connect_to_relay("relay.nodetunnel.io", 9998)
	
	peer.relay_connected.connect(_relay_connected)
	
	peer.peer_connected.connect(_peer_connected)
	
	peer.peer_disconnected.connect(_peer_disconnected)
	
	peer.room_left.connect(_room_left)


func _relay_connected(new_online_id):
	online_id = new_online_id

func _peer_connected(id):
	toast.new("Player " + str(id) + " joined", 0)
	if is_multiplayer_authority():
		var players = game.get_meta("players")
		players.append(id)
		update_players()
		cards_change(0)

func _peer_disconnected(id):
	if id != get_multiplayer_authority():
		toast.new("Player " + str(id) + " left", 0)
	else:
		toast.new("Lobby closed", 2)
	
	if is_multiplayer_authority():
		var players = game.get_meta("players")
		players.erase(id)
		update_players()
	elif id == get_multiplayer_authority() and id != game.get_meta("id"):
		_lobby_leave_pressed()

func _room_left():
	game.set_meta("id", 0)
	game.set_meta("players", [])
	game.set_meta("lobby_id", "")
	main.show()
	toast.new("Lobby left", 0)

# Main

func _main_host_pressed():
	if game.get_meta("can_host"):
		game.set_meta("lobby_id", online_id)
		lobby_code.text = "Lobby ID: " + online_id
		lobby_copy.show()
		
		game.set_meta("players", [1])
		
		peer.host()
		await peer.hosting
		
		main.hide()
		lobby.show()
		lobby_cards.show()
		lobby_start.show()
		toast.new("Lobby created", 1)
		
		update_players()
	else:
		toast.new("Your build cannot host", 0)

func _main_join_pressed():
	main.hide()
	joining.show()
	back.show()

# Joining

func _back_pressed():
	joining.hide()
	back.hide()
	main.show()

func _joining_join_pressed():
	if joining_code.text.length() <= 0:
		toast.new("Lobby ID is too short", 2)
	else:
		peer.join(joining_code.text)
		
		if await await_timeout(peer.joined, 6.0):
			game.set_meta("id", multiplayer.get_unique_id())
			toast.new("Connected", 1)
			joining.hide()
			back.hide()
			lobby.show()
			lobby_start.hide()
		else:
			toast.new("Connection timeout", 2)

func cards_change(amt):
	game.set_meta("cards_amount", clamp(game.get_meta("cards_amount") + amt, 1, int(floor(52.0/float(clamp(game.get_meta("players").size(), 2, 6) + 3)))))
	lobby_cards.get_node("Amount").text = str(game.get_meta("cards_amount"))

func _lobby_cards_add():
	cards_change(1)

func _lobby_cards_subtract():
	cards_change(-1)

# Lobby

func _lobby_copy_pressed():
	DisplayServer.clipboard_set(game.get_meta("lobby_id"))

func _lobby_leave_pressed():
	peer.leave_room()
	await peer.room_left
	
	lobby.hide()
	main.show()

func _lobby_start_pressed():
	if is_multiplayer_authority():
		var players = game.get_meta("players").size()
		if players >= 2 and players <= 6:
			hide()
			var world = base_world.instantiate()
			game.add_child(world, true)
			toast.new("Game started", 1)
		else:
			toast.new("You need 2-6 players", 2)
