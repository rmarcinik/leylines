extends Node

var steam_id: int = 0
var steam_username: String = ""
var steam_active: bool = false

func _init() -> void:
	OS.set_environment("SteamAppID", str(480))
	OS.set_environment("SteamGameID", str(480))

func _ready() -> void:
	var init = Steam.steamInit()
	if init['status'] == 1:
		steam_active = true
		steam_id = Steam.getSteamID()
		steam_username = Steam.getPersonaName()
		print("Steam OK — %s  steam_id:%d" % [steam_username, steam_id])
	else:
		print("Steam init failed: ", init)

func _process(_delta: float) -> void:
	if steam_active:
		Steam.run_callbacks()
