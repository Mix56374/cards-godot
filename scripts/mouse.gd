extends Node

@onready var cards = $Cards
@onready var nodes = $Nodes
@onready var camera = $Camera
var hover_card = null
var drag = false

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed() and hover_card:
				drag = hover_card.position - get_viewport().get_mouse_position()
				hover_card.set_meta("drag", true)
			elif event.is_released() and drag:
				hover_card.set_meta("drag", false)
				drag = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed() and hover_card:
				hover_card.set_meta("flip", not hover_card.get_meta("flip"))

func _process(_delta):
	var viewport = get_viewport()
	var mouse = viewport.get_mouse_position()
	var screen = viewport.get_visible_rect()
	
	mouse = mouse.clamp(screen.position, screen.end) + camera.position
	
	if drag:
		hover_card.set_meta("position", mouse + drag)
		
		for node in nodes.get_children():
			if node.get_node("Collision").get_shape().get_rect().has_point(node.to_local(mouse)):
				hover_card.set_meta("target", node)
		
	else:
		hover_card = null
		for card in cards.get_children():
			if card.get_meta("interactable") and card.get_rect().has_point(card.to_local(mouse)):
				hover_card = card
		
		for card in cards.get_children():
			card.set_meta("hover", card == hover_card)
