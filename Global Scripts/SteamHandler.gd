extends Node

var player_multiplayer_spawner: MultiplayerSpawner
var crowd_multiplayer_spawner: MultiplayerSpawner
var named_npc_multiplayer_spawner: MultiplayerSpawner

var actor_spawn_node: Node2D

var player_scene: PackedScene
var crowd_scene: PackedScene
var named_scene: PackedScene

var lobby_id: int = 0
var lobby_name: String
var peer: SteamMultiplayerPeer

var lobby_list: Dictionary

var going_to_host: bool = false
var is_host: bool = false
var is_joining: bool = false
var my_multiplayer_id : int = 0

var has_been_init = false
var gathering_lobbies = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	Steam.run_callbacks()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Steam Init: ", Steam.steamInit(480, true))
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_join)
	Steam.lobby_match_list.connect(_on_lobby_match_list)

func setup_steam_multiplayer_values(player_mps: MultiplayerSpawner, npc_mps: MultiplayerSpawner, named_mps: MultiplayerSpawner, 
	actor_spawn_node2d: Node2D,
	player_packed: PackedScene, crowd_packed: PackedScene, named_packed: PackedScene):
	player_multiplayer_spawner = player_mps
	crowd_multiplayer_spawner = npc_mps
	named_npc_multiplayer_spawner = named_mps
	
	actor_spawn_node = actor_spawn_node2d
	
	# Apparently you have to add call here
	player_multiplayer_spawner.spawn_function = _spawn_player
	crowd_multiplayer_spawner.spawn_function = _spawn_npc
	
	player_scene = player_packed
	crowd_scene = crowd_packed
	named_scene = named_packed
	
	has_been_init = true

func host_lobby():
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 16)
	is_host = true

func join_lobby(the_lobby_id: int):
	is_joining = true
	Steam.joinLobby(the_lobby_id)

func _on_lobby_created(result: int, the_lobby_id: int):
	if result == Steam.Result.RESULT_OK:
		self.lobby_id = the_lobby_id
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		
		Steam.setLobbyData(lobby_id, "name", self.lobby_name)
		Steam.setLobbyData(lobby_id, "mode", "GodotSteam test")
		
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_add_player)
		multiplayer.peer_disconnected.connect(_remove_player)
		my_multiplayer_id = multiplayer.get_unique_id()
		_add_player(my_multiplayer_id) #Creates the host player.
		print("Lobby ID: ", lobby_id)

func _on_lobby_join(the_lobby_id: int, _permissions: int, _locked: bool, _response: int):
	if !is_joining:
		return
	
	self.lobby_id = the_lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	multiplayer.multiplayer_peer = peer
	is_joining = false

func _add_player(id : int):
	print("Peer being added: ", id)
	if multiplayer.is_server():
		if !PlayersData.session_data.has(id):
			PlayersData.session_data[id] = {
				"player_id": id,
				"player_name": MyData.my_name
			}
		_spawn_for_peer(id)

func _spawn_for_peer(id: int):
	if !PlayersData.session_data.has(id):
		print("Waiting on appearance for ", id)
		return
	
	print("Spawning player for peer ", id)
	player_multiplayer_spawner.spawn({"peer_id": id, "player_data": PlayersData.session_data[id]})

func _remove_player(id: int):
	if !actor_spawn_node.has_node(str(id)):
		return
	
	actor_spawn_node.get_node(str(id)).queue_free()

func _spawn_player(data):
	#var player : Player_Character_Class = player_scene.instantiate()
	#player.name = str(data.peer_id)
	#player.set_meta("appearance", data.appearance)
	
	#return player
	pass

func _spawn_npc(data):
	#var npc : Non_Player_Character_Class = crowd_scene.instantiate()
	#npc.name = data.name
	#npc.start_pos = data.position
	#return npc
	pass

func spawn_npc(npc_name: String, npc_position: Vector2):
	if !multiplayer.is_server():
		return
	var crowd_name : String = "crowd_"+ npc_name
	var data = {"position": npc_position, "name": crowd_name}

	crowd_multiplayer_spawner.spawn(data)
	

func get_lobbies():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	
	Steam.requestLobbyList()
	gathering_lobbies = true


func _on_lobby_match_list(these_lobbies: Array):
	lobby_list = {}
	for this_lobby in these_lobbies:
		var the_lobby_id = this_lobby
		var lobby_name: String = Steam.getLobbyData(the_lobby_id, "name")
		var lobby_mode: String = Steam.getLobbyData(the_lobby_id, "mode")
		var lobby_num_members: int = Steam.getNumLobbyMembers(the_lobby_id)
		
		#lobby_list[the_lobby_id]["name"] = lobby_name
		#lobby_list[the_lobby_id]["mode"] = lobby_mode
		#lobby_list[the_lobby_id]["members count"] = lobby_num_members
		
		lobby_list[the_lobby_id] = {
			"name": lobby_name,
			"mode": lobby_mode,
			"members count": lobby_num_members
		}
	
	gathering_lobbies = false
