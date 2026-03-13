extends Node

# General-purpose Steam P2P message bus.
#
# Any node can participate in sync:
#   Network.register("my_type", _on_my_type)   # subscribe
#   Network.send("my_type", {key: value})       # broadcast
#   Network.send("my_type", {key: value}, true) # reliable broadcast
#   Network.send("my_type", {key: value}, true, steam_id) # targeted
#
# Handler signature: func _on_my_type(sender_id: int, data: Dictionary)

const UNRELIABLE := 0
const RELIABLE   := 2

# Structural signals — lobby and connection lifecycle
signal lobby_ready(lobby_id: int)
signal peer_connected(steam_id: int, username: String)
signal peer_disconnected(steam_id: int)

var is_host: bool = false
var lobby_id: int  = 0
var world_seed: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 10

var _handlers: Dictionary = {}  # String -> Array[Callable]

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.p2p_session_request.connect(_on_p2p_session_request)

func _process(_delta: float) -> void:
	if lobby_id > 0:
		_drain_packets()

# ── Public API ────────────────────────────────────────────────────────────────

func register(type: String, handler: Callable) -> void:
	if not _handlers.has(type):
		_handlers[type] = []
	_handlers[type].append(handler)

func unregister(type: String, handler: Callable) -> void:
	if _handlers.has(type):
		_handlers[type].erase(handler)

## Send a message to all peers (target_id=0) or a specific peer.
func send(type: String, data: Dictionary, reliable: bool = false, target_id: int = 0) -> void:
	if lobby_id == 0:
		return
	data['_t'] = type
	_send_raw(data, RELIABLE if reliable else UNRELIABLE, target_id)

func create_lobby() -> void:
	if lobby_id == 0:
		is_host = true
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_members_max)

func join_lobby(id: int) -> void:
	Steam.joinLobby(id)

# ── Lobby callbacks ───────────────────────────────────────────────────────────

func _on_lobby_created(connect: int, id: int) -> void:
	if connect == 1:
		lobby_id = id
		world_seed = randi()
		Steam.setLobbyData(lobby_id, 'name', 'Leylines')
		Steam.allowP2PPacketRelay(true)
		print("Lobby created: %d  seed: %d" % [lobby_id, world_seed])
		emit_signal("lobby_ready", lobby_id)

func _on_lobby_joined(id: int, _perms: int, _locked: int, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = id
		_refresh_members()
		# Announce existing members to game systems before sending our handshake
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
	# CHAT_MEMBER_STATE_CHANGE_LEFT=2, DISCONNECTED=4
	if chat_state == 2 or chat_state == 4:
		emit_signal("peer_disconnected", change_id)

func _refresh_members() -> void:
	lobby_members.clear()
	for i in range(Steam.getNumLobbyMembers(lobby_id)):
		var sid: int = Steam.getLobbyMemberByIndex(lobby_id, i)
		lobby_members.append({'steam_id': sid, 'name': Steam.getFriendPersonaName(sid)})

# ── P2P ───────────────────────────────────────────────────────────────────────

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

func _route(sender: int, data: Dictionary) -> void:
	var type: String = data.get('_t', '')
	match type:
		# Bootstrap messages handled internally; not forwarded to game handlers
		'handshake':
			_refresh_members()
			emit_signal("peer_connected", sender, data.get('name', ''))
			if is_host:
				# send world seed directly back to the joining peer
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

func _send_handshake() -> void:
	_send_raw({'_t': 'handshake', 'name': Global.steam_username}, RELIABLE, 0)

func _world() -> Node:
	return get_tree().current_scene
