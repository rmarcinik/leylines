extends CanvasLayer

# Minimal lobby overlay — built entirely in code, no scene file needed.
# Shows Host/Join panel on start. Collapses to a corner lobby-ID label once in a lobby.

var _id_field: LineEdit
var _status_label: Label
var _hud_label: Label

func _ready() -> void:
	layer = 10
	_build_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Network.lobby_ready.connect(_on_lobby_ready)

# ── Build ─────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Dark overlay
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.72)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Centered column
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	col.custom_minimum_size = Vector2(340, 0)
	add_child(col)

	var title := Label.new()
	title.text = "LEYLINES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.WHITE)
	col.add_child(title)

	_add_gap(col, 32)

	var host_btn := Button.new()
	host_btn.text = "HOST"
	host_btn.pressed.connect(_on_host)
	_style_button(host_btn)
	col.add_child(host_btn)

	_add_gap(col, 16)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)

	_id_field = LineEdit.new()
	_id_field.placeholder_text = "lobby id"
	_id_field.custom_minimum_size = Vector2(200, 40)
	_id_field.add_theme_font_size_override("font_size", 18)
	row.add_child(_id_field)

	var join_btn := Button.new()
	join_btn.text = "JOIN"
	join_btn.pressed.connect(_on_join)
	_style_button(join_btn)
	row.add_child(join_btn)

	_add_gap(col, 24)

	# Divider
	var div := ColorRect.new()
	div.color = Color(0.3, 0.3, 0.3)
	div.custom_minimum_size = Vector2(280, 1)
	div.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	col.add_child(div)

	_add_gap(col, 16)

	var local_row := HBoxContainer.new()
	local_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(local_row)

	var local_host_btn := Button.new()
	local_host_btn.text = "LOCAL HOST"
	local_host_btn.pressed.connect(_on_local_host)
	local_host_btn.custom_minimum_size = Vector2(150, 40)
	local_host_btn.add_theme_font_size_override("font_size", 16)
	local_row.add_child(local_host_btn)

	var local_join_btn := Button.new()
	local_join_btn.text = "LOCAL JOIN"
	local_join_btn.pressed.connect(_on_local_join)
	local_join_btn.custom_minimum_size = Vector2(150, 40)
	local_join_btn.add_theme_font_size_override("font_size", 16)
	local_row.add_child(local_join_btn)

	_add_gap(col, 20)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	col.add_child(_status_label)

	# Corner HUD — shown after lobby is live
	_hud_label = Label.new()
	_hud_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_hud_label.position = Vector2(12, 12)
	_hud_label.add_theme_font_size_override("font_size", 14)
	_hud_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_hud_label.visible = false
	add_child(_hud_label)

func _style_button(btn: Button) -> void:
	btn.custom_minimum_size = Vector2(200, 48)
	btn.add_theme_font_size_override("font_size", 20)

func _add_gap(parent: Control, height: int) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, height)
	parent.add_child(gap)

# ── Actions ───────────────────────────────────────────────────────────────────

func _on_host() -> void:
	_status_label.text = "creating lobby..."
	Network.create_lobby()

func _on_join() -> void:
	var id := int(_id_field.text.strip_edges())
	if id == 0:
		_status_label.text = "enter a lobby id"
		return
	_status_label.text = "joining..."
	Network.join_lobby(id)

func _on_local_host() -> void:
	_status_label.text = "hosting locally on port %d..." % Network.LOCAL_PORT
	Network.create_local_lobby()

func _on_local_join() -> void:
	_status_label.text = "joining localhost:%d..." % Network.LOCAL_PORT
	Network.join_local_lobby()

func _on_lobby_ready(lobby_id: int) -> void:
	_hud_label.text = "lobby  %d" % lobby_id
	_hud_label.visible = true
	# Hide the overlay, restore mouse capture
	for child in get_children():
		if child != _hud_label:
			child.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
