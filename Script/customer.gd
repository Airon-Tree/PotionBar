extends Control

signal awaiting_potion(customer_index: int, day: int)
signal finished_day(day: int)

@onready var date_label: Label = $Date
@onready var portrait: TextureRect = $Portrait
@onready var name_label: Label = $Name
@onready var score_label: Label = $Score
@onready var dialog_text: RichTextLabel = $Dialogue/ScrollContainer/DialogText
@onready var scroll_container: ScrollContainer = $Dialogue/ScrollContainer

const CUSTOMER_INFOS = [
	{"name": "Customer1", "tex": preload("res://Art/customer1.png")},
	{"name": "Customer2", "tex": preload("res://Art/customer2.png")},
	{"name": "Customer3", "tex": preload("res://Art/customer3.png")},
]

var DIALOG_BANK: Dictionary = {
	1: {
		0: {
			"before": ["before1", "before2", "before3"],
			"before_special": ["You've heard about the market gossip, right?", "Maybe that will help."],
			"after": {
				"after1": ["after1-1", "after1-2", "after1-3"],
				"after2": ["after2-1", "after2-2", "after2-3"],
				"special": ["special1", "special2", "special3"]
			}
		},
		1: {
			"before": ["before1", "before2", "before3"],
			"before_special": ["They asked about the alchemist yesterday..."],
			"after": {
				"after1": ["after1-1", "after1-2", "after1-3"],
				"after2": ["after2-1", "after2-2", "after2-3"],
				"special": ["special1", "special2", "special3"]
			}
		},
		2: {
			"before": ["before1", "before2", "before3"],
			"after": {
				"after1": ["after1-1", "after1-2", "after1-3"],
				"after2": ["after2-1", "after2-2", "after2-3"],
				"special": ["special1", "special2", "special3"]
			}
		}
	},
	2: {
		0: {
			"before": ["before1", "before2", "before3"],
			"before_special": ["I may tell you more if you know how to please me."],
			"after": {
				"after1": ["after1-1", "after1-2", "after1-3"],
				"after2": ["after2-1", "after2-2", "after2-3"],
				"special": ["special1", "special2", "special3"]
			}
		},
		1: {
			"before": ["before1", "before2", "before3"],
			"after": {
				"after1": ["after1-1", "after1-2", "after1-3"],
				"after2": ["after2-1", "after2-2", "after2-3"],
				"special": ["special1", "special2", "special3"]
			}
		},
		2: {
			"before": ["before1", "before2", "before3"],
			"after": {
				"after1": ["after1-1", "after1-2", "after1-3"],
				"after2": ["after2-1", "after2-2", "after2-3"],
				"special": ["special1", "special2", "special3"]
			}
		}
	},
	3: {
		0: {
			"before": ["before1", "before2", "before3"],
			"after": {
				"after1": ["after1-1", "after1-2", "after1-3"],
				"after2": ["after2-1", "after2-2", "after2-3"],
				"special": ["special1", "special2", "special3"]
			}
		},
		1: {
			"before": ["before1", "before2", "before3"],
			"after": {
				"after1": ["after1-1", "after1-2", "after1-3"],
				"after2": ["after2-1", "after2-2", "after2-3"],
				"special": ["special1", "special2", "special3"]
			}
		},
		2: {
			"before": ["before1", "before2", "before3"],
			"after": {
				"after1": ["after1-1", "after1-2", "after1-3"],
				"after2": ["after2-1", "after2-2", "after2-3"],
				"special": ["special1", "special2", "special3"]
			}
		}
	}
}

