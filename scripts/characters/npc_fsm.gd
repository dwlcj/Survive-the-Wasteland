extends BaseCharacter
class_name NPC_FSM

var brain : StackFSM
var hit_animations = ["attack", "attack_2", "headbutt", "kick", "kick_2", "punch"]

onready var player = get_tree().root.get_child(get_tree().root.get_child_count() - 1).get_node("player")
onready var animation_state_machine = get_node("character/animation_tree")["parameters/playback"]
onready var impact_blood = preload("res://particles/impact/blood.tscn")

const ATTACK_RANGE = 5
const INTEREST_RANGE = 500

var attack_finished = false

func _ready():
	brain = StackFSM.new()
	self.add_child(brain)
	brain.push_state("idle")
	get_node("viewport/canvas_layer/health").text = str(self.health)

func _physics_process(delta):
	pass

func idle():
	get_node("viewport/canvas_layer/state").text = str(brain.stack)
	cmd.forward = 0
	animation_state_machine.travel("idle")
	if translation.distance_squared_to(player.translation) <= INTEREST_RANGE:
		brain.push_state("chase_player")
	if translation.distance_squared_to(player.translation) <= ATTACK_RANGE:
		brain.push_state("attack_player")

func chase_player():
	get_node("viewport/canvas_layer/state").text = str(brain.stack)
	self.look_at(Vector3(player.transform.origin.x, transform.origin.y, player.transform.origin.z), Vector3.UP)
	cmd.forward = 1
	animation_state_machine.travel("run")
	if translation.distance_squared_to(player.translation) > INTEREST_RANGE:
		brain.pop_state()
	if translation.distance_squared_to(player.translation) <= ATTACK_RANGE:
		brain.pop_state()
		brain.push_state("attack_player")

func attack_player():
	get_node("viewport/canvas_layer/state").text = str(brain.stack)
	set_attack_finished(false)
	self.look_at(Vector3(player.transform.origin.x, transform.origin.y, player.transform.origin.z), Vector3.UP)
	cmd.forward = 0
	animation_state_machine.travel(hit_animations[randi() % hit_animations.size()])
	if translation.distance_squared_to(player.translation) > ATTACK_RANGE and attack_finished:
		brain.pop_state()

func hit(damage):
	.hit(damage)
	get_node("viewport/canvas_layer/health").text = str(self.health)

func die():
	.die()
	animation_state_machine.stop()
	$character/animation_tree.active = false
	$character/animation_player.stop()
	$collision_shape.disabled = true
	$character/skeleton.physical_bones_start_simulation()

func create_impact_fx(scn_fx, result):
	var fx = scn_fx.instance()
	get_tree().root.add_child(fx)
	fx.global_transform.origin = result.global_transform.origin
	fx.emitting = true

func hit_target():
	var bodies = $hurt.get_overlapping_bodies()
	for body in bodies:
		if body is KinematicBody and body.has_method("hit"):
			body.hit(25)
			body.vel = (body.global_transform.origin - $hurt.global_transform.origin).normalized() * 15
			create_impact_fx(impact_blood, body)
		if body is RigidBody:
			body.apply_impulse(global_transform.origin, (global_transform.origin - body.global_transform.origin).normalized() * 5)

func set_attack_finished(value):
	attack_finished = value
