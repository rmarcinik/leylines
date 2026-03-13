extends Node

# General-purpose multiplayer message bus.
# Supports two transports — Steam P2P and local ENet (for same-machine testing).
#
# Any node can participate in sync:
#   Network.register("my_type", _on_my_type)        # subscribe
#   Network.send("my_type", {key: value})            # broadcast (unreliable)
#   Network.send("my_type", {key: value}, true)      # broadcast (reliable)
#   Network.send("my_type", {key: value}, true, id)  # targeted
#
# Handler signature: func _on_my_type(sender_id: int, data: Dictionary)

const UNRELIABLE := 0
const RELIABLE   := 2
const LOCAL_PORT := 7777

# Structural signals — lobby and connection lifecycle
signal lobby_ready(lobby_id: int)
signal peer_connected(steam_id: int, username: String)
signal peer_disconnected(steam_id: int)

var is_host:    bool  = false
var lobby_id:   int   = 0
var world_seed: int   = 0
var lobby_members: Array = []
var lobby_members_max: int = 10

var _handlers:    Dictionary = {}   # String -> Array[Callable]
var _local_mode:  bool       = false
var _mp:          MultiplayerAPI    # set when using ENet

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.p2p_session_request.connect(_on_p2p_session_request)

func _process(_delta: float) -> void:
	if lobby_id > 0 and not _local_mode:
		_drain_packets()

# ── Public API ────────────────────────────────────────────────────────────────

func register(type: String, handler: Callable) -> void:
	if not _handlers.has(type):
		_handlers[type] = []
	_handlers[type].append(handler)

func unregister(type: String, handler: Callable) -> void:
	if _handlers.has(type):
		_handlers[type].erase(handler)

## Send to all peers (target_id=0) or a specific peer.
func send(type: String, data: Dictionary, reliable: bool = false, target_id: int = 0) -> void:
	if lobby_id == 0:
		return
	data['_t'] = type
	if _local_mode:
		_send_enet(data, reliable, target_id)
	else:
		_send_raw(data, RELIABLE if reliable else UNRELIABLE, target_id)

# ── Steam lobby ───────────────────────────────────────────────────────────────

func create_lobby() -> void:
	if lobby_id == 0:
		is_host = true
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_members_max)

func join_lobby(id: int) -> void:
	Steam.joinLobby(id)

func _on_lobby_created(connect: int, id: int) -> void:
	if connect == 1:
		lobby_id = id
		world_seed = randi()
		Steam.setLobbyData(lobby_id, 'name', 'Leylines')
		Steam.allowP2PPacketRelay(true)
		print("Steam lobby created: %d  seed: %d" % [lobby_id, world_seed])
		emit_signal("lobby_ready", lobby_id)

