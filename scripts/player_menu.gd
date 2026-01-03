extends PanelContainer

func _ready():
	if is_multiplayer_authority():
		$Label.text = "Player " + str(get_meta("id"))
