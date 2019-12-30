extends Spatial
class_name Gun

export var ray_length = 500
export var damage = 10
export var impact_multiplier = 10
export(float, 0.1, 0.8, 0.05) var fire_delay = 0.15
export var bullets = 5
export(float, 0, 50, 5) var spread = 0

# ammo
export var MAX_AMMO = 32
onready var ammo setget set_ammo
onready var ammo_supply : float setget set_ammo_supply
signal ammo_changed
var is_reloading = false

# sounds
export(AudioStreamSample) var fire_sample
export(AudioStreamSample) var reload_sample
export(AudioStreamSample) var pick_sample

# impact
onready var scn_impact = preload("res://scenes/impact/impact.tscn")
onready var scn_wound = preload("res://scenes/impact/wound.tscn")
onready var scn_blood = preload("res://particles/impact/blood.tscn")
onready var scn_debris = preload("res://particles/impact/debris.tscn")

# muzzle flash
var muzzle_flash : Node
var muzzle_flash_timer = 0

var is_pickable = true
var shooter : BaseCharacter
var can_fire = true
var fire_timer = 0
var ray_cast

func _ready():
	connect("ammo_changed", self, "_on_ammo_changed")
	get_node("pickup").connect("body_entered", self, "_on_pickup")
	
	ray_cast = get_node("ray_cast")
	ray_cast.cast_to.z = -ray_length
	ray_cast.enabled = true
	muzzle_flash = get_node("muzzle_flash")
	
	set_ammo(MAX_AMMO)
	get_node("animation_player").play("idle")

func _physics_process(delta):
	if muzzle_flash.visible == true:
		muzzle_flash_timer += 1.0 * delta
		if muzzle_flash_timer >= 0.05:
			muzzle_flash.visible = false
			muzzle_flash.get_node("light").visible = false
			muzzle_flash_timer = 0
	
	if fire_timer < fire_delay:
		fire_timer += 1.0 * delta
	if fire_timer > fire_delay:
		can_fire = true
	else:
		can_fire = false

	if ammo <= 0 or is_reloading: 
		can_fire = false

func reload():
	if ammo < MAX_AMMO and ammo_supply > 0 and !is_reloading:
		is_reloading = true
		
		get_node("animation_player").seek(0, true)
		get_node("animation_player").play("reload")
		
		get_node("audio/reload").stream = reload_sample
		get_node("audio/reload").play()
		
		yield(get_node("animation_player"), "animation_finished")
		is_reloading = false
		
		var ammo_required = MAX_AMMO - ammo
		if ammo_supply >= ammo_required:
			ammo_supply -= ammo_required
			set_ammo(ammo + ammo_required)
		else:
			set_ammo(ammo + ammo_supply)
			ammo_supply = 0

func fire(shooter):
	if can_fire:
		fire_timer = 0
		
		set_ammo(ammo - 1)
		
		get_node("audio/fire").stream = fire_sample
		get_node("audio/fire").play()
		
		get_node("animation_player").seek(0, true)
		get_node("animation_player").play("fire")
		
		muzzle_flash.rotation.z = rand_range(-180, 180)
		muzzle_flash.visible = true
		muzzle_flash.get_node("light").visible = true
		
		for i in bullets:
				if shooter is Player:
					var screen_center = get_viewport().size / 2
					var camera = shooter.get_node("head/camera")
					var state = get_world().direct_space_state
					var from = camera.project_ray_origin(screen_center)
					var to = from + camera.project_ray_normal(screen_center)  * ray_length + random_spread(spread)
					var result = state.intersect_ray(from, to, [self, shooter], 1)
					if result:
						create_forces_and_effects(result.collider, result.position, result.normal, from)
				if shooter is NPC:
					var from = translation
					var body = ray_cast.get_collider()
					if body:
						create_forces_and_effects(body, ray_cast.get_collision_point(), ray_cast.get_collision_normal(), from)
		can_fire = false
	else:
		ray_cast.enabled = false

func set_ammo(value):
	ammo = value
	emit_signal("ammo_changed", ammo)

func set_ammo_supply(value):
	ammo_supply = value
	emit_signal("ammo_changed", ammo)

func _on_ammo_changed(ammo):
	update_hud()

func update_hud():
	get_node("hud/ammo").text = "ammo: " + str(ammo) + "/" + str(ammo_supply)

func _on_pickup(body):
	pick(body)

func pick(shooter):
	if is_pickable and shooter is BaseCharacter and !shooter.is_dead:
		self.visible = false
		print(shooter.get_name() + " picked up a gun")
		is_pickable = false
		get_node("pickup/collision_shape").disabled = true
		get_node("collision_shape").disabled = true
		self.sleeping = true
		get_parent().remove_child(self)
		var holder = shooter.get_node("head/weapons/holder")
		holder.add_child(self)
		self.set_owner(holder)
		self.transform = Transform.IDENTITY
		get_node("audio/pick").stream = pick_sample
		get_node("audio/pick").play()
		get_node("animation_player").play("equip")

func drop():
	self.visible = true
	var weapons_container = game.main_scene.get_node("items")
	var previous_position = global_transform
	get_parent().remove_child(self)
	weapons_container.add_child(self)
	self.set_owner(weapons_container)
	get_node("hud/ammo").visible = false
	get_node("pickup/collision_shape").disabled = false
	get_node("collision_shape").disabled = false
	self.sleeping = false
	self.global_transform = previous_position
	yield(get_tree().create_timer(1), "timeout")
	is_pickable = true

func random_spread(spread):
	randomize()
	return Vector3(rand_range(-spread, spread), rand_range(-spread, spread), rand_range(-spread, spread))

func create_impact(scn, point, normal, body, from):
	var impact = scn.instance()
	body.add_child(impact)
	impact.global_transform.origin = point
	impact.global_transform = utils.look_at_with_z(impact.global_transform, normal, from)
	impact.rotation.z = rand_range(-180, 180)

func create_fx(scn, point, normal, from):
	var fx = scn.instance()
	get_tree().root.add_child(fx)
	fx.global_transform.origin = point
	fx.emitting = true
	fx.global_transform = utils.look_at_with_y(fx.global_transform, normal, from)

func create_forces_and_effects(body, point, normal, from):
	if body is StaticBody:
		create_impact(scn_impact, point, normal, body, from)
		create_fx(scn_debris, point, normal, from)
	if body is BaseCharacter:
		body.hit(damage, shooter)
		body.vel = (point - global_transform.origin).normalized() * impact_multiplier
		create_impact(scn_wound, point, normal, body, from)
		create_fx(scn_blood, point, normal, from)
	if body is RigidBody:
		var dir = body.global_transform.origin - point
		dir = dir.normalized()
		body.apply_impulse(point, dir * impact_multiplier / 25)
		create_impact(scn_impact, point, normal, body, from)
		create_fx(scn_debris, point, normal, from)
	if body is PhysicalBone:
		create_impact(scn_wound, point, normal, body, from)
		create_fx(scn_blood, point, normal, from)
		body.translation += (point - global_transform.origin).normalized() * impact_multiplier
