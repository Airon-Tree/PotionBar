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
	{"name": "Village Guardian", "tex": preload("res://Art/customer1.png")},
	{"name": "Village Elder", "tex": preload("res://Art/customer2.png")},
	{"name": "Traveling Librarian", "tex": preload("res://Art/customer3.png")},
]

# Track customer states to create connections
var _customer_states: Dictionary = {
	"guardian": {"last_potion_quality": "", "needs_help": true},
	"elder": {"last_potion_quality": "", "worried_about_guardian": false},
	"librarian": {"researching": "", "interested_in_guardian": false}
}

var DIALOG_BANK: Dictionary = {
	1: {
		0: { # Village Guardian - Day 1
			"before": [
				"Morning! I heard you finally passed your master's trial—congrats! My job keeping the village safe totally relies on your potions.",
				"I spotted fresh goblin footprints near the eastern ridge—deep ones, like they're carrying heavy equipment. That's never a good sign.",
				"Tonight I'll track them to their nest while they sleep. Could you brew me a [color=yellow]Refresh Potion[/color]? If I doze off during surveillance, we could miss crucial intel.",
				"[i](She needs to stay alert, but I wonder if there's something even more effective than a standard Refresh Potion...)[/i]"
			],
			"after": {
				"good": [
					"Perfect clarity! This should keep me sharp through the night.",
					"By the way, I saw the Elder struggling with her flour sacks earlier. Maybe check if she needs something for her joints?",
					"And that librarian... he was studying old maps near the mill. Knowledgeable types like him often have insights we practical folks miss."
				],
				"bad": [
					"This looks... weaker than I hoped. The sediment worries me.",
					"Speaking of worries, the Elder mentioned her arthritis is acting up with this cold snap. She'd never ask, but she could use something warming.",
					"The librarian might know about purification methods—he seems the scholarly type."
				],
				"special": [ # Energy Potion (stronger alternative)
					"Whoa! This is more potent than a standard Refresh Potion! The energy just radiates through me!",
					"You know, the Elder was talking about old remedies yesterday. Said some could 'clear the mind as well as the lungs.' Maybe she knows something we don't.",
					"With this level of alertness, I should pay more attention to what the others are noticing too."
				]
			}
		},
		1: { # Village Elder - Day 1
			"before": {
				"default": [
					"Ah, good day to you, dear. May the gods watch over your path.",
					"Our young guardian rushed by earlier—all business, that one. When I was her age, we dealt with threats using more than just brute force.",
					"This autumn chill settles deep in old bones. A simple [color=yellow]Flu Potion[/color] would be most welcome, though Old John sometimes added [color=orange]extra Sage[/color] for particularly harsh seasons.",
					"[i](She seems to be hinting that standard recipes can be enhanced for better results...)[/i]"
				],
				"guardian_good": [
					"I saw our guardian heading out with purpose. Your potion must have given her confidence.",
					"She stopped to help me with my market basket—good heart under all that armor. Sometimes the strongest protection comes from clever thinking, not strong arms.",
					"A [color=yellow]Flu Potion[/color] for my aches, but my mind wanders to the stories our librarian friend might preserve about days like these.",
					"[i](She's connecting different types of knowledge—maybe there's wisdom in combining approaches?)[/i]"
				],
				"guardian_bad": [
					"Child, the guardian looked uneasy. I offered her some of my honey biscuits—comfort food helps steady nerves.",
					"She mentioned the librarian was studying old battle tactics. You know, in my day, we'd sometimes enhance simple traps with... [color=orange]stronger persuasions[/color].",
					"My [color=yellow]Flu Potion[/color] can wait—if she fails her scout, we'll need remedies that do more than just warm old bones.",
					"[i](She's suggesting we might need more aggressive solutions than standard potions...)[/i]"
				]
			},
			"after": {
				"good": [
					"Excellent work! The balance of warmth and clarity is perfect.",
					"You should share your technique with the librarian—he's always seeking 'living knowledge' as he calls it.",
					"And tell our guardian that old bones still remember things—sometimes the right mixture at the right time saves more than any sword swing."
				],
				"bad": [
					"The color is off, but the effort is appreciated.",
					"Don't be discouraged. Even the librarian's precious books contain failed experiments that led to great discoveries.",
					"Sometimes the simplest solutions work best—like proper trap placement with the right... enhancements."
				],
				"special": [ # Cure Potion (enhanced flu treatment)
					"Blessed stars! This has the golden hue of Old John's master recipes! The extra Valerian makes all the difference!",
					"This isn't just a Flu Potion—it's a proper restorative! The librarian must record this innovation!",
					"Our guardian would appreciate how thinking beyond the obvious can lead to remarkable results."
				]
			}
		},
		2: { # Traveling Librarian - Day 1
			"before": {
				"default": [
					"Ah, so this is Old John's successor. Your master understood that the best potions serve multiple purposes.",
					"The Elder was telling me fascinating folk remedies this morning. She mentioned some potions can be 'adapted for modern needs' with the right adjustments.",
					"A standard [color=yellow]Health Potion[/color] would suffice, though I've read accounts where adding [color=orange]extra Warmwood[/color] created remarkable resilience.",
					"[i](He's directly suggesting an enhancement to the standard Health Potion formula...)[/i]"
				],
				"elder_mentioned": [
					"The Elder's stories about past conflicts match patterns in my oldest texts. She mentioned 'creative solutions' being as important as strong ones.",
					"Historical records show that the most successful alchemists understand intent over instruction. They brew what's needed, not just what's asked.",
					"A robust [color=yellow]Health Potion[/color]—one that could handle more than simple scrapes if your insight suggests [color=orange]enhancements[/color].",
					"[i](He's encouraging you to think beyond the basic request...)[/i]"
				],
				"guardian_danger": [
					"The guardian's tension is palpable. Single defenders against hordes rarely end well in the histories.",
					"The Elder has the right idea—sometimes prevention beats confrontation. A properly enhanced potion can deter where force fails.",
					"Brew something strong. The old texts speak of potions that do more than heal—they [color=orange]fortify[/color].",
					"[i](He's clearly suggesting you should enhance the Health Potion for defensive capabilities...)[/i]"
				]
			},
			"after": {
				"good": [
					"Remarkable craftsmanship! The viscosity suggests excellent ingredient integration.",
					"The Elder would appreciate how you've balanced the traditional with the practical.",
					"Our guardian could benefit from understanding that sometimes the best defense is a well-brewed offense."
				],
				"bad": [
					"The separation concerns me, but the intent is clear.",
					"Even the Elder's famous recipes evolved through experimentation. Each attempt teaches something.",
					"Don't limit yourself to standard formulas. The greatest discoveries come from understanding what a situation truly needs."
				],
				"special": [ # Strong Potion (enhanced health)
					"Astounding! You've created something beyond a simple Health Potion! The extra Warmwood creates remarkable fortification!",
					"This matches descriptions of ancient guardian elixirs! The Elder would recognize this as proper 'battle-ready' brewing!",
					"With innovation like this, you could create potions that serve multiple strategic purposes!"
				]
			}
		}
	},
	2: {
		0: { # Village Guardian - Day 2
			"before": {
				"good": [
					"Your potion worked perfectly! I found their main cave... and it's worse than we imagined.",
					"The Elder was right about the eastern ridge—her knowledge of the land saved me hours of searching.",
					"And that librarian... his maps showed cave systems I didn't know existed. He mentioned something about '[color=orange]area denial[/color]' strategies from old texts.",
					"I'm setting trap lines tonight—I need another [color=yellow]Refresh Potion[/color] to maintain watch, unless you have any... [color=orange]creative ideas[/color] for dealing with groups.",
					"[i](She's openly asking for alternative approaches beyond simple alertness...)[/i]"
				],
				"bad": [
					"I barely made it back. Dozed off for a moment and they nearly caught me.",
					"The Elder noticed my limp and gave me a poultice from her garden. She muttered something about 'needing more than watchfulness'.",
					"The librarian's texts mentioned goblin adaptability. Maybe we need to adapt our approach too.",
					"I'm rigging every trap I know, but I need something more reliable this time. Maybe something that [color=orange]works while I sleep[/color]?",
					"[i](She's desperate for a solution that doesn't rely solely on her vigilance...)[/i]"
				],
				"elder_warned": [
					"The Elder got me thinking... she mentioned old methods where traps did more than just catch.",
					"Turns out the librarian has scrolls about '[color=orange]persuasive defenses[/color].' Between her memory and his books, they're onto something.",
					"I still need surveillance capability, but I'm definitely open to... [color=orange]enhanced solutions[/color] for the traps themselves.",
					"[i](She's directly hinting at using poison on her traps as an alternative strategy...)[/i]"
				]
			},
			"after": {
				"good": [
					"Solid work! This should keep me alert through the night watch.",
					"I'll check with the Elder about the best placements—she knows these woods better than anyone.",
					"And maybe the librarian has something about behavioral patterns. His historical perspective is surprisingly practical."
				],
				"bad": [
					"It'll have to do. I'll just have to check the traps more frequently.",
					"The Elder's poultice is helping my leg at least. Different kinds of healing, I suppose.",
					"See you at dawn... hopefully."
				],
				"special": [ # Poison Potion
					"You brilliant alchemist! This is exactly what the Elder and librarian were hinting at!",
					"Poison on the traps means they'll neutralize themselves! No more all-night watches!",
					"This is the kind of strategic thinking that wins campaigns! Between your potions, the Elder's wisdom, and the librarian's knowledge, we might just survive this!"
				]
			}
		},
		1: { # Village Elder - Day 2
			"before": {
				"guardian_good": [
					"The guardian actually smiled this morning! Your potions are working miracles.",
					"She asked me about the old ways of enhancing simple defenses. Young people rediscovering old wisdom warms my heart.",
					"The librarian has been helping her understand that knowledge can be a weapon too. Strange friendship, but good for both.",
					"An [color=yellow]Energy Potion[/color] for the baking, though if you feel inspired to enhance it with [color=orange]extra Comfrey[/color], I wouldn't say no.",
					"[i](She's specifically mentioning an ingredient that could enhance the Energy Potion...)[/i]"
				],
				"guardian_struggling": [
					"Oh child, the shadows under her eyes tell the whole story.",
					"I've been teaching her that sometimes the best strength comes from cleverness, not muscle.",
					"The librarian found accounts where simple potions, properly enhanced, turned the tide of entire skirmishes.",
					"An [color=yellow]Energy Potion[/color]—and if your insight suggests something [color=orange]more potent[/color], I trust your judgment.",
					"[i](She's explicitly giving you permission to enhance beyond the basic request...)[/i]"
				],
				"default": [
					"The millstone turns regardless of goblins or gods.",
					"Our guardian was asking about strategic thinking. She's learning that battles are won with minds as well as swords.",
					"The librarian says my folk wisdom matches chemical principles. Funny how different kinds of knowledge converge.",
					"An [color=yellow]Energy Potion[/color] would help, though Old John sometimes made a version with [color=orange]extra Poppy[/color] that could fuel an entire day's work.",
					"[i](She's sharing specific enhancement knowledge from your master...)[/i]"
				]
			},
			"after": {
				"good": [
					"Ah, the warmth spreads just right! You've mastered the balance.",
					"I'll bake extra honey biscuits—the guardian has developed quite a taste for them.",
					"The librarian asked for the recipe. Says collaboration between practical and scholarly wisdom creates the best results."
				],
				"bad": [
					"The aftertaste is bitter, much like our prospects.",
					"Still, the guardian says even imperfect tools can save lives if used with wisdom.",
					"The librarian would say every attempt advances understanding. I say sometimes you need to trust your instincts about what's truly needed."
				],
				"special": [ # Refresh Potion (enhanced energy)
					"By the eternal flame! This isn't just energy—it's pure vitality! The extra Poppy makes all the difference!",
					"This could power the morning watch and the evening baking! The guardian should try this for endurance!",
					"You're not just following recipes—you're understanding what each situation truly requires!"
				]
			}
		}
	}
}

