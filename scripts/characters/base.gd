extends KinematicBody
class_name BaseCharacter

const GRAVITY = -24.8
const ACCEL = 6
const DEACCEL = 12
const SPRINT_ACCEL = 18
const AIR_ACCEL = 5
const AIR_DEACCEL = 2
const MAX_SLOPE_ANGLE = 40

const MAX_STAIR_SLOPE = 10
const STAIR_JUMP_HEIGHT = 4

export var max_speed = 12
export var max_sprint_speed = 20
export var jump_speed = 10

var cmd = {
	forward = 0,
	left = 0,
	jump = false,
	sprint = false
}

var health setget set_health
signal health_changed

var hydration setget set_hydration
signal hydration_changed
var hydration_timer = 0
var is_thirsty = false
var thirst_timer = 0

var is_on_stairs = false
var is_sprinting = false
var is_dead = false
var last_time_in_air = 0

var vel = Vector3()
var dir = Vector3()
var input_movement_vector = Vector2()

var cam_xform
var head

# Footsteps
const TIME_BETWEEN_FOOTSTEP = 0.5
var footstep_timer = 0
const footsteps = [
	preload("res://sounds/footsteps/test/footstep_1.wav"),
	preload("res://sounds/footsteps/test/footstep_2.wav"),
	preload("res://sounds/footsteps/test/footstep_3.wav"),
	preload("res://sounds/footsteps/test/footstep_4.wav"),
	preload("res://sounds/footsteps/test/footstep_5.wav")
]
const footstep_jump = preload("res://sounds/footsteps/test/footstep_jump.wav")
const footstep_land = preload("res://sounds/footsteps/test/footstep_land.wav")

export(AudioStreamSample) var pain_sound
export(AudioStreamSample) var death_sound

var hit_sound = preload("res://sounds/impact/impact_wound.wav")

# ground check
var is_grounded = false

var equipped_gun
var gun_index = 0

func _ready():
	head = $head
	set_health(100)
	set_hydration(100)

func _physics_process(delta):
	if !is_dead:
		process_grounded()
		process_cmd()
		process_movement(delta)
		process_footsteps(delta)
		process_fall_damage(delta)
		process_stairs()
		
		process_hydration(delta)
		process_thirstiness(delta)

func process_cmd():
	# Walking
	dir = Vector3()
	cam_xform = head.get_global_transform()

	input_movement_vector = Vector2()

	if cmd.forward == 1:
		input_movement_vector.y += 1
	if cmd.forward == -1:
		input_movement_vector.y -= 1
	if cmd.left == 1:
		input_movement_vector.x -= 1
	if cmd.left == -1:
		input_movement_vector.x += 1

	input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized.
	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x

	# Jumping
	if is_on_floor():
		if cmd.jump:
			vel.y = jump_speed
	
	# Sprinting
	if cmd.sprint:
		is_sprinting = true
	else:
		is_sprinting = false


func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()
	
	vel.y += delta * GRAVITY
	
	var hvel = vel
	hvel.y = 0
	
	var target = dir
	if is_sprinting:
		target *= max_sprint_speed
	else:
		target *= max_speed
	
	var accel
	if dir.dot(hvel) > 0:
		if is_sprinting:
			accel = SPRINT_ACCEL
		else:
			accel = ACCEL
	else:
		if is_on_floor():
			accel = DEACCEL
		else:
			accel = AIR_DEACCEL
	
	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))
	
func process_footsteps(delta):
	if has_node('audio/footsteps'):
		footstep_timer += delta
		if is_on_floor() and (abs(input_movement_vector.x) > 0 or abs(input_movement_vector.y) > 0):
			var time_between_footstep
			if is_sprinting:
				time_between_footstep = TIME_BETWEEN_FOOTSTEP / 2
			else:
				time_between_footstep = TIME_BETWEEN_FOOTSTEP
			if footstep_timer > time_between_footstep:
				$audio/footsteps.stream = footsteps[randi() % footsteps.size()]
				$audio/footsteps.play(0)
				footstep_timer = 0
			pass
		if is_on_floor() and cmd.jump:
			$audio/footsteps.stream = footstep_land
			$audio/footsteps.play(0)
			pass
		if is_grounded and vel.y > 0 and !is_on_stairs:
			$audio/footsteps.stream = footstep_jump
			$audio/footsteps.play(0)
			pass
	pass

func process_fall_damage(delta):
	if !is_on_floor():
		last_time_in_air += delta
	else:
		if last_time_in_air > 2:
			hit(20, null)
		last_time_in_air = 0
	pass

func process_grounded():
	if $ground_check.is_colliding() == true:
		is_grounded = true
	else:
		is_grounded = false
	pass

func process_stairs():
	if has_node("stair_catcher"):
		$stair_catcher.translation.x = input_movement_vector.x
		$stair_catcher.translation.z = -input_movement_vector.y
		if dir.length() > 0 and $stair_catcher.is_colliding():
			var stair_normal = $stair_catcher.get_collision_normal()
			var stair_angle = rad2deg(acos(stair_normal.dot(Vector3.UP)))
			if stair_angle < MAX_STAIR_SLOPE:
				vel.y = STAIR_JUMP_HEIGHT
				is_on_stairs = true
			else:
				is_on_stairs = false

func process_hydration(delta):
	if !is_thirsty:
		hydration_timer += delta
		if hydration_timer >= 5:
			hydration_timer = 0
			set_hydration(hydration - 10)

func process_thirstiness(delta):
	if is_thirsty:
		thirst_timer += delta
		if thirst_timer >= 2:
			thirst_timer = 0
			set_health(health - 20)

func hit(damage, dealer):
	set_health(health - damage)
	if has_node("audio/hit"):
		$audio/hit.stream = hit_sound
		$audio/hit.play()
	if has_node('audio/voice'):
		$audio/voice.stream = pain_sound
		$audio/voice.play()
		
func set_health(value):
	health = value
	emit_signal('health_changed', health)
	if health <= 0 and !is_dead:
		die()

func set_hydration(value):
	hydration = value
	emit_signal('hydration_changed', hydration)
	if hydration <= 0 and !is_thirsty:
		is_thirsty = true
	if hydration > 0:
		is_thirsty = false
		
func die():
	if !is_dead:
		drop_guns()
		if has_node("audio/voice"):
			$audio/voice.stream = death_sound
			$audio/voice.play()
		is_dead = true

func drop_guns():
	equipped_gun = null
	var guns = get_node("head/weapons/holder").get_children()
	if guns.size() > 0:
		for g in guns:
			if g.has_method("drop"):
				g.drop()
