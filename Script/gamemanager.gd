extends Node
# gamemanager.gd — Bridge between PotionBar and Customer; settle on day 3, show score, allow restart

@export var potion_bar_path: NodePath
@export var customer_path: NodePath

@export var total_days: int = 3              # total number of days
@export var settle_delay_sec: float = 1.0    # delay before settlement after the last day

var potion_bar: Node = null
var customer: Node = null

var _waiting_for_potion: bool = false
var _pending_potion_name: String = ""        # buffer if potion is made before the customer is awaiting
var _settle_dialog: AcceptDialog = null      # settlement popup

func _ready() -> void:
	# fetch nodes
	if potion_bar_path != NodePath():
		potion_bar = get_node_or_null(potion_bar_path)
	if customer_path != NodePath():
		customer = get_node_or_null(customer_path)

	if potion_bar == null:
		push_error("GameManager.gd: PotionBar not found. Please set potion_bar_path in the Inspector.")
	if customer == null:
		push_error("GameManager.gd: Customer not found. Please set customer_path in the Inspector.")

	# connect signals
	if potion_bar:
		# PotionBar.gd: signal potion_made(potion_name: String)
		potion_bar.connect("potion_made", Callable(self, "_on_potion_made"))
	if customer:
		# Customer.gd: signal awaiting_potion(customer_index: int, day: int)
		customer.connect("awaiting_potion", Callable(self, "_on_customer_awaiting"))
		# Customer.gd: signal finished_day(day: int)
		customer.connect("finished_day", Callable(self, "_on_finished_day"))
		customer.set("_total_days", total_days)

	# init state
	_waiting_for_potion = false
	_pending_potion_name = ""

func _on_potion_made(potion_name: String) -> void:
	# When a potion is made: deliver immediately if customer is awaiting; otherwise buffer it
	if customer == null:
		return

	if _waiting_for_potion:
		_waiting_for_potion = false
		customer.call_deferred("notify_potion", potion_name)
		_pending_potion_name = ""
		print("[GameManager] Deliver potion now: ", potion_name)
	else:
		_pending_potion_name = potion_name
		print("[GameManager] Buffer potion: ", potion_name, " (waiting for customer to be ready)")

func _on_customer_awaiting(customer_index: int, day: int) -> void:
	# Customer is now awaiting a potion
	_waiting_for_potion = true
	print("[GameManager] Customer awaiting: day ", day, " index ", customer_index)

	# If a potion was buffered earlier, deliver it now
	if _pending_potion_name != "":
		var potion_to_deliver := _pending_potion_name   # avoid shadowing Node.name
		_pending_potion_name = ""
		_waiting_for_potion = false
		customer.call_deferred("notify_potion", potion_to_deliver)
		print("[GameManager] Deliver buffered potion: ", potion_to_deliver)

func _on_finished_day(day: int) -> void:
	print("[GameManager] Day finished: day ", day, ". Moving to next day.")
	# clear state across days
	_waiting_for_potion = false
	_pending_potion_name = ""

	# reached the last day: start settlement flow
	if day >= total_days:
		# prevent Customer from starting the next day (Customer._start_customer_flow checks _running)
		if customer:
			customer.set("_running", true)
		# wait, then show settlement
		await get_tree().create_timer(settle_delay_sec).timeout
		_show_settlement()

# ===== Settlement popup =====
func _show_settlement() -> void:
	var score := 0
	if customer:
		var v = customer.get("_total_score")
		if v != null:
			score = int(v)

	if _settle_dialog == null:
		_settle_dialog = AcceptDialog.new()
		_settle_dialog.title = "End of Operations"
		_settle_dialog.dialog_text = ""
		_settle_dialog.exclusive = true
		_settle_dialog.min_size = Vector2i(320, 180)
		_settle_dialog.size = Vector2i(320, 180)
		add_child(_settle_dialog)
		# set button text to "Restart"
		_settle_dialog.get_ok_button().text = " Restart "
		_settle_dialog.confirmed.connect(func ():
			get_tree().reload_current_scene()
		)
	
	var lbl := _settle_dialog.get_label()
	if lbl:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 32)

	_settle_dialog.dialog_text = "Score: %d" % score
	_settle_dialog.popup_centered_clamped(_settle_dialog.size, 0.9)