func _on_lobby_joined(id: int, _perms: int, _locked: int, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = id
		_refresh_members()
		for m in lobby_members:
			if m['steam_id'] != Global.steam_id:
				emit_signal("peer_connected", m['steam_id'], m['name'])
		_send_handshake()
		emit_signal("lobby_ready", lobby_id)
	else:
		print("Join lobby failed, response: ", response)

func _on_lobby_chat_update(id: int, change_id: int, _maker: int, chat_state: int) -> void:
	if id != lobby_id:
		return
	_refresh_members()
	if chat_state == 2 or chat_state == 4:
		emit_signal("peer_disconnected", change_id)

func _refresh_members() -> void:
	if _local_mode:
		return
	lobby_members.clear()
	for i in range(Steam.getNumLobbyMembers(lobby_id)):
		var sid: int = Steam.getLobbyMemberByIndex(lobby_id, i)
		lobby_members.append({'steam_id': sid, 'name': Steam.getFriendPersonaName(sid)})

# ── Local ENet lobby (same-machine testing) ───────────────────────────────────

func create_local_lobby() -> void:
	_local_mode = true
	is_host    = true
	world_seed = randi()
	lobby_id   = LOCAL_PORT
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(LOCAL_PORT)
	get_tree().get_multiplayer().multiplayer_peer = peer
	_mp = get_tree().get_multiplayer()
	_mp.peer_connected.connect(_on_enet_connected)
	_mp.peer_disconnected.connect(_on_enet_disconnected)
	_mp.peer_packet.connect(_on_enet_packet)
	print("Local lobby on port %d  seed: %d" % [LOCAL_PORT, world_seed])
	emit_signal("lobby_ready", lobby_id)

func join_local_lobby() -> void:
	_local_mode = true
	var peer := ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", LOCAL_PORT)
	get_tree().get_multiplayer().multiplayer_peer = peer
	_mp = get_tree().get_multiplayer()
	_mp.peer_connected.connect(_on_enet_connected)
	_mp.peer_disconnected.connect(_on_enet_disconnected)
	_mp.peer_packet.connect(_on_enet_packet)
	# lobby_ready and peer_connected emitted in _on_enet_connected

func _on_enet_connected(enet_id: int) -> void:
	if is_host:
		# New client connected — send them the world seed
		_send_enet({'_t': 'world_seed', 'seed': world_seed}, true, enet_id)
	else:
		# Connected to host (enet_id == 1 for server)
		lobby_id = LOCAL_PORT
		emit_signal("peer_connected", enet_id, "host")
		_send_enet({'_t': 'handshake', 'name': Global.steam_username}, true, 0)
		emit_signal("lobby_ready", lobby_id)

func _on_enet_disconnected(enet_id: int) -> void:
	emit_signal("peer_disconnected", enet_id)

var _enet_pkt_logged := false
func _on_enet_packet(from_id: int, packet: PackedByteArray) -> void:
	if not _enet_pkt_logged:
		print("[Network._on_enet_packet] first packet from ", from_id, " size=", packet.size())
		_enet_pkt_logged = true
	_route(from_id, bytes_to_var(packet))

func _send_enet(data: Dictionary, reliable: bool, target_id: int) -> void:
	var bytes: PackedByteArray
	bytes.append_array(var_to_bytes(data))
	var mode := MultiplayerPeer.TRANSFER_MODE_RELIABLE if reliable \
		else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED
	_mp.send_bytes(bytes, target_id, mode)

# ── Steam P2P ─────────────────────────────────────────────────────────────────

func _on_p2p_session_request(remote_id: int) -> void:
	Steam.acceptP2PSessionWithUser(remote_id)

func _send_raw(data: Dictionary, send_type: int, target_id: int) -> void:
	var bytes: PackedByteArray
	bytes.append_array(var_to_bytes(data))
	if target_id == 0:
		for m in lobby_members:
			if m['steam_id'] != Global.steam_id:
				Steam.sendP2PPacket(m['steam_id'], bytes, send_type, 0)
	else:
		Steam.sendP2PPacket(target_id, bytes, send_type, 0)

func _drain_packets(n: int = 0) -> void:
	if n >= 32 or Steam.getAvailableP2PPacketSize(0) == 0:
		return
	var pkt_size: int = Steam.getAvailableP2PPacketSize(0)
	var raw: Dictionary = Steam.readP2PPacket(pkt_size, 0)
	_route(raw['remote_steam_id'], bytes_to_var(raw['data']))
	_drain_packets(n + 1)

# ── Routing (shared by both transports) ──────────────────────────────────────

var _route_logged := {}
func _route(sender: int, data: Dictionary) -> void:
	var type: String = data.get('_t', '')
	if not _route_logged.has(type):
		print("[Network._route] type='", type, "' sender=", sender, " handlers=", _handlers.keys())
		_route_logged[type] = true
	match type:
		'handshake':
			_refresh_members()
			emit_signal("peer_connected", sender, data.get('name', ''))
			if is_host:
				if _local_mode:
					_send_enet({'_t': 'world_seed', 'seed': world_seed}, true, sender)
				else:
					_send_raw({'_t': 'world_seed', 'seed': world_seed}, RELIABLE, sender)
		'world_seed':
			world_seed = data['seed']
			var world := _world()
			if world and world.has_method("receive_world_seed"):
				world.call("receive_world_seed", world_seed)
		_:
			if _handlers.has(type):
				for handler: Callable in _handlers[type]:
					handler.call(sender, data)
			else:
				print("[Network._route] WARNING: no handler for type='", type, "'")

func _send_handshake() -> void:
	_send_raw({'_t': 'handshake', 'name': Global.steam_username}, RELIABLE, 0)

func _world() -> Node:
	return get_tree().current_scene