var EXPECTED_POTIONS: Dictionary = {
	1: {
		0: {
			"Health Potion": {"after":"after2","score":100},
			"Failed Potion": {"after":"after1","score":50},
			"Special Potion": {"special":"special","score":150,"unlock_customers":[1]}
		},
		1: {
			"Health Potion": {"after":"after2","score":100},
			"Failed Potion": {"after":"after1","score":50},
			"Special Potion": {"special":"special","score":150}
		},
		2: {
			"Health Potion": {"after":"after2","score":100},
			"Failed Potion": {"after":"after1","score":50},
			"Special Potion": {"special":"special","score":150}
		}
	},
	2: {
		0: {
			"Health Potion": {"after":"after2","score":100},
			"Failed Potion": {"after":"after1","score":50},
			"Special Potion": {"special":"special","score":150}
		},
		1: {
			"Health Potion": {"after":"after2","score":100},
			"Failed Potion": {"after":"after1","score":50},
			"Special Potion": {"special":"special","score":150}
		},
		2: {
			"Health Potion": {"after":"after2","score":100},
			"Failed Potion": {"after":"after1","score":50},
			"Special Potion": {"special":"special","score":150}
		}
	},
	3: {
		0: {
			"Health Potion": {"after":"after2","score":100},
			"Failed Potion": {"after":"after1","score":50},
			"Special Potion": {"special":"special","score":150}
		},
		1: {
			"Health Potion": {"after":"after2","score":100},
			"Failed Potion": {"after":"after1","score":50},
			"Special Potion": {"special":"special","score":150}
		},
		2: {
			"Health Potion": {"after":"after2","score":100},
			"Failed Potion": {"after":"after1","score":50},
			"Special Potion": {"special":"special","score":150}
		}
	}
}

@export var default_after_key: String = "after1"
@export var line_interval_sec: float = 2.0
@export var transition_interval_sec: float = 1.0
@export var fade_duration_sec: float = 2.0

var _day: int = 1
var _idx: int = 0
var _total_days: int = 3
var _total_score: int = 0
var _waiting: bool = false
var _running: bool = false
var _fade_tween: Tween = null

var _unlocked_customers: Dictionary = {}
var _seen_specials: Dictionary = {}

func _ready() -> void:
	portrait.modulate = Color(portrait.modulate.r, portrait.modulate.g, portrait.modulate.b, 0.0)
	_update_day_label()
	_update_score_label()
	_start_customer_flow()

func notify_potion(potion_name: String) -> void:
	if not _waiting:
		return
	_waiting = false

	var info: Dictionary = _resolve_after_info(_day, _idx, potion_name)
	var lines: Array = []

	if info.has("special_key") and str(info["special_key"]) != "":
		lines = _get_special_lines(_day, _idx, str(info["special_key"]))
	elif str(info["after_key"]) == "special":
		lines = _get_special_lines(_day, _idx, "special")
	else:
		lines = _get_after_lines(_day, _idx, str(info["after_key"]))

	if info.has("unlock_customers"):
		var key = "%d:%d:%s" % [_day, _idx, potion_name]
		if not _seen_specials.has(key):
			_seen_specials[key] = true
			for cust in info["unlock_customers"]:
				var target_day = _day + 1
				if not _unlocked_customers.has(target_day):
					_unlocked_customers[target_day] = []
				if cust not in _unlocked_customers[target_day]:
					_unlocked_customers[target_day].append(cust)

	await _play_lines(lines)

	_total_score += int(info.get("score", 0))
	_update_score_label()

	await get_tree().create_timer(transition_interval_sec).timeout
	await _fade_out()
	
	if _day == _total_days and _idx == CUSTOMER_INFOS.size() - 1:
		emit_signal("finished_day", _day)
		return
	
	_clear_dialog()
	_next_customer_or_next_day()

func _start_customer_flow() -> void:
	if _running:
		return
	_running = true

	var info: Dictionary = CUSTOMER_INFOS[_idx]
	name_label.text = info["name"]
	portrait.texture = info["tex"]
	
	await _fade_in()

	_clear_dialog()
	var before_lines: Array = []

	if _unlocked_customers.has(_day) and _idx in _unlocked_customers[_day]:
		before_lines = _get_before_special_lines(_day, _idx)
	else:
		before_lines = _get_before_lines(_day, _idx)

	await _play_lines(before_lines)

	_waiting = true
	_running = false
	emit_signal("awaiting_potion", _idx, _day)

func _next_customer_or_next_day() -> void:
	_idx += 1
	if _idx >= CUSTOMER_INFOS.size():
		_idx = 0
		_day += 1
		_update_day_label()
		emit_signal("finished_day", _day - 1)
	_start_customer_flow()

func _update_day_label() -> void:
	if is_instance_valid(date_label):
		date_label.text = "Day %d" % _day

