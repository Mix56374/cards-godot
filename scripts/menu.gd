extends CenterContainer

@onready var main = $Main
@onready var main_host = $Main/Host
@onready var main_join = $Main/Join

@onready var joining = $Joining

@onready var hosting = $Hosting

@onready var lobby = $Lobby


func _main_host_pressed():
	main.hide()
	hosting.show()

func _main_join_pressed():
	main.hide()
	joining.show()


func _joining_join_pressed():
	# check if lobby id is valid, wait to connect, change text in lobby menu, and THEN go to lobby menu
	joining.hide()
	lobby.show()
