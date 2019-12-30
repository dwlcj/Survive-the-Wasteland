extends RigidBody
class_name Item

export(int, "Ammo", "Health", "Water") var item_type setget set_item_type

func _ready():
	$area.connect("body_entered", self, "_on_body_entered")
	update_items_by_type()
	match item_type:
		0:
			var material = SpatialMaterial.new()
			material.albedo_color = "#14ff00"
			var mesh = $mesh.mesh.duplicate()
			mesh.surface_set_material(0, material)
			$mesh.mesh = mesh
		1:
			var material = SpatialMaterial.new()
			material.albedo_color = "#ff0000"
			var mesh = $mesh.mesh.duplicate()
			mesh.surface_set_material(0, material)
			$mesh.mesh = mesh
		2:
			var material = SpatialMaterial.new()
			material.albedo_color = "#0087ff"
			var mesh = $mesh.mesh.duplicate()
			mesh.surface_set_material(0, material)
			$mesh.mesh = mesh
	
func _on_body_entered(body):
	if body is BaseCharacter:
		match item_type:
			0:
				# Temporary check
				if body is BaseCharacter:
					if body.equipped_gun:
						body.equipped_gun.set_ammo_supply(body.equipped_gun.ammo_supply + 30)
					if body is Player:
						game.player.get_node("hud/message").set_message("Picked up Ammo")
			1:
				body.set_health(clamp(body.health + 30,0,100))
				if body is Player:
					game.player.get_node("hud/message").set_message("Picked up Health")
			2:
				body.set_hydration(clamp(body.hydration + 30,0,100))
				if body is Player:
					game.player.get_node("hud/message").set_message("Picked up Water")
		
		$audio.play()
		visible = false
		yield(get_tree().create_timer(10), "timeout")
		queue_free()

func update_items_by_type():
	pass
	
func set_item_type(value):
	item_type = value
	update_items_by_type()