func _resolve_after_key(day: int, idx: int, potion_name: String) -> String:
	var day_map: Dictionary = EXPECTED_POTIONS.get(day, {})
	var cust_map: Dictionary = day_map.get(idx, {})
	if cust_map.has(potion_name):
		var entry = cust_map[potion_name]
		if typeof(entry) == TYPE_DICTIONARY:
			return String(entry.get("after", default_after_key))
		else:
			return String(entry)
	return default_after_key

func _get_before_lines(day: int, idx: int) -> Array:
	var d: Dictionary = DIALOG_BANK.get(day, {})
	var c: Dictionary = d.get(idx, {})
	if c.has("before"):
		return c["before"]
	return []

func _get_before_special_lines(day: int, idx: int) -> Array:
	var d: Dictionary = DIALOG_BANK.get(day, {})
	var c: Dictionary = d.get(idx, {})
	if c.has("before_special"):
		return c["before_special"]
	return _get_before_lines(day, idx)

func _get_after_lines(day: int, idx: int, after_key: String) -> Array:
	var d: Dictionary = DIALOG_BANK.get(day, {})
	var c: Dictionary = d.get(idx, {})
	if not c:
		return []
	if c.has("after"):
		var after: Dictionary = c["after"]
		if after.has(after_key):
			return after[after_key]
	return []

func _get_special_lines(day: int, idx: int, special_key: String) -> Array:
	var d: Dictionary = DIALOG_BANK.get(day, {})
	var c: Dictionary = d.get(idx, {})
	if not c:
		return []
	if c.has("special") and typeof(c["special"]) == TYPE_DICTIONARY:
		if c["special"].has(special_key):
			return c["special"][special_key]
	if c.has("after"):
		var after: Dictionary = c["after"]
		if after.has(special_key):
			return after[special_key]
		if after.has("special") and special_key == "special":
			return after["special"]
	if c.has("special") and typeof(c["special"]) == TYPE_ARRAY and special_key == "special":
		return c["special"]
	return []

func _clear_dialog() -> void:
	dialog_text.clear()
	_autoscroll_deferred()

func _append_dialog(line: String) -> void:
	if line == "":
		return
	dialog_text.append_text(line + "\n")
	_autoscroll_deferred()

func _autoscroll_deferred() -> void:
	await get_tree().process_frame
	scroll_container.scroll_vertical = 999999

func _play_lines(lines: Array) -> void:
	for i in range(lines.size()):
		var l: String = str(lines[i])
		_append_dialog(l)
		if i < lines.size() - 1:
			await get_tree().create_timer(line_interval_sec).timeout

func _resolve_after_info(day: int, idx: int, potion_name: String) -> Dictionary:
	var day_map: Dictionary = EXPECTED_POTIONS.get(day, {})
	var cust_map: Dictionary = day_map.get(idx, {})

	if cust_map.has(potion_name):
		var entry: Variant = cust_map[potion_name]
		if typeof(entry) == TYPE_DICTIONARY:
			var ak: String = String(entry.get("after", ""))
			var sk: String = String(entry.get("special", ""))
			var sc: int = int(entry.get("score", 0))
			var unlocks: Array = entry.get("unlock_customers", [])
			var after_key_val: String = ak if ak != "" else default_after_key
			return {"after_key": after_key_val, "special_key": sk, "score": sc, "unlock_customers": unlocks}
		else:
			var ak2: String = String(entry)
			return {"after_key": ak2, "special_key": "", "score": 0, "unlock_customers": []}

	return {"after_key": default_after_key, "special_key": "", "score": 0, "unlock_customers": []}

func _update_score_label() -> void:
	if is_instance_valid(score_label):
		score_label.text = "Score: %d" % _total_score

func _kill_fade_tween() -> void:
	if _fade_tween != null:
		_fade_tween.kill()
		_fade_tween = null

func _fade_to(alpha: float) -> void:
	_kill_fade_tween()
	_fade_tween = create_tween()
	_fade_tween.tween_property(portrait, "modulate:a", alpha, fade_duration_sec)
	await _fade_tween.finished

func _fade_in() -> void:
	if portrait.modulate.a < 0.001:
		portrait.modulate = Color(portrait.modulate.r, portrait.modulate.g, portrait.modulate.b, 0.0)
	await _fade_to(1.0)

func _fade_out() -> void:
	await _fade_to(0.0)
