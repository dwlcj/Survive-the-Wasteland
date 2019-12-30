extends "base.gd"
class_name Player

const FOV_INITAL = 82
const FOV_ZOOM = 22
const FOV_SPRINT = 92

var fov

var camera

const CAM_LEAN_TARGET = 0.025
var camera_lean

var MOUSE_SENSITIVITY = 0.075

# Head bob
var transition_speed = 20
const BOB_SPEED = 7
const BOB_SPEED_SPRINT = 14
const BOB_SPEED_CROUCH = 4
var bob_amount = 0.05
var bob_timer = PI / 2
var rest_pos = Vector3()
var cam_pos = Vector3()

# Animations
onready var animation_state_machine = $character/animation_tree["parameters/playback"]

var grenade_scn = preload("res://scenes/weapons/grenade.tscn")

func _ready():
	camera = $head/camera
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.fov = FOV_INITAL
	var camera_rotation_z_target = 0.0
	
	connect("health_changed", self, "_on_health_changed")
	connect("hydration_changed", self, "_on_hydration_changed")
	
	set_health(100)

func _physics_process(delta):
	process_player_input(delta)
	process_camera_movement(delta)
	process_headbob(delta)
	process_animations()
	process_guns()

func process_player_input(delta):
	# Walking
	if Input.is_action_pressed("movement_forward"):
		cmd.forward = 1
	elif Input.is_action_pressed("movement_backward"):
		cmd.forward = -1
	else:
		cmd.forward = 0
	if Input.is_action_pressed("movement_left"):
		cmd.left = 1
	elif Input.is_action_pressed("movement_right"):
		cmd.left = -1
	else:
		cmd.left = 0

	# Jumping
	if is_on_floor():
		if Input.is_action_pressed("movement_jump"):
			cmd.jump = true
		else:
			cmd.jump = false

	# Sprinting
	if Input.is_action_pressed("movement_sprint"):
		cmd.sprint = true
	else:
		cmd.sprint = false

	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Zoom
	if Input.is_action_pressed("zoom"):
		fov = FOV_ZOOM
	else:
		fov = FOV_INITAL
	camera.fov += (fov - camera.fov) * 5 * delta
	
	if Input.is_action_just_pressed("drop"):
		if equipped_gun:
			equipped_gun.drop()
			equipped_gun = null
	
	if equipped_gun:
		if Input.is_action_pressed("mouse_primary") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			if equipped_gun.can_fire:
				equipped_gun.fire(self)
				camera.shake(0.025, 0.15)
		if Input.is_action_just_pressed("reload"):
			equipped_gun.reload()

func process_guns():
	if !is_dead:
		var guns = get_node("head/weapons/holder").get_children()
		if guns.size() > 0:
			for g in guns:
				g.visible = false
				g.get_node("hud/ammo").visible = false
		
			if Input.is_action_just_released("next_weapon") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				if guns.size() > 0:
					gun_index += 1
					if gun_index >= guns.size():
						gun_index = -1					
					equipped_gun = guns[gun_index]
					equipped_gun.get_node("animation_player").play("equip")
					if gun_index == -1:
						equipped_gun = null

		if equipped_gun:
			$head/hands.visible = false
			equipped_gun.visible = true
			equipped_gun.get_node("hud/ammo").visible = true
		else:
			$head/hands.visible = true

func process_camera_movement(delta):
	# Lean
	if cmd.left == 1:
		camera_lean = CAM_LEAN_TARGET
	elif cmd.left == -1:
		camera_lean = -CAM_LEAN_TARGET
	else:
		camera_lean = 0	
	camera.rotation.z += (camera_lean - camera.rotation.z) * 15 * delta
	
	# Sprint Zoom
	if cmd.sprint and dir.dot(vel) > 0:
		fov = FOV_SPRINT
	else:
		fov = FOV_INITAL
	camera.fov += (fov - camera.fov) * 5 * delta

func process_headbob(delta):
	if is_grounded and dir.dot(vel) > 0:
		var bob_speed = BOB_SPEED
		if is_sprinting:
			bob_speed = BOB_SPEED_SPRINT
		bob_timer += bob_speed * delta
		var new_pos = Vector3(cos(bob_timer) * bob_amount, rest_pos.y + abs((sin(bob_timer) * bob_amount)), rest_pos.z)
		cam_pos = new_pos
	else:
		bob_timer = PI / 2
		var new_pos = Vector3(lerp(cam_pos.x, rest_pos.x, transition_speed * delta), lerp(cam_pos.y, rest_pos.y, transition_speed * delta), lerp(cam_pos.z, rest_pos.z, transition_speed * delta))
		cam_pos = new_pos
	
	if bob_timer > PI * 2:
		bob_timer = 0
		
	camera.transform.origin += (cam_pos - camera.transform.origin) * 5 * delta
	pass

func process_animations():
	if dir.dot(vel) > 0:
		animation_state_machine.travel("run")
	if dir.dot(vel) <= 0:
		animation_state_machine.travel("idle")

func update_hud():
	if get_node("hud/health"):
		get_node("hud/health").text = "health: " + str(health)
	if get_node("hud/hydration"):
		get_node("hud/hydration").value = hydration

# Health
func _on_health_changed(new_value):
	health = new_value
	update_hud()

func _on_hydration_changed(new_value):
	hydration = new_value
	update_hud()

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

	var camera_rot = head.rotation_degrees
	camera_rot.x = clamp(camera_rot.x, -70, 70)
	head.rotation_degrees = camera_rot

func hit(damage, dealer):
	.hit(damage, dealer)
	camera.shake(0.025, 0.2)

func die():
	.die()
	
	$head/weapons.hide()
	$head/hands.hide()
	
	var head = get_node("head")
	var skeleton = get_node("character/skeleton")
	head.get_parent().remove_child(head)
	skeleton.add_child(head)
	head.set_owner(skeleton)
	#$collision_shape.disabled = true

	$character/mesh.set_layer_mask_bit(0, true)
	$character/mesh.set_layer_mask_bit(1, false)
	animation_state_machine.stop()
	$character/animation_tree.active = false
	$character/animation_player.stop()
	$character/skeleton.physical_bones_start_simulation()

func rise():
	if is_dead:
		is_dead = false
		set_health(100)
		set_hydration(100)
		
		$character/skeleton.physical_bones_stop_simulation()
		$character/animation_tree.active = true
		$character/mesh.set_layer_mask_bit(0, false)
		$character/mesh.set_layer_mask_bit(1, true)
		
		var head = get_node("character/skeleton/head")
		head.get_parent().remove_child(head)
		self.add_child(head)
		head.set_owner(self)
		
		$head/weapons.show()
		$head/hands.show()
		
		# at random location - temporary
		randomize()
		transform.origin = Vector3(rand_range(-10, 10), 10, rand_range(-10, 10))
