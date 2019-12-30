extends RigidBody

var exploded = false
var time_to_explode = 0
var explosion_scn = preload("res://particles/impact/explosion.tscn")

func _ready():
	pass

func _physics_process(delta):
	time_to_explode += delta
	if !exploded and time_to_explode >= 3:
		var explosion = explosion_scn.instance()
		game.main_scene.add_child(explosion)
		explosion.global_transform.origin = global_transform.origin
		var bodies = $area.get_overlapping_bodies()
		for b in bodies:
			if b is KinematicBody:
				if b.has_method("hit"):
					b.hit(100, self)
					yield(get_tree().create_timer(0.05), "timeout")
					b.vel = (b.global_transform.origin - global_transform.origin).normalized() * 1000
		exploded = true
		visible = false
		queue_free()