var EXPECTED_POTIONS: Dictionary = {
	1: {
		0: { # Guardian wants Refresh Potion
			"Refresh Potion": {"after":"good","score":100},
			#"Failed Potion": {"after":"bad","score":50},
			"Energy Potion": {"after":"special","score":150}  # Enhanced alternative
		},
		1: { # Elder wants Flu Potion
			"Flu Potion": {"after":"good","score":100},
			#"Failed Potion": {"after":"bad","score":50},
			"Cure Potion": {"after":"special","score":150}  # Enhanced alternative
		},
		2: { # Librarian wants Health Potion
			"Health Potion": {"after":"good","score":100},
			#"Failed Potion": {"after":"bad","score":50},
			"Strong Potion": {"after":"special","score":150}  # Enhanced alternative
		}
	},
	2: {
		0: { # Guardian wants Refresh Potion (or Poison for special)
			"Refresh Potion": {"after":"good","score":100},
			#"Failed Potion": {"after":"bad","score":50},
			"Poison": {"after":"special","score":150}  # Strategic alternative
		},
		1: { # Elder wants Energy Potion
			"Energy Potion": {"after":"good","score":100},
			#"Failed Potion": {"after":"bad","score":50},
			"Refresh Potion": {"after":"special","score":150}  # Enhanced alternative
		},
		2: { # Librarian wants Health/Strong Potion
			"Health Potion": {"after":"good","score":100},
			#"Failed Potion": {"after":"bad","score":50},
			"Strong Potion": {"after":"special","score":150}  # Enhanced alternative
		}
	},
	3: {
		0: { # Guardian wants Strong Potion for final fight
			"Strong Potion": {"after":"good","score":100},
			#"Failed Potion": {"after":"bad","score":50},
			"Energy Potion": {"after":"special","score":150}  # Enhanced alternative
		},
		1: { # Elder wants Health Potion for Guardian
			"Health Potion": {"after":"good","score":100},
			#"Failed Potion": {"after":"bad","score":50},
			"Cure Potion": {"after":"special","score":150}  # Enhanced alternative
		},
		2: { # Librarian wants Cure Potion for aftermath
			"Cure Potion": {"after":"good","score":100},
			#"Failed Potion": {"after":"bad","score":50},
			"Flu Potion": {"after":"special","score":150}  # Enhanced alternative
		}
	}
}

