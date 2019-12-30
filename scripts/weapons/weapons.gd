extends Spatial

var mouse_relative_x = 0.0
var mouse_relative_y = 0.0
const EASING = 10

func _ready():
	pass

func _process(delta):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_degrees.x += ((mouse_relative_y / 5) - rotation_degrees.x) * EASING * delta
		rotation_degrees.y += ((mouse_relative_x / 5) - rotation_degrees.y) * EASING * delta
		mouse_relative_x = 0
		mouse_relative_y = 0
		pass

func _input(event):
	if event is InputEventMouseMotion:
		mouse_relative_x = event.relative.x
		mouse_relative_y = event.relative.y
