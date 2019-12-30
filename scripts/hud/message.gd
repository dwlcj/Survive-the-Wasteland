extends Label

var message setget set_message
signal message_changed

func set_message(message):
	emit_signal("message_changed")
	visible = true
	modulate = Color(1, 1, 1, 1)
	text = message
	#get_node("tween").interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	yield(get_tree().create_timer(1), "timeout")
	visible = false