@export var default_after_key: String = "good"
@export var line_interval_sec: float = 2.0
@export var transition_interval_sec: float = 5.0
@export var fade_duration_sec: float = 2.0

var _day: int = 1
var _idx: int = 0
var _total_days: int = 3
var _total_score: int = 0
var _waiting: bool = false
var _running: bool = false
var _fade_tween: Tween = null

func _ready() -> void:
	portrait.modulate = Color(portrait.modulate.r, portrait.modulate.g, portrait.modulate.b, 0.0)
	_update_day_label()
	_update_score_label()
	
	# Initialize comprehensive customer states
	_customer_states = {
		"guardian": {
			"last_potion_quality": "",
			"needs_help": true,
			"received_enhanced_help": false,
			"used_special_strategy": false,
			"has_community_support": false,
			"has_research_support": false,
			"excellent_preparation": false
		},
		"elder": {
			"last_potion_quality": "",
			"worried_about_guardian": false,
			"shared_wisdom": false,
			"shared_strategic_wisdom": false,
			"strategic_advice_worked": false,
			"actively_supporting": false,
			"provided_crucial_support": false
		},
		"librarian": {
			"researching_strategies": false,
			"interested_in_guardian": false,
			"research_validated": false,
			"documented_success": false
		}
	}
	
	_start_customer_flow()

