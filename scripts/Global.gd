extends Node

var steam_id: int = 0
var steam_username: String = ""

func _init() -> void:
	OS.set_environment("SteamAppID", str(480))
	OS.set_environment("SteamGameID", str(480))

func _ready() -> void:
	pass
	#Steam.steamInit() #commented to not spam spacewar
	#steam_id = Steam.getSteamID()
	#steam_username = Steam.getPersonaName()

func _process(_delta: float) -> void:
	pass #Steam.run_callbacks()
