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
				"Morning! Congrats on passing your master's trial—the village relies on your potions for protection.",
				"Fresh goblin footprints near the eastern ridge... deep ones, like they're carrying heavy equipment. Never a good sign.",
				"I'm tracking them to their nest tonight. Could you brew me a [color=yellow]Refresh Potion[/color]? Dozing off during surveillance could cost us crucial intel.",
				"[i](She needs to stay alert, but I wonder if there's something more effective than a standard Refresh Potion...)[/i]"
			],
			"after": {
				"good": [
					"Perfect clarity! This should keep me sharp.",
				],
				"bad": [
					"This looks... weaker than I hoped. The sediment worries me.",
				],
				"special": [ # Energy Potion (stronger alternative)
					"Whoa! More potent than a standard Refresh Potion! Energy radiates through me!",
					"With this alertness, I should be able pay more attention to what others aren't noticing.",
					"The Elder was struggling with flour sacks earlier—her health has been declining and the weather is not helping. Old John sometimes added [color=orange]extra Valerian[/color] for harsh seasons.",
				]
			}
		},
		1: { # Village Elder - Day 1
			"before": {
				"default": [
					"Good day, dear. May the gods watch over your path.",
					"Our guardian rushed by earlier—all business. When I was her age, we used more than brute force.",
					"In my day, we enhanced simple traps with... [color=orange]lethal elements[/color].",
					"This autumn chill settles deep. A [color=yellow]Flu Potion[/color] would help"
				],
				"guardian_good": [
					"Our guardian headed out with purpose. Your potion must have given her confidence.",
					"This autumn chill settles deep. A [color=yellow]Flu Potion[/color] would help"
				],
				"guardian_bad": [
					"Child, the guardian looked uneasy. I offered honey biscuits—comfort food steadies nerves.",
					"This autumn chill settles deep. A [color=yellow]Flu Potion[/color] would help, though Old John sometimes added [color=orange]extra Valerian[/color] for harsh seasons.",
					"Though if the guardian fails her scout, we'll need more than warm bones.",
				]
			},
			"after": {
				"good": [
					"Excellent work! Perfect balance of warmth and clarity.",
					"Tell our guardian that old bones remember—the right mixture saves more than any sword swing."
				],
				"bad": [
					"The color is off, but appreciated.",
					"Don't be discouraged. Even the librarian's books contain failed experiments that led to discoveries.",
				],
				"special": [ # Cure Potion (enhanced flu treatment)
					"Blessed stars! This has the golden hue of Old John's master recipes! The extra Valerian makes all the difference! Old John also mentioned adding [color=orange]extra Poppy and Warmwood[/color] to his Health potions creates remarkable results.",
					"Our guardian would appreciate thinking beyond the obvious."
				]
			}
		},
		2: { # Traveling Librarian - Day 1
			"before": {
				"default": [
					"Ah, Old John's successor. Your master understood that best potions serve multiple purposes.",
					"I'm currently behind on some manuscripts, a [color=yellow]Refresh Potion[/color] would suffice",
				],
				"elder_mentioned": [
					"The Elder's stories match my oldest texts. She mentioned 'creative solutions' being crucial.",
					"Historical records show successful alchemists understand intent over instruction. Brew what's needed, not just asked.",
					"Brew something strong. Old texts speak of potions that do more than heal—they [color=orange]fortify[/color].",
				],
				"guardian_danger": [
					"The guardian's tension is palpable. Single defenders rarely fare well in histories.",
					"The Elder has the right idea—prevention beats confrontation. Enhanced potions deter where force fails.",
				]
			},
			"after": {
				"good": [
					"Remarkable craftsmanship! Viscosity suggests excellent integration.",
				],
				"bad": [
					"The separation concerns me, but intent is clear.",
					"Even the Elder's recipes evolved through experimentation. Each attempt teaches.",
					"Don't limit to standard formulas. Greatest discoveries understand true needs."
				],
				"special": [ # Strong Potion (enhanced health)
					"Astounding! Beyond a simple Health Potion! The extra Warmwood creates remarkable fortification!",
					"With this innovation, you could create multi-purpose potions!"
				]
			}
		}
	},
	2: {
		0: { # Village Guardian - Day 2
			"before": {
				"default": [
					"The goblin nest is larger than expected—they're organized, not just scavengers.",
					"I need to set perimeter traps before nightfall. A [color=yellow]Refresh Potion[/color] for the long watch ahead.",
				],
				"good": [
					"Your potion worked! Found their main cave... the situation is worse than imagined.",
					"The Elder was right about the eastern ridge—her knowledge saved me hours.",
					"Setting trap lines tonight—need another [color=yellow]Refresh Potion[/color], unless you have... [color=orange]creative ideas[/color] for groups.",
				],
				"bad": [
					"Barely made it back. Dozed off and they nearly caught me.",
					"The Elder noticed my limp—gave me a garden poultice.",
				],
				"elder_warned": [
					"The Elder got me thinking... old methods where traps did more than catch.",
				]
			},
			"after": {
				"good": [
					"Solid work! Should keep me alert through night watch.",
					"I'll check with the Elder about placements—she knows these woods best.",
					"Maybe the librarian has behavioral patterns. Historical perspective is practical."
				],
				"bad": [
					"It'll have to do. Just check traps more frequently.",
					"The Elder's poultice helps my leg. Different healings, I suppose.",
					"See you at dawn... hopefully."
				],
				"special": [ # Poison Potion
					"Brilliant! Exactly what they hinted at!",
					"Poison on traps means they neutralize themselves! No more all-night watches!",
					"This strategic thinking wins campaigns! Between your potions, Elder's wisdom, and librarian's knowledge, we might survive!"
				]
			}
		},
		1: { # Village Elder - Day 2
			"before": {
				"default": [
					"The wind carries troubling sounds from the eastern ridge tonight.",
					"Our guardian prepares for another dangerous night. She carries too much weight for one pair of shoulders.",
					"An [color=yellow]Energy Potion[/color] would help me prepare supplies for whatever dawn may bring.",
				],
				"guardian_good": [
					"The guardian smiled! Your potions work miracles.",
					"She asked about enhancing defenses. Youth rediscovering wisdom warms my heart.",
					"An [color=yellow]Energy Potion[/color] for baking, though enhanced with [color=orange]extra Comfrey[/color] would be welcome.",
				],
				"guardian_struggling": [
					"Oh child, the shadows under her eyes tell the story.",
					"Teaching her that best strength comes from cleverness, not muscle.",
					"Librarian found accounts where enhanced potions turned skirmishes.",
					"An [color=yellow]Energy Potion[/color]—and if insight suggests something [color=orange]more potent[/color], I trust you.",
				]
			},
			"after": {
				"good": [
					"Ah, warmth spreads just right! Mastered the balance.",
					"I'll bake extra honey biscuits—guardian developed a taste.",
					"Librarian asked for recipe. Says collaboration creates best results."
				],
				"bad": [
					"Bitter aftertaste, like our prospects.",
					"Still, guardian says imperfect tools save lives with wisdom.",
					"Librarian would say every attempt advances understanding. Trust instincts about needs."
				],
				"special": [ # Refresh Potion (enhanced energy)
					"By the eternal flame! Not just energy—pure vitality! Extra Poppy makes difference!",
					"This could power watch and baking! Guardian should try for endurance!",
					"You're not just following recipes—understanding true requirements!"
				]
			}
		},
		2: { # Traveling Librarian - Day 2
			"before": {
				"default": [
					"My research uncovered troubling patterns. These goblins exhibit tactical behavior unseen in local breeds.",
					"The guardian's reports match ancient texts describing organized incursions rather than random raids.",
					"A [color=yellow]Health Potion[/color] would be prudent—these manuscripts won't transcribe themselves.",
				],
				"guardian_success": [
					"The guardian's success proves historical tactics still apply. She's adapting well.",
					"My scrolls mention potions that could turn the tide if properly enhanced.",
					"A [color=yellow]Health Potion[/color], though the old texts suggest [color=orange]fortified versions[/color] for times of conflict.",
				],
				"guardian_struggle": [
					"The guardian's difficulties mirror accounts of underestimated threats.",
					"Historical records show that conventional methods often fail against organized foes.",
					"We need solutions beyond standard potions. Something that [color=orange]changes the battlefield[/color].",
				],
				"collaboration": [
					"The Elder's wisdom combined with my research reveals promising strategies.",
					"Ancient alchemists often brewed for specific threats, not general needs.",
					"Consider what this situation truly requires, not just what's traditionally asked.",
				]
			},
			"after": {
				"good": [
					"Adequate preparation. The consistency suggests careful work.",
					"Remember, the greatest alchemists adapted their craft to the needs of their time.",
					"Between us, we might yet preserve both knowledge and lives."
				],
				"bad": [
					"Imperfect, but serviceable. Even failed mixtures teach valuable lessons.",
					"The Elder would say every attempt brings us closer to understanding.",
					"Don't be constrained by tradition when innovation is needed."
				],
				"special": [ # Strong Potion (enhanced health)
					"Remarkable! This matches descriptions of ancient battle elixirs!",
					"The extra Warmwood creates exactly the fortification described in tactical manuscripts!",
					"With potions like this, we stand a real chance against what's coming!"
				]
			}
		}
	},
	3: {
		0: { # Village Guardian - Day 3
			"before": {
				"default": [
					"This is it—they're massing for an attack. Tonight decides everything.",
					"The traps are set, but we need every advantage. I need a [color=yellow]Strong Potion[/color] for the fight ahead.",
				],
				"good": [
					"Your support has been crucial. We've identified their command group.",
					"The Elder's wisdom about trap placement saved us twice already.",
					"A [color=yellow]Strong Potion[/color] for the final push—this ends tonight, one way or another.",
				],
				"bad": [
					"We're stretched thin. The poultices help, but we need proper healing.",
					"The librarian's maps showed weak points in their formation.",
					"A [color=yellow]Strong Potion[/color] might give us the edge we desperately need.",
				],
				"special": [
					"Between the Elder's strategies and the librarian's research, we've turned this around.",
					"Your enhanced potions have made all the difference in our preparations.",
					"One last [color=yellow]Strong Potion[/color] to finish this—we can actually win this.",
				]
			},
			"after": {
				"good": [
					"Solid and reliable. Exactly what I need for tonight.",
					"Thank you for everything. The village is lucky to have you.",
					"With this, I can face whatever comes through those trees."
				],
				"bad": [
					"It'll have to do. We've come too far to turn back now.",
					"Remember what we've learned—sometimes cleverness beats strength.",
					"Watch for my signal fire tonight. Pray it burns bright."
				],
				"special": [ # Energy Potion (enhanced strong)
					"Incredible! This feels like liquid courage!",
					"With this coursing through me, I could take on their entire war band!",
					"Your master would be proud. You haven't just followed recipes—you've understood what we needed!"
				]
			}
		},
		1: { # Village Elder - Day 3
			"before": {
				"default": [
					"The air tastes of iron and anticipation. Battle comes tonight.",
					"Our guardian prepares to face what we've long feared.",
					"A [color=yellow]Health Potion[/color] for her—she'll need all the strength we can give.",
				],
				"guardian_confident": [
					"She stands ready, your potions having fortified her well.",
					"The old ways and new knowledge have merged beautifully.",
					"A [color=yellow]Health Potion[/color] for our protector—make it count.",
				],
				"guardian_worried": [
					"She carries the weight of us all. I see the doubt in her eyes.",
					"We must give her every advantage we can muster.",
					"A [color=yellow]Health Potion[/color], and pray it's enough to tip the scales.",
				]
			},
			"after": {
				"good": [
					"Well crafted. This should sustain her through the night.",
					"You've grown beyond your master's teachings, child. He would be proud.",
					"Whatever happens tonight, know you've given us our best chance."
				],
				"bad": [
					"It will have to serve. We work with what we have.",
					"Sometimes the will to survive matters more than the tools we wield.",
					"Keep watch tonight. Your skills may yet be needed again."
				],
				"special": [ # Cure Potion (enhanced health)
					"Gods above! This is restoration magic made liquid!",
					"With this, she could survive wounds that would kill a normal warrior!",
					"You haven't just made a potion—you've given us hope!"
				]
			}
		},
		2: { # Traveling Librarian - Day 3
			"before": {
				"default": [
					"History records moments like these—where everything balances on a knife's edge.",
					"My research suggests this night will be remembered, one way or another.",
					"A [color=yellow]Cure Potion[/color] for the aftermath. Hope for the best, prepare for the worst.",
				],
				"elder_concerned": [
					"The Elder's premonitions match ancient omens. She feels the turning point approaching.",
					"Your collaboration has created something new—a fusion of wisdom and craft.",
					"A [color=yellow]Cure Potion[/color] for what comes next. Dawn will tell our story.",
				],
				"final_preparations": [
					"All the pieces are in place. Your innovations have changed everything.",
					"This will be recorded as either our finest hour or our final stand.",
					"One last [color=yellow]Cure Potion[/color]—for healing, for hope, for whatever comes after.",
				]
			},
			"after": {
				"good": [
					"Properly balanced. It will serve its purpose well.",
					"Whatever happens tonight, your contributions have been invaluable.",
					"Future generations will study this moment. I'll ensure they know your role."
				],
				"bad": [
					"Adequate, given the circumstances. We make do.",
					"Remember, even imperfect efforts can change history.",
					"The records will show we tried. That matters."
				],
				"special": [ # Flu Potion (enhanced cure)
					"Astounding! This transcends mere healing—it's revitalization!",
					"You've created something that could redefine post-battle recovery!",
					"With potions like this, we could rebuild better than before! This is legacy work!"
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
		2: { # Librarian wants Refresh Potion
			"Refresh Potion": {"after":"good","score":100},
			#"Failed Potion": {"after":"bad","score":50},
			"Energy Potion": {"after":"special","score":150}  # Enhanced alternative
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
		var default_lines: Array = before_data.get("default", ["What can you brew for me today?"])
		var additional_lines: Array = []
		
		# Determine which contextual dialogue to use based on previous outcomes
		match idx:
			0: # Guardian
				if day == 2:
					# Day 2 Guardian - check if Elder gave strategic advice
					if _customer_states["elder"]["shared_strategic_wisdom"]:
						additional_lines = before_data.get("elder_warned", [])
					else:
						# Check previous potion quality
						var prev_quality = _customer_states["guardian"]["last_potion_quality"]
						if prev_quality == "good":
							additional_lines = before_data.get("good", [])
						elif prev_quality == "bad":
							additional_lines = before_data.get("bad", [])
				elif day == 3:
					# Day 3 Guardian - check if special strategies were used
					if _customer_states["guardian"]["used_special_strategy"]:
						additional_lines = before_data.get("special", [])
					else:
						var prev_quality = _customer_states["guardian"]["last_potion_quality"]
						if prev_quality == "good":
							additional_lines = before_data.get("good", [])
						elif prev_quality == "bad":
							additional_lines = before_data.get("bad", [])
				
			1: # Elder
				if day == 1:
					# Day 1 Elder - check guardian's initial state
					if _customer_states["guardian"]["last_potion_quality"] == "good":
						additional_lines = before_data.get("guardian_good", [])
					elif _customer_states["guardian"]["last_potion_quality"] == "bad":
						additional_lines = before_data.get("guardian_bad", [])
				elif day == 2:
					# Day 2 Elder - check guardian's progress and librarian's involvement
					if _customer_states["guardian"]["last_potion_quality"] == "good":
						additional_lines = before_data.get("guardian_good", [])
					elif _customer_states["guardian"]["last_potion_quality"] == "bad":
						additional_lines = before_data.get("guardian_struggling", [])
					elif _customer_states["librarian"]["researching_strategies"]:
						additional_lines = before_data.get("librarian_collaboration", [])
				elif day == 3:
					# Day 3 Elder - final preparations
					if _customer_states["guardian"]["last_potion_quality"] == "good":
						additional_lines = before_data.get("guardian_confident", [])
					elif _customer_states["guardian"]["last_potion_quality"] == "bad":
						additional_lines = before_data.get("guardian_worried", [])
				
			2: # Librarian
				if day == 1:
					# Day 1 Librarian - initial observations
					if _customer_states["elder"]["shared_wisdom"]:
						additional_lines = before_data.get("elder_mentioned", [])
					elif _customer_states["guardian"]["needs_help"]:
						additional_lines = before_data.get("guardian_danger", [])
				elif day == 2:
					# Day 2 Librarian - ongoing research
					if _customer_states["guardian"]["last_potion_quality"] == "good":
						additional_lines = before_data.get("guardian_success", [])
					elif _customer_states["guardian"]["last_potion_quality"] == "bad":
						additional_lines = before_data.get("guardian_struggle", [])
					elif _customer_states["elder"]["shared_strategic_wisdom"]:
						additional_lines = before_data.get("collaboration", [])
				elif day == 3:
					# Day 3 Librarian - final analysis
					if _customer_states["elder"]["actively_supporting"]:
						additional_lines = before_data.get("elder_concerned", [])
					elif _customer_states["guardian"]["used_special_strategy"]:
						additional_lines = before_data.get("final_preparations", [])
		
		# Always return default lines, with additional context lines appended
		if additional_lines.size() > 0:
			return default_lines + additional_lines
		else:
			return default_lines
	
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