func notify_potion(potion_name: String) -> void:
	if not _waiting:
		return
	_waiting = false

	# Update customer states based on potion given
	var info: Dictionary = _resolve_after_info(_day, _idx, potion_name)
	var after_key: String = info["after_key"]
	
	# Track potion quality and interactions for narrative connections
	match _idx:
		0: # Guardian
			_customer_states["guardian"]["last_potion_quality"] = after_key
			
			if _day == 1:
				if after_key == "bad":
					_customer_states["elder"]["worried_about_guardian"] = true
				elif after_key == "special":
					_customer_states["guardian"]["received_enhanced_help"] = true
					
			elif _day == 2:
				if after_key == "special" and potion_name == "Poison":
					_customer_states["guardian"]["used_special_strategy"] = true
					_customer_states["elder"]["strategic_advice_worked"] = true
					_customer_states["librarian"]["research_validated"] = true
				elif after_key == "bad":
					_customer_states["guardian"]["had_setback"] = true
					
			elif _day == 3:
				if after_key == "special":
					_customer_states["guardian"]["excellent_preparation"] = true
				elif after_key == "bad":
					_customer_states["guardian"]["inadequate_preparation"] = true
				
		1: # Elder
			_customer_states["elder"]["last_potion_quality"] = after_key
			
			if _day == 1:
				if after_key == "good" and _customer_states["guardian"]["last_potion_quality"] == "bad":
					_customer_states["elder"]["worried_about_guardian"] = true
				elif after_key == "special":
					_customer_states["elder"]["shared_strategic_wisdom"] = true
					_customer_states["librarian"]["researching_strategies"] = true
				elif after_key == "bad":
					_customer_states["elder"]["had_potion_issues"] = true
					
			elif _day == 2:
				if after_key == "special":
					_customer_states["elder"]["actively_supporting"] = true
					_customer_states["guardian"]["has_community_support"] = true
				elif after_key == "bad":
					_customer_states["elder"]["struggling_to_help"] = true
					
			elif _day == 3:
				if after_key == "special":
					_customer_states["elder"]["provided_crucial_support"] = true
				elif after_key == "bad":
					_customer_states["elder"]["limited_help"] = true
				
		2: # Librarian
			_customer_states["librarian"]["last_potion_quality"] = after_key
			
			if _day == 1:
				if after_key == "special":
					_customer_states["librarian"]["researching_strategies"] = true
					_customer_states["elder"]["shared_wisdom"] = true
				elif _customer_states["guardian"]["needs_help"]:
					_customer_states["librarian"]["interested_in_guardian"] = true
				elif after_key == "bad":
					_customer_states["librarian"]["had_research_setback"] = true
					
			elif _day == 2:
				if after_key == "special":
					_customer_states["librarian"]["research_validated"] = true
					_customer_states["guardian"]["has_research_support"] = true
				elif after_key == "bad":
					_customer_states["librarian"]["research_challenges"] = true
					
			elif _day == 3:
				if after_key == "special":
					_customer_states["librarian"]["documented_success"] = true
				elif after_key == "bad":
					_customer_states["librarian"]["incomplete_research"] = true

	var lines: Array = _get_after_lines(_day, _idx, after_key)
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
	var before_lines: Array = _get_before_lines(_day, _idx)

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
		return String(cust_map[potion_name])
	return default_after_key




