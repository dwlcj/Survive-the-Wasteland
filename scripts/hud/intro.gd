extends Label

var tween

func _ready():
	tween = get_node("tween")
	modulate = Color(1, 1, 1, 0)
	yield(get_tree().create_timer(5), "timeout")
	tween.interpolate_property(self, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(get_tree().create_timer(5), "timeout")
	tween.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
