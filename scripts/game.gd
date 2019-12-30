extends Node

const GROUP_PLAYERS = "players"

var player_scn = preload("res://scenes/characters/player.tscn")
var players_container : Node
var players = []

var npc_scn = preload("res://scenes/characters/npc.tscn")
var npc_container : Node
var npcs = []

var item_scn = preload("res://scenes/items/item.tscn")
var weapon_scn = preload("res://scenes/weapons/ar15.tscn")
var items_container : Node
var items = []

var music = preload("res://music/germ_factory.ogg")
var music_player : AudioStreamPlayer

var player : Node
var root : Node
var main_scene : Node

func _ready():
	root = get_tree().root
	main_scene = root.get_child(get_tree().root.get_child_count() - 1)
	players_container = main_scene.get_node("players")
	npc_container = main_scene.get_node("npcs")
	items_container = main_scene.get_node("items")
	
	music_player = AudioStreamPlayer.new()
	music_player.stream = music
	main_scene.add_child(music_player)
	music_player.play()
	music_player.volume_db = -10
	
	spawn_player(2, 50)
	spawn_items(50, 100, 200)
	spawn_weapons(10, 100, 200)
	spawn_npcs(15, 100, 200)

func _process(delta):
	if(Input.is_action_just_pressed("reload_map")):
		#get_tree().reload_current_scene()
		#get_tree().change_scene("res://scenes/main.tscn")
		player.rise()

func spawn_items(count, radius, height):
	for i in range(count):
		var item = item_scn.instance()
		randomize()
		item.set_item_type(randi() % 3)
		items.push_back(item)
		items_container.add_child(item)
		randomize()
		item.translation = Vector3(rand_range(-radius, radius), height, rand_range(-radius, radius))

func spawn_weapons(count, radius, height):
	for i in range(count):
		var weapon = weapon_scn.instance()
		items.push_back(weapon)
		items_container.add_child(weapon)
		randomize()
		weapon.translation = Vector3(rand_range(-radius, radius), height, rand_range(-radius, radius))

func spawn_npcs(count, radius, height):
	for i in range(count):
		var npc = npc_scn.instance()
		npcs.push_back(npc)
		npc_container.add_child(npc)
		randomize()
		npc.translation = Vector3(rand_range(-radius, radius), height, rand_range(-radius, radius))

func spawn_player(radius, height):
	player = player_scn.instance()
	players.empty()
	players.push_back(player)
	players_container.add_child(player)
	randomize()
	player.translation = Vector3(rand_range(-radius, radius), height, rand_range(-radius, radius))
	player.add_to_group(GROUP_PLAYERS)
