extends Sprite2D

var dtexture = texture
var btexture = load('res://cards/card_back.png')
var size = scale.y
var zrot = 0.0
var drag = 0.0
var rot = 0.0

func _ready():
	set_meta("scale", scale.y)
	set_meta("position", position)
	set_meta("rotation", rotation)
	if not dtexture:
		var card_id = get_meta("card_id")
		dtexture = load("res://cards/card_"+str(1+(card_id/14))+"_"+str(1+((card_id-1)%13))+".png")
		texture = dtexture

func _process(delta):
	var target = get_meta("target")
	var lsize = get_meta("scale") + ((float(get_meta("hover")) + float(get_meta("drag"))) * 0.01)
	var lzrot = float(get_meta("flip")) * 2.0
	var ldrag = float(get_meta("drag"))
	
	var lpos
	if target:
		lpos = lerp(target.position, get_meta("position"), ease(drag, 0.3)) - position
	else:
		lpos = get_meta("position") - position
	var lrot = get_meta("rotation")
	
	lpos = Vector2(cos(lpos.angle()), sin(lpos.angle())) * min(lpos.length(), 200.0)
	
	if zrot > 1.0:
		texture = btexture
	else:
		texture = dtexture
	
	rot = lerp(rot, lrot, delta * 5.0)
	drag = lerp(drag, ldrag, delta * 10.0)
	rotation = rot + clamp(lpos.x/200.0, -0.85, 0.85)
	position = lerp(position, position + lpos, delta * (10.0 + (ease(drag, 0.1) * 15.0)))
	zrot = lerp(zrot, lzrot, delta * 10.0)
	size = lerp(size, lsize, delta * 15.0)
	scale = Vector2(size, size)
	scale.x = lerp(size, -size, zrot/2)
