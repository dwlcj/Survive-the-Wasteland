extends BaseCharacter
class_name NPC

const PERCEPTION_RANGE = 50
const FOV = 90

onready var player = game.main_scene.get_node("player")
onready var animation_state_machine = $character/animation_tree["parameters/playback"]
onready var navigation = game.main_scene.get_node("map/navigation")

var is_idling = true
var is_attacking = false
var attack_finished = true
var target_found = false

var hit_animations = ["attack", "attack_2", "attack_3"]

onready var impact_blood = preload("res://particles/impact/blood.tscn")
onready var impact_debris = preload("res://particles/impact/debris.tscn")
onready var voice = [
	preload("res://sounds/voice/robot/voice_1.wav"),
	preload("res://sounds/voice/robot/voice_2.wav"),
	preload("res://sounds/voice/robot/voice_3.wav"),
	preload("res://sounds/voice/robot/voice_4.wav"),
	preload("res://sounds/voice/robot/voice_5.wav"),
	preload("res://sounds/voice/robot/voice_6.wav"),
	preload("res://sounds/voice/robot/voice_7.wav"),
	preload("res://sounds/voice/robot/voice_8.wav"),
	preload("res://sounds/voice/robot/voice_9.wav")
]
var time_to_say_stuff = true

var patrol_target = Vector3()
var patrol_target_set = false
var is_patroling = false

var target_item : Node
var target_item_set = false
var is_looking_for_items = false

var can_shoot = true

onready var muzzle_flash = $character/skeleton/gun/helper/muzzle_flash
var muzzle_flash_timer = 0
var spread = 1

var idling_enabled = false
var can_idle = true
var time_to_idle = false
var time_to_idle_timer = 0

func ready():
	pass

func _physics_process(delta):
	var target = game.player
	process_guns()
	process_logic(target, delta)
	say_random_stuff()
	#process_bones()
	
func process_logic(target, delta):
	if !is_dead:
		if dir.dot(vel) > 0:
			animation_state_machine.travel("run")
		if dir.dot(vel) <= 0:
			animation_state_machine.travel("idle")
		
		if target_is_visible(target, FOV, PERCEPTION_RANGE):
			target_found = true
		
		look_for_items()
		
		if target_found:
			if target is BaseCharacter:
				if !target.is_dead:
					is_looking_for_items = false
					can_idle = false
					if translation.distance_to(target.translation) > 5:
						if equipped_gun:
							shoot_at_target(target)
						else:
							chase_target(target)
					elif translation.distance_to(target.translation) <= 5:
						chase_target(target)
						if translation.distance_to(target.translation) < 2:
								cmd.forward = 0
								look_at(Vector3(target.translation.x, translation.y, target.translation.z), Vector3.UP)
								set_attack_finished(false)
								animation_state_machine.travel(hit_animations[randi() % hit_animations.size()])
		if translation.distance_to(target.translation) > PERCEPTION_RANGE:
			target_found = false
			look_for_items()
		if target is BaseCharacter:
			if target.is_dead:
				target_found = false
			
		if can_idle and idling_enabled:
			time_to_idle_timer += delta
			if !time_to_idle:
				randomize()
				if time_to_idle_timer >= rand_range(5, 15):
					time_to_idle = true
					time_to_idle_timer = 0
			if time_to_idle:
				randomize()
				if time_to_idle_timer >= rand_range(5, 15):
					time_to_idle = false
					time_to_idle_timer = 0
			if time_to_idle:
				cmd.forward = 0

func process_guns():
	if !is_dead:
		var guns = get_node("head/weapons/holder").get_children()
		if guns.size() > 0:
			equipped_gun = guns[guns.size() - 1]
			equipped_gun.visible = true
		else:
			equipped_gun = null

func set_is_attacking(value):
	is_attacking = value

func hit_target():
	var bodies = $hurt.get_overlapping_bodies()
	for body in bodies:
		if body is KinematicBody and body.has_method("hit"):
			body.hit(5, self)
			body.vel = (body.global_transform.origin - $hurt.global_transform.origin).normalized() * 15
			create_impact_fx_b(impact_blood, body)
		if body is RigidBody:
			body.apply_impulse(global_transform.origin, (global_transform.origin - body.global_transform.origin).normalized() * 5)

func chase_target(target):
	var path = navigation.get_simple_path(translation, target.translation)
	var last_point = translation
	var distance = 3
	for i in range(path.size()):
		var distance_between_points = last_point.distance_to(path[0])
		if distance <= distance_between_points:
			look_at(Vector3(path[0].x, translation.y, path[0].z), Vector3.UP)
			cmd.forward = 1
			break
		elif distance < 0.0:
			translation = path[0]
			break
		distance -= distance_between_points
		last_point = path[0]
		path.remove(0)