func _get_before_lines(day: int, idx: int) -> Array:
	var d: Dictionary = DIALOG_BANK.get(day, {})
	var c: Dictionary = d.get(idx, {})
	
	if not c or not c.has("before"):
		return ["Hello! I need a potion."]
	
	var before_data = c["before"]
	
	# Handle array case (simple dialogue) - Only Guardian Day 1 uses this format
	if typeof(before_data) == TYPE_ARRAY:
		return before_data
	
	# Handle dictionary case (contextual dialogue)
	if typeof(before_data) == TYPE_DICTIONARY:
		# Determine which contextual dialogue to use based on previous outcomes
		match idx:
			0: # Guardian
				if day == 2:
					# Day 2 Guardian - check if Elder gave strategic advice
					if _customer_states["elder"]["shared_strategic_wisdom"]:
						return before_data.get("elder_warned", before_data.get("default", ["I need a potion for my mission."]))
					# Check previous potion quality
					var prev_quality = _customer_states["guardian"]["last_potion_quality"]
					if prev_quality == "good":
						return before_data.get("good", before_data.get("default", ["The scouting went well."]))
					elif prev_quality == "bad":
						return before_data.get("bad", before_data.get("default", ["I had some trouble..."]))
				elif day == 3:
					# Day 3 Guardian - check if special strategies were used
					if _customer_states["guardian"]["used_special_strategy"]:
						return before_data.get("special", before_data.get("default", ["Ready for the final push."]))
					var prev_quality = _customer_states["guardian"]["last_potion_quality"]
					if prev_quality == "good":
						return before_data.get("good", before_data.get("default", ["We're making progress."]))
					elif prev_quality == "bad":
						return before_data.get("bad", before_data.get("default", ["We need to finish this."]))
				
			1: # Elder
				if day == 1:
					# Day 1 Elder - check guardian's initial state
					if _customer_states["guardian"]["last_potion_quality"] == "good":
						return before_data.get("guardian_good", before_data.get("default", ["Good day, dear."]))
					elif _customer_states["guardian"]["last_potion_quality"] == "bad":
						return before_data.get("guardian_bad", before_data.get("default", ["I'm concerned..."]))
				elif day == 2:
					# Day 2 Elder - check guardian's progress and librarian's involvement
					if _customer_states["guardian"]["last_potion_quality"] == "good":
						return before_data.get("guardian_good", before_data.get("default", ["Our guardian seems well."]))
					elif _customer_states["guardian"]["last_potion_quality"] == "bad":
						return before_data.get("guardian_struggling", before_data.get("default", ["Our guardian needs support."]))
					elif _customer_states["librarian"]["researching_strategies"]:
						return before_data.get("default", ["The librarian has interesting ideas..."])
				elif day == 3:
					# Day 3 Elder - final preparations
					if _customer_states["guardian"]["last_potion_quality"] == "good":
						return before_data.get("guardian_confident", before_data.get("default", ["She looks ready."]))
					elif _customer_states["guardian"]["last_potion_quality"] == "bad":
						return before_data.get("guardian_worried", before_data.get("default", ["I worry for her."]))
				
			2: # Librarian
				if day == 1:
					# Day 1 Librarian - initial observations
					if _customer_states["elder"]["shared_wisdom"]:
						return before_data.get("elder_mentioned", before_data.get("default", ["The Elder has wisdom..."]))
					elif _customer_states["guardian"]["needs_help"]:
						return before_data.get("guardian_danger", before_data.get("default", ["The situation concerns me..."]))
				elif day == 2:
					# Day 2 Librarian - ongoing research
					if _customer_states["guardian"]["last_potion_quality"] == "good":
						return before_data.get("guardian_success", before_data.get("default", ["Progress is being made."]))
					elif _customer_states["guardian"]["last_potion_quality"] == "bad":
						return before_data.get("guardian_struggle", before_data.get("default", ["The challenges continue."]))
					elif _customer_states["elder"]["shared_strategic_wisdom"]:
						return before_data.get("default", ["Collaboration shows promise..."])
				elif day == 3:
					# Day 3 Librarian - final analysis
					if _customer_states["elder"]["actively_supporting"]:
						return before_data.get("elder_concerned", before_data.get("default", ["The community prepares..."]))
					elif _customer_states["guardian"]["used_special_strategy"]:
						return before_data.get("final_preparations", before_data.get("default", ["The moment approaches..."]))
		
		# Fallback to default dialogue for current day
		return before_data.get("default", ["What can you brew for me today?"])
	
	# Final fallback
	return ["I need your help with a potion."]

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

	# If the potion is explicitly listed in expected potions, use its outcome
	if cust_map.has(potion_name):
		var entry: Variant = cust_map[potion_name]
		if typeof(entry) == TYPE_DICTIONARY:
			var sc: int = int(entry.get("score", 0))
			var ak: String = String(entry.get("after", "bad"))  # Default to bad if missing
			return {"after_key": ak, "score": sc}
		else:
			var ak2: String = String(entry)
			return {"after_key": ak2, "score": 0}

	# ANY potion not explicitly listed is treated as "Failed Potion"
	return {"after_key": "bad", "score": 50}

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
