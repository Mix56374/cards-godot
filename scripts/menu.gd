extends CenterContainer

var peer
var online_id
var timeout_signal = false

var base_world = preload("res://scenes/world.tscn")
var base_player = preload("res://scenes/player_menu.tscn")
@onready var game = get_tree().get_root().get_node("Game")
@onready var toast = %Toast
@onready var build = %Build
@onready var username = %Username
@onready var data = %Data
@onready var timer = $Timer

@onready var main = $Main
@onready var main_host = $Main/Host
@onready var main_join = $Main/Join

@onready var joining = $Joining
@onready var joining_code = $Joining/Code
@onready var joining_join = $Joining/Buttons/Join

@onready var lobby = $Lobby
@onready var lobby_cards = $Lobby/Cards
@onready var lobby_players = $Lobby/Players/Container
@onready var lobby_code = $Lobby/Container/Code
@onready var lobby_copy = $Lobby/Container/Copy
@onready var lobby_start = $Lobby/Buttons/Container/Start

# Setup

func timeout_helper():
	timeout_signal = true

func await_timeout(await_signal, time):
	timeout_signal = false
	
	if await_signal.is_connected(timeout_helper):
		await_signal.disconnect(timeout_helper)
	await_signal.connect(timeout_helper, CONNECT_ONE_SHOT)
	timer.start()
	for i in range(time/0.05):
		if timeout_signal:
			timer.stop()
			return true
		await timer.timeout
	timer.stop()
	return false

func find_player(id):
	for player in lobby_players.get_children():
		if player.get_meta("id") == id:
			return player
	return null

func _ready():
	build.text += "a" if game.get_meta("can_host") else "b"
	
	peer = NodeTunnelPeer.new()
	multiplayer.multiplayer_peer = peer
	multiplayer.server_relay = true
	
	peer.connect_to_relay("relay.nodetunnel.io", 9998)
	
	peer.relay_connected.connect(_relay_connected)
	
	peer.peer_connected.connect(_peer_connected)
	
	peer.peer_disconnected.connect(_peer_disconnected)
	
	peer.room_left.connect(_room_left)


func _relay_connected(id):
	online_id = id

func _peer_connected(id):
	if is_multiplayer_authority():
		var players = game.get_meta("players")
		players.append(id)
		
		var player = base_player.instantiate()
		player.set_meta("id", id)
		player.get_node("Label").text = "Player " + str(id)
		lobby_players.add_child(player, true)
		
		cards_change(0)
	else:
		toast.new("New player joined", 0)

func _peer_disconnected(id):
	if id != get_multiplayer_authority():
		toast.new("Player " + str(id) + " left", 0)
	else:
		toast.new("Lobby closed", 2)
	
	if is_multiplayer_authority():
		var players = game.get_meta("players")
		players.erase(id)
		var player = find_player(id)
		if player:
			player.queue_free()
		
	elif id == get_multiplayer_authority() and id != game.get_meta("id"):
		_lobby_leave_pressed()

func _room_left():
	game.set_meta("id", 0)
	username.text = ""
	game.set_meta("players", [])
	game.set_meta("lobby_id", "")
	main.show()
	toast.new("Lobby left", 0)

# Main

func _main_host_pressed():
	if game.get_meta("can_host"):
		main_host.disabled = true
		peer.host()
		await peer.hosting
		
		var id = multiplayer.get_unique_id()
		
		game.set_meta("lobby_id", online_id)
		game.set_meta("id", id)
		username.text = "Player " + str(id)
		lobby_code.text = "Lobby ID: " + online_id
		lobby_copy.show()
		
		game.set_meta("players", [id])
		
		main.hide()
		lobby.show()
		lobby_cards.show()
		lobby_start.show()
		main_host.disabled = false
		toast.new("Lobby created", 1)
		
		var player = base_player.instantiate()
		player.set_meta("id", id)
		player.get_node("Label").text = "Player " + str(id)
		lobby_players.add_child(player, true)
	else:
		toast.new("Your build cannot host", 0)

func _main_join_pressed():
	main.hide()
	joining.show()

# Joining

func _joined_back_pressed():
	joining.hide()
	main.show()

func _joining_join_pressed():
	if joining_code.text.length() <= 0:
		toast.new("Lobby ID is too short", 2)
	else:
		peer.join(joining_code.text)
		
		if await await_timeout(peer.joined, 6.0):
			var id = multiplayer.get_unique_id()
			game.set_meta("id", id)
			username.text = "Player " + str(id)
			toast.new("Connected", 1)
			
			joining.hide()
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
	
	if is_multiplayer_authority():
		for player in lobby_players.get_children():
			player.queue_free()
	
	lobby.hide()
	main.show()

func _lobby_start_pressed():
	if is_multiplayer_authority():
		var players = game.get_meta("players").size()
		if players >= 2 and players <= 6:
			hide()
			data.hide()
			var world = base_world.instantiate()
			game.add_child(world, true)
			toast.new("Game started", 1)
		else:
			toast.new("You need 2-6 players", 2)
