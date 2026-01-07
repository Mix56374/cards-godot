extends PanelContainer

@export var player_id = 1
@onready var mult_sync = $MultiplayerSynchronizer

func _setup():
	#print(get_tree().get_root().get_node("Game").get_meta("id"), " | ", name)
	mult_sync.set_multiplayer_authority(player_id)

func _process(_delta):
	if player_id != mult_sync.get_multiplayer_authority():
		_setup()
