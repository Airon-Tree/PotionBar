extends Control

var counts: Dictionary = {}
var selected: String = ""
var pot_list: Array[String] = []

@onready var materials_bar := $MarginContainer/VBoxContainer/MaterialsBar
@onready var material_buttons := materials_bar.get_children()
@onready var pot_button := $MarginContainer/VBoxContainer/CenterContainer/PotButton
@onready var make_button := $MarginContainer/VBoxContainer/ActionBar/MakeButton
@onready var clear_button := $MarginContainer/VBoxContainer/ActionBar/ClearButton
@onready var log := $MarginContainer/VBoxContainer/Log

# Bases & Process buttons
@onready var base_bar := $MarginContainer/VBoxContainer/BaseBar
@onready var base_btn_water := base_bar.get_node("Base_Water") as Button
@onready var base_btn_oil   := base_bar.get_node("Base_Oil") as Button
@onready var base_btn_wine  := base_bar.get_node("Base_Wine") as Button

@onready var process_bar := $MarginContainer/VBoxContainer/ProcessBar
@onready var grind_button := process_bar.get_node("GrindButton") as Button
@onready var distill_button := process_bar.get_node("DistillButton") as Button

# Potion result
@export var tex_health_potion: Texture2D
@export var tex_failed_potion: Texture2D
@onready var formula_list := $MarginContainer/VBoxContainer/FormulaPanel/ScrollContainer/FormulaList
@onready var potions_shelf := $MarginContainer/VBoxContainer/PotionsShelf
# Each recipe: name, base, grind, distill, materials{name->count}, texture
var RECIPES: Array = [
	{
		"name": "Health Potion",
		"base": "Water",
		"grind": true,
		"distill": false,
		"materials": { "Sage": 2, "Valerian": 1, "Warmwood": 1 },
		"texture": null  # filled in _ready from tex_health_potion
	},
	# Add more recipes here later...
]



var base_selected: String = ""
var do_grind: bool = false
var do_distill: bool = false

func _ready() -> void:
	# init counts and wire up signals
	counts.clear()
	for mb in material_buttons:
		counts[mb.material_name] = 0
		mb.set_count(0)
		mb.material_chosen.connect(_on_material_chosen)

	pot_button.pressed.connect(_on_pot_pressed)
	make_button.pressed.connect(_on_make_pressed)
	clear_button.pressed.connect(_on_clear_pressed)


	
	# Bases
	base_btn_water.toggle_mode = true
	base_btn_oil.toggle_mode   = true
	base_btn_wine.toggle_mode  = true

	base_btn_water.pressed.connect(func(): _on_base_pressed("Water"))
	base_btn_oil.pressed.connect(func(): _on_base_pressed("Oil"))
	base_btn_wine.pressed.connect(func(): _on_base_pressed("Wine"))

	# default base = Water
	_on_base_pressed("Water")

	# Process
	grind_button.toggle_mode = true
	distill_button.toggle_mode = true

	grind_button.pressed.connect(_on_grind_toggled)
	distill_button.pressed.connect(_on_distill_toggled)
	
	# assign textures into recipe structs
	for r in RECIPES:
		if r["name"] == "Health Potion":
			r["texture"] = tex_health_potion
			
	_refresh_formula_list()
	
	_log_intro()

# join helper
func _j(arr: Array[String], sep: String) -> String:
	var out := ""
	for i in range(arr.size()):
		if i > 0:
			out += sep
		out += arr[i]
	return out

func _refresh_formula_list() -> void:
	var lines: Array[String] = []
	lines.append("[b]Alchemical Formulas[/b]")
	for r in RECIPES:
		var parts: Array[String] = []
		parts.append("Base: %s" % r["base"])

		var proc: Array[String] = []
		if r["grind"]: proc.append("grind")
		if r["distill"]: proc.append("distill")
		parts.append("Process: " + (_j(proc, ", ") if proc.size() > 0 else "none"))

		var mats: Array[String] = []
		for k in r["materials"].keys():
			mats.append("%s×%d" % [k, int(r["materials"][k])])
		parts.append("Materials: " + _j(mats, ", "))

		lines.append("• [color=#88d]%s[/color] — %s" % [r["name"], _j(parts, " | ")])

	formula_list.clear()
	formula_list.append_text(_j(lines, "\n") + "\n")

func _on_base_pressed(which: String) -> void:
	
	base_selected = which

	base_btn_water.set_pressed_no_signal(which == "Water")
	base_btn_oil.set_pressed_no_signal(which == "Oil")
	base_btn_wine.set_pressed_no_signal(which == "Wine")
	_highlight_button(base_btn_water, which == "Water")
	_highlight_button(base_btn_oil,   which == "Oil")
	_highlight_button(base_btn_wine,  which == "Wine")
	_update_mix_line()

func _on_grind_toggled() -> void:
	do_grind = grind_button.button_pressed
	_highlight_button(grind_button, do_grind)
	_update_mix_line()

