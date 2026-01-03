extends CenterContainer

var peer
var online_id
var timeout_signal = false

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

@onready var hosting = $Hosting
@onready var hosting_players = $Hosting/Players/Amount
@onready var hosting_cards = $Hosting/Cards/Amount

@onready var lobby = $Lobby
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

func _peer_disconnected(id):
	if id != get_multiplayer_authority():
		toast.new("Player " + str(id) + " left", 0)
	
	if is_multiplayer_authority():
		var players = game.get_meta("players")
		players.erase(id)
		update_players()
	elif id == get_multiplayer_authority():
		print("server")
		_lobby_leave_pressed()

func _room_left():
	print("left")

# Main

func _main_host_pressed():
	main.hide()
	hosting.show()
	back.show()

func _main_join_pressed():
	main.hide()
	joining.show()
	back.show()

# Joining

func _back_pressed():
	joining.hide()
	hosting.hide()
	back.hide()
	main.show()

func _joining_join_pressed():
	if joining_code.text.length() <= 0:
		toast.new("Lobby ID is too short", 2)
	else:
		peer.join(joining_code.text)
		
		if await await_timeout(peer.joined, 6.0):
			toast.new("Connected", 1)
			joining.hide()
			back.hide()
			lobby.show()
			lobby_start.hide()
		else:
			toast.new("Connection timeout", 2)

# Hosting

func _hosting_host_pressed():
	game.set_meta("lobby_id", online_id)
	lobby_code.text = "Lobby ID: " + online_id
	lobby_copy.show()
	
	game.set_meta("players", [1])
	
	peer.host()
	await peer.hosting
	
	hosting.hide()
	back.hide()
	lobby.show()
	lobby_start.show()
	
	update_players()

func players_change(amt):
	game.set_meta("players_amount", clamp(game.get_meta("players_amount") + amt, 2, 6))
	cards_change(0)
	hosting_players.text = str(game.get_meta("players_amount"))

func cards_change(amt):
	game.set_meta("cards_amount", clamp(game.get_meta("cards_amount") + amt, 1, int(floor(52.0/float(game.get_meta("players_amount"))))))
	hosting_cards.text = str(game.get_meta("cards_amount"))

func _hosting_players_add():
	players_change(1)

func _hosting_players_subtract():
	players_change(-1)

func _hosting_cards_add():
	cards_change(1)

func _hosting_cards_subtract():
	cards_change(-1)

# Lobby

func _lobby_copy_pressed():
	DisplayServer.clipboard_set(game.get_meta("lobby_id"))

func _lobby_leave_pressed():
	peer.leave_room()
	await peer.room_left
	game.set_meta("players", [])
	game.set_meta("lobby_id", "")
	toast.new("Lobby left", 0)
	
	lobby.hide()
	main.show()

func _lobby_start_pressed():
	pass
