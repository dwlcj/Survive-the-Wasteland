extends Spatial
class_name Force

var player
var camera

var spatial
var joint
var target_bone

var hands

var audio
var force_start = preload("res://sounds/weapons/force/force_start.wav")
var force_loop = preload("res://sounds/weapons/force/force_loop.wav")
var force_end = preload("res://sounds/weapons/force/force_end.wav")
var force_shoot = preload("res://sounds/weapons/force/force_shoot.wav")

func _ready():
	player = find_parent("player")
	camera = player.get_node("head/camera")
	joint = get_node("joint")
	spatial = get_node("spatial")
	audio = get_node("audio")
	hands = get_node("hands")

func _physics_process(delta):
	if Input.is_action_pressed("mouse_secondary") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and !player.equipped_gun:
		var space_state = get_world().direct_space_state
		var screen_center = get_viewport().size / 2
		var from = camera.project_ray_origin(screen_center)
		var to = from + camera.project_ray_normal(screen_center)  * 15
		var result = space_state.intersect_ray(from, to, [self, get_node("spatial"), player])
		if result:
			if result.collider is BaseCharacter:
				var body = result.collider
				body.die()
				joint.global_transform.origin = result.position
				spatial.global_transform.origin = result.position
				target_bone = body.get_node("character/skeleton/Head")
				if target_bone:
					joint.set_node_a(spatial.get_path())
					yield(get_tree().create_timer(0.1), "timeout")
					joint.set_node_b(target_bone.get_path())
				
				hands.get_node("animation_player").play("grab")
				
				if !audio.playing:
					audio.stream = force_loop
					audio.play()
				
#			if result.collider is PhysicalBone:
#				var body = result.collider
#				joint.global_transform.origin = result.position
#				spatial.global_transform.origin = result.position
#				#target_bone = body
#				target_bone = body.get_parent().get_node("Head")
#				joint.set_node_a(spatial.get_path())
#				joint.set_node_b(target_bone.get_path())
			
		if target_bone:
			var pos = spatial.global_transform.origin
			spatial.global_transform.origin.linear_interpolate(pos, 5 * delta)
			pass
		if Input.is_action_just_pressed("mouse_primary"):
			joint.set_node_a("")
			joint.set_node_b("")
			if target_bone:
				audio.stop()
				audio.stream = force_shoot
				audio.play()
				hands.get_node("animation_player").play("throw")
				target_bone.translation += (spatial.global_transform.origin - global_transform.origin).normalized() * 10
			target_bone = null
	else:
		joint.set_node_a("")
		joint.set_node_b("")
		hands.get_node("animation_player").play("idle")
		if audio.stream == force_loop:
			audio.stop()
