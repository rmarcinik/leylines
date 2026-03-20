class_name Stars extends Node3D

@export var sky_radius: float = 500.0
@export var field_radius: float = 20.0
@export var star_light: float = 3.0

var _field_scene := preload("res://scenes/field.tscn")
var _atom_scene  := preload("res://scenes/atom.tscn")

# Constellations as (azimuth°, elevation°) pairs on the sky sphere.
# Each encodes a hint about how fields and atoms work.
var _constellations := [
	{
		# Stars converge toward a bright center — focal atoms pull inward
		"name":  "The Well",
		"hint":  "things fall toward the bright one",
		"color": Color(0.7, 0.9, 1.0),
		"stars": [[50,75], [50,58], [38,63], [62,63], [30,69], [70,69]],
	},
	{
		# Stars in a straight line — linear atoms carry things forward
		"name":  "The Current",
		"hint":  "aligned flow carries",
		"color": Color(0.6, 1.0, 0.8),
		"stars": [[120,32], [128,38], [136,44], [144,50], [152,56], [160,62]],
	},
	{
		# Eight stars in a circle — balanced radial pull sustains orbit
		"name":  "The Ring",
		"hint":  "equal pull in a circle sustains",
		"color": Color(1.0, 0.95, 0.6),
		"stars": [
			[240,69], [249,66], [254,55], [249,44],
			[240,41], [231,44], [226,55], [231,66],
		],
	},
	{
		# Bright head with curving tail — entering a field bends the path
		"name":  "The Comet",
		"hint":  "crossing a field bends the path",
		"color": Color(1.0, 0.8, 0.5),
		"stars": [[300,62], [314,52], [322,42], [328,33], [332,25]],
	},
	{
		# Two mirrored groups — opposing forces make stillness
		"name":  "The Scales",
		"hint":  "opposing forces make stillness",
		"color": Color(0.9, 0.7, 1.0),
		"stars": [
			[178,42], [172,50], [168,36],
			[202,42], [208,50], [212,36],
			[188,44], [192,44],
		],
	},
]

func _ready() -> void:
	for c in _constellations:
		_place_constellation(c)

func _place_constellation(data: Dictionary) -> void:
	var first := true
	for coords: Array in data.stars:
		var pos := _sphere_pos(coords[0], coords[1]) * sky_radius
		var energy := star_light * (1.5 if first else 1.0)
		_place_star(pos, data.color, energy)
		first = false

func _place_star(pos: Vector3, color: Color, energy: float) -> void:
	var field: Field = _field_scene.instantiate()
	field.default_radius = field_radius
	add_child(field)
	field.global_position = pos
	var atom: Atom = _atom_scene.instantiate()
	atom.light = energy
	atom.light_color = color
	field.add_child(atom)

func _sphere_pos(az_deg: float, el_deg: float) -> Vector3:
	var az := deg_to_rad(az_deg)
	var el := deg_to_rad(el_deg)
	return Vector3(cos(el) * sin(az), sin(el), cos(el) * cos(az))
