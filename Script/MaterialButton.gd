extends Button

@export var material_name: String = "Herb"
@export var material_texture: Texture2D

var count: int = 0
signal material_chosen(name: String)

func _ready() -> void:
	toggle_mode = true  # shows “selected” state
	if material_texture:
		$Icon.texture = material_texture
	_update_count()

func _update_count() -> void:
	$Count.text = str(count)

func set_count(v: int) -> void:
	count = v
	_update_count()

func set_selected(on: bool) -> void:
	button_pressed = on
	# subtle highlight; change to a StyleBox/Theme later if you want
	modulate = Color(1,1,1,1) if on else Color(0.9,0.9,0.9,1)

func _pressed() -> void:
	emit_signal("material_chosen", material_name)
	
	
