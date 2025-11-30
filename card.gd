extends Sprite2D

var lscale = scale
var dtexture = texture
var btexture = load('res://cards/card_back.png')
var zrot = 0.0
var drag = 0.0
var rot = 0.0

func _ready():
	set_meta("scale", scale)
	set_meta("position", position)
	set_meta("rotation", rotation)

func _process(delta):
	var target = get_meta("target")
	var size = (int(get_meta("hover")) + int(get_meta("drag"))) * 0.01
	var lzrot = float(get_meta("flip")) * 2.0
	var ldrag = float(get_meta("drag"))
	var lpos
	if target and not ldrag:
		lpos = target.position - position
	else:
		lpos = get_meta("position") - position
	var lrot = get_meta("rotation")
	
	lscale = (get_meta("scale") + Vector2(size, size))
	lscale.x = lscale.x - (lscale.x * lzrot)
	lpos = Vector2(cos(lpos.angle()), sin(lpos.angle())) * min(lpos.length(), 150.0 + (drag * 100.0))
	zrot = lerp(zrot, lzrot, delta * 10.0)
	
	if zrot > 1.0:
		texture = btexture
	else:
		texture = dtexture
	
	rot = lerp(rot, lrot, delta * 5.0)
	drag = lerp(drag, ldrag, delta * 5.0)
	rotation = rot + clamp(lpos.x/200.0, -0.85, 0.85)
	position = lerp(position, position + lpos, delta * (10.0 + (drag * 10.0)))
	scale = lerp(scale, lscale, delta * 10.0)
