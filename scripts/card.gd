extends Sprite2D

var time = Time
var rng = RandomNumberGenerator.new()

var ftexture = texture
var btexture = preload('res://cards/card_back.png')
var size = scale.y
var zrot = 0.0
var drag = 0.0
var rot = 0.0
var rng_offset = rng.randf_range(5.0, 8.0)
var rng_sign = (2 * randi_range(0, 1)) - 1

func _enter_tree():
	set_meta("scale", scale.y)
	var card_id = get_meta("card_id")
	ftexture = load("res://cards/card_"+str(1+(card_id/14))+"_"+str(1+((card_id-1)%13))+".png")
	set_deferred("texture", ftexture)
	
	var target = get_meta("target")
	if target:
		position = target
	else:
		position = get_meta("position")
	
	zrot = float(get_meta("flip")) * 2.0
	if zrot > 1.0:
		texture = btexture
	else:
		texture = ftexture
	
	rot = get_meta("rotation")
	

func _process(delta):
	var target = get_meta("target")
	var lsize = get_meta("scale") + ((float(get_meta("hover")) + float(get_meta("drag"))) * 0.01)
	var lzrot = float(get_meta("flip")) * 2.0
	var ldrag = float(get_meta("drag"))
	var ltime = time.get_ticks_msec()/1000.0
	
	var lpos
	if target:
		lpos = lerp(target.position, get_meta("position"), ease(drag, 0.3)) - position
	else:
		lpos = get_meta("position") - position
	var lrot = get_meta("rotation")
	
	lpos = Vector2(cos(lpos.angle()), sin(lpos.angle())) * min(lpos.length(), 200.0)
	
	if get_meta("card_id") == 52:
		print(sin((PI * ltime)/rng_offset) * 0.03)
	
	rot = lerp(rot, lrot, delta * 5.0)
	drag = lerp(drag, ldrag, delta * 10.0)
	rotation = rot + (sin((PI * ltime)/rng_offset) * rng_sign * 0.04) + clamp(lpos.x/200.0, -0.85, 0.85)
	position = lerp(position, position + lpos, delta * (10.0 + (ease(drag, 0.1) * 15.0)))
	zrot = lerp(zrot, lzrot, delta * 10.0)
	size = lerp(size, lsize + ((cos(PI * (ltime/(rng_offset * 1.0) + 0.5)) + 1.0) * 0.005), delta * 15.0)
	scale = Vector2(size, size)
	scale.x = lerp(size, -size, zrot/2)
	# Fix the floating animation on lines 57 and 60 so it is integrated into the overall code better, and can smoothly be toggled on or off, and no I will NOT be fixing the magic numbers
	
	if zrot > 1.0:
		texture = btexture
	else:
		texture = ftexture
