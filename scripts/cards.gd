extends Node2D

var rng = RandomNumberGenerator.new()

func _ready():
	var base_card = preload("res://scenes/card.tscn")
	var screen_size = get_viewport_rect().size
	
	for i in range(1, 53):
		var card = base_card.instantiate()
		card.set_meta("card_id", i)
		card.set_meta("flip", true)
		card.set_meta("interactable", true)
		card.set_meta("position", screen_size - (card.get_rect().size * card.scale)/2 - Vector2(40.0 - (i/10), 40.0 - (i/10)))
		#card.set_meta("rotation", rng.randf_range(-0.02, 0.02))
		add_child(card)
	
