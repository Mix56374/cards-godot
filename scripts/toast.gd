extends PanelContainer

@onready var label = $Label
@onready var timer = $Timer

func new(text, type):
	label.text = text
	var color = Color.WHITE
	match type:
		1:
			color = Color.LIGHT_GREEN
		2:
			color = Color.LIGHT_CORAL
	label.add_theme_color_override("font_color", color)
	
	show()
	timer.start()
	await timer.timeout
	hide()
	
	label.text = ""
