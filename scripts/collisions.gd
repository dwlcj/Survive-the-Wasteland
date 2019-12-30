extends Node

var main : Node
var bodies : Array

func _ready():
	main = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	push_bodies(main)
	for b in bodies:
		var player = AudioStreamPlayer3D.new()
		player.name = "player"
		b.add_child(player)
		var sound = preload("res://sounds/collisions/concrete_1.wav")
		player.stream = sound
		
		b.contact_monitor = true
		b.contacts_reported = 1
		if b.physics_material_override:
			pass
		b.connect("body_entered", self, "_on_body_entered", [b])

func push_bodies(node):
	for n in node.get_children():
		if n is RigidBody:
			bodies.push_back(n)
		if n.get_child_count() > 0:
			push_bodies(n)

func _on_body_entered(body, b):
	var player = b.get_node("player")
	player.pitch_scale = rand_range(0.9, 1.1)
	if !player.playing:
		player.play()
	pass