extends PanelContainer

@onready var hand_label = $Container/CardsHand
@export var hand := 4:
	set(value):
		hand_label.text = "Cards Per Hand: " + str(value)

@onready var play_label = $Container/CardsPlay
@export var play := 1:
	set(value):
		play_label.text = "Cards Played: " + str(value)

@onready var time_label = $Container/TimePlay
@export var time := 1:
	set(value):
		time_label.text = "Time Played: " + str(value) + "s"

@onready var success_label = $Container/Success
@export var success := false:
	set(value):
		success_label.text = "Successful Game: " + ("Yes" if value else "No")