func patrol(patrol_radius):
	is_patroling = true
	if !patrol_target_set:
		randomize()
		patrol_target = Vector3(rand_range(-patrol_radius, patrol_radius), 1, rand_range(-patrol_radius, patrol_radius))
		patrol_target_set = true
	else:
		var path = navigation.get_simple_path(translation, patrol_target)
		var last_point = translation
		var distance = 5
		for i in range(path.size()):
			var distance_between_points = last_point.distance_to(path[0])
			if distance <= distance_between_points:
				look_at(Vector3(path[0].x, translation.y, path[0].z), Vector3.UP)
				cmd.forward = 1
				break
			elif distance < 0:
				translation = path[0]
				break
			distance -= distance_between_points
			last_point = path[0]
			path.remove(0)
		if translation.distance_to(patrol_target) <= 5:
			patrol_target_set = false

func look_for_items():
	can_idle = true
	is_looking_for_items = true
	if !target_item_set:
		var item = game.items[randi() % game.items.size()]
		if is_instance_valid(item):
			target_item = item
			target_item_set = true
		else:
			target_item_set = false
	else:
		if is_instance_valid(target_item):
			var path = navigation.get_simple_path(translation, target_item.translation)
			var last_point = translation
			var distance = 3
			for i in range(path.size()):
				var distance_between_points = last_point.distance_to(path[0])
				if distance <= distance_between_points:
					look_at(Vector3(path[0].x, translation.y, path[0].z), Vector3.UP)
					cmd.forward = 1
					break
				elif distance < 0:
					translation = path[0]
					break
				distance -= distance_between_points
				last_point = path[0]
				path.remove(0)
			if translation.distance_to(target_item.translation) <= 1:
				target_item_set = false
				cmd.foward = 0
		else:
			target_item_set = false

func target_is_visible(target, fov, distance):
	var facing = -transform.basis.z
	var to_target = target.translation - global_transform.origin
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(global_transform.origin, target.global_transform.origin, [self])
	var result_target : Node
	if result:
		if result.collider is KinematicBody or result.collider is RigidBody:
			result_target = result.collider
	return rad2deg(facing.angle_to(to_target)) < fov and global_transform.origin.distance_to(target.global_transform.origin) <= distance and result_target == target

func hit(damage, dealer):
	.hit(damage, dealer)
	if dealer:
		if dealer.is_in_group(game.GROUP_PLAYERS):
			target_found = true
	cmd.forward = 0

func set_attack_finished(value):
	attack_finished = value

func die():
	.die()
	
	animation_state_machine.stop()
	$character/animation_tree.active = false
	$character/animation_player.stop()
	$collision_shape.disabled = true
	$character/skeleton.physical_bones_start_simulation()
	
	# rise after 10 seconds
	yield(get_tree().create_timer(60), "timeout")
	rise()
	
func rise():
	if is_dead:
		target_found = false
		is_dead = false
		set_health(100)
		set_hydration(100)
		$character/skeleton.physical_bones_stop_simulation()
		$collision_shape.disabled = false
		$character/animation_tree.active = true
		# at random location - temporary
		randomize()
		transform.origin = Vector3(rand_range(-500, 500), 200, rand_range(-500, 500))

func say_random_stuff():
	if !$audio/voice.playing and time_to_say_stuff and target_found and !is_dead:
		$audio/voice.stream = voice[randi() % voice.size()]
		$audio/voice.play()
		time_to_say_stuff = false
		randomize()
		yield(get_tree().create_timer(rand_range(2, 10)), "timeout")
		time_to_say_stuff = true

func shoot_at_target(target):
	look_at(Vector3(target.translation.x, translation.y, target.translation.z), Vector3.UP)
	cmd.forward = 0
	if equipped_gun:
		if can_shoot:
			can_shoot = false
			equipped_gun.look_at(target.translation, Vector3.UP)
			equipped_gun.fire(self)
			if equipped_gun.ammo <= 0 and equipped_gun.ammo_supply > 0:
				equipped_gun.reload()
			if equipped_gun.ammo <= 0 and equipped_gun.ammo_supply <= 0:
				equipped_gun.drop()
			randomize()
			yield(get_tree().create_timer(rand_range(0.1, 0.2)), "timeout")
			can_shoot = true

func process_bones():
	var bones = get_node("character/skeleton").get_children()
	for b in bones:
		if b is PhysicalBone:
			if !is_dead:
				b.get_node("collision_shape").disabled = true
				#b.translation = translation
				#b.global_transform = $character/skeleton.get_bone_global_pose($character/skeleton.find_bone(b.bone_name))
			else:
				b.get_node("collision_shape").disabled = false

func create_impact_fx_b(scn_fx, result):
	var fx = scn_fx.instance()
	get_tree().root.add_child(fx)
	fx.global_transform.origin = result.global_transform.origin
	fx.emitting = true
