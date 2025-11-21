extends Node3D

@onready var head = $Head
@onready var camera = $Head/Camera
@onready var raycast = $Head/Raycast

const sensitivity = 0.002

var player = {
	defaults = {
		rot = rotation
	}
}

#func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#func _input(event):
	#if event is InputEventKey:
		#if event.keycode == KEY_ESCAPE:
			#get_tree().quit()

func _physics_process(_delta):
	var viewport = get_viewport()
	var mouse = viewport.get_mouse_position()
	var screen = viewport.get_visible_rect()
	
	mouse = mouse.clamp(screen.position, screen.end)
	
	camera.rotation.y = deg_to_rad(-7 * sin((PI * (mouse.x-(screen.end.x/2))/2)/(screen.end.x/2)))
	camera.rotation.x = deg_to_rad(-7 * sin((PI * (mouse.y-(screen.end.y/2))/2)/(screen.end.y/2)))
	camera.rotation += player.defaults.rot
	print(camera.rotation)
	
	
	#move_and_slide()
