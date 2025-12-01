extends Node2D

var rng = RandomNumberGenerator.new()

func _ready():
	var base_card = $Card
	for i in range(1, 53):
		var card = base_card.duplicate()
		card.set_meta("card_id", i)
		card.position = Vector2(rng.randf_range(0.0, get_viewport_rect().size.x), rng.randf_range(0.0, get_viewport_rect().size.y))
		card.set_meta("flip", true)
		add_child(card)
	
	base_card.queue_free()