func _on_distill_toggled() -> void:
	do_distill = distill_button.button_pressed
	_highlight_button(distill_button, do_distill)
	_update_mix_line()

func _highlight_button(btn: Button, on: bool) -> void:
	# brighter when selected
	btn.modulate = Color(1,1,1,1) if on else Color(0.9,0.9,0.9,1)

func _on_material_chosen(name: String) -> void:
	selected = name
	for mb in material_buttons:
		mb.set_selected(mb.material_name == name)

func _on_pot_pressed() -> void:
	if selected == "":
		log.append_text("[i]Select a material first, then click the pot.[/i]\n")
		return
	counts[selected] += 1
	pot_list.append(selected)

	# update the matching button's counter
	for mb in material_buttons:
		if mb.material_name == selected:
			mb.set_count(counts[selected])
			break

	_update_mix_line()

func _on_make_pressed() -> void:
	var parts: Array[String] = []
	for k in counts.keys():
		if counts[k] > 0:
			parts.append("%s×%d" % [k, counts[k]])

	var summary := ", ".join(parts) if parts.size() > 0 else "nothing"
	var base_str := base_selected if base_selected != "" else "no base"
	var proc_parts: Array[String] = []
	if do_grind: proc_parts.append("grinded")
	if do_distill: proc_parts.append("distilled")
	var process_str := ", ".join(proc_parts) if proc_parts.size() > 0 else "no processing"

	# Try to match a recipe
	var r := _match_recipe()
	var result_name := "Failed Potion"
	var result_tex: Texture2D = tex_failed_potion
	
	if r.size() > 0:
		result_name = r["name"]
		if r["texture"] != null:
			result_tex = r["texture"]
	
	# Log the result
	var line := "Result: [b]%s[/b]  |  Base: %s  |  Process: %s  |  Materials: %s" % [result_name, base_str, process_str, summary]
	print(line)
	log.append_text(line + "\n")
	
	# Show the potion on the shelf (texture)
	_add_potion_to_shelf(result_tex, result_name)

func _add_potion_to_shelf(tex: Texture2D, name: String) -> void:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(64, 64)
	t.texture = tex
	t.tooltip_text = name
	potions_shelf.add_child(t)

func _on_clear_pressed() -> void:
	# reset data
	for k in counts.keys():
		counts[k] = 0
	pot_list.clear()
	selected = ""

	# reset UI
	for mb in material_buttons:
		mb.set_count(0)
		mb.set_selected(false)
		
		# reset base & process
	base_selected = ""
	base_btn_water.set_pressed_no_signal(false)
	base_btn_oil.set_pressed_no_signal(false)
	base_btn_wine.set_pressed_no_signal(false)
	_highlight_button(base_btn_water, false)
	_highlight_button(base_btn_oil, false)
	_highlight_button(base_btn_wine, false)

	do_grind = false
	do_distill = false
	grind_button.set_pressed_no_signal(false)
	distill_button.set_pressed_no_signal(false)
	_highlight_button(grind_button, false)
	_highlight_button(distill_button, false)

	log.text = ""
	_log_intro()
	
	for c in potions_shelf.get_children():
		c.queue_free()

func _log_intro() -> void:
	log.append_text("[i]Ready. Click a material to select it, then click the POT to add one unit. Press Make to print, Clear to reset.[/i]\n")

func _update_mix_line() -> void:
	var parts: Array[String] = []
	for k in counts.keys():
		if counts[k] > 0:
			parts.append("%s×%d" % [k, counts[k]])
	var summary := ", ".join(parts) if parts.size() > 0 else "empty"
	var base_str := base_selected if base_selected != "" else "no base"
	var proc_parts: Array[String] = []
	if do_grind: proc_parts.append("grinded")
	if do_distill: proc_parts.append("distilled")
	var process_str := ", ".join(proc_parts) if proc_parts.size() > 0 else "no processing"
	
	log.text = "Current mix: " + summary + "\n"
	
func _clean_counts_dict(src: Dictionary) -> Dictionary:
	# returns a new dictionary with only >0 entries
	var out: Dictionary = {}
	for k in src.keys():
		var v: int = int(src[k])
		if v > 0:
			out[k] = v
	return out

func _materials_equal(a: Dictionary, b: Dictionary) -> bool:
	# same keys and same counts
	if a.size() != b.size():
		return false
	for k in a.keys():
		if not b.has(k):
			return false
		if int(a[k]) != int(b[k]):
			return false
	return true

func _match_recipe() -> Dictionary:
	var mat_now := _clean_counts_dict(counts)
	for r in RECIPES:
		if base_selected != r["base"]:
			continue
		if do_grind != r["grind"]:
			continue
		if do_distill != r["distill"]:
			continue
		if _materials_equal(mat_now, r["materials"]):
			return r
	return {}  # no match
