extends CanvasLayer


const SWIPE_MIN_DISTANCE := 120.0   # pixels; tune on device
const SWIPE_MAX_TIME := 0.5         # seconds
const SWIPE_MAX_SIDEWAYS := 100.0   # reject diagonal-ish drags
const SLIDE_TIME := 0.25


#@onready var _label: RichTextLabel = $Control/RichTextLabel #label for debugging in android
@onready var drink_button: = $Control/DrinkButton
@onready var inventory_interface: Control = $InventoryInterface
@onready var hot_bar_inventory: PanelContainer = %HotBarInventory

@onready var shop_interface: ShopInterface = %ShopInterface
@onready var job_board_menu: Control = %JobBoardMenu

@onready var settings_menu: Control = %SettingsMenu


@onready var player_character: PlayerCharacter = %PlayerCharacter
@onready var red_tint: ColorRect = %RedTint

var _touch_start_pos := Vector2.ZERO
var _touch_start_time := 0.0
var _touch_active := false

func _ready() -> void:
	inventory_interface.set_player_inventory_data(GameManager.PLAYER_INVENTORY)
	hot_bar_inventory.set_inventory_data(GameManager.PLAYER_INVENTORY)
	inventory_interface.hide()
	SignalManager.toggle_inventory.connect(_toggle_inventory)
	hot_bar_inventory.swiped_up.connect(_on_hotbar_swiped_up)
	
	shop_interface.hide()
	SignalManager.toggle_crafting.connect(_toggle_crafting)
	SignalManager.toggle_job_board.connect(_toggle_job_board)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_pos = event.position
			_touch_start_time = Time.get_ticks_msec() / 1000.0
			_touch_active = true
		elif _touch_active:
			_touch_active = false
			_check_swipe(event.position)

func _on_drink_button_pressed() -> void:
	#SignalManager.test_notification.emit()
	GameManager.drink()
	##later change this to emit how long button pressed

func _check_swipe(end_pos: Vector2) -> void:
	var elapsed := Time.get_ticks_msec() / 1000.0 - _touch_start_time
	if elapsed > SWIPE_MAX_TIME:
		return
	
	var delta := end_pos - _touch_start_pos
	if absf(delta.x) > SWIPE_MAX_SIDEWAYS:
		return
	
	if delta.y < -SWIPE_MIN_DISTANCE and not inventory_interface.visible:
		_slide_in(inventory_interface)
	elif delta.y > SWIPE_MIN_DISTANCE and inventory_interface.visible:
		_slide_out(inventory_interface)

func _toggle_inventory() -> void:
	if inventory_interface.visible:
		_slide_out(inventory_interface)
	else:
		_slide_in(inventory_interface)


func _slide_in(panel:Control)->void:
	panel.show()
	panel.position.y = panel.size.y  # start off-screen below
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "position:y", 0.0, SLIDE_TIME)
	tween.parallel().tween_property(hot_bar_inventory, "modulate:a", 0.0, SLIDE_TIME)
	tween.tween_callback(hot_bar_inventory.hide) 


func _on_hotbar_swiped_up() -> void:
	if not inventory_interface.visible:
		_slide_in(inventory_interface)
	

func _slide_out(panel:Control)-> void:
	var tween := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	hot_bar_inventory.show()
	tween.tween_property(panel, "position:y", panel.size.y, SLIDE_TIME)
	tween.parallel().tween_property(hot_bar_inventory, "modulate:a", 1.0, SLIDE_TIME)
	tween.tween_callback(panel.hide)

func _toggle_crafting() -> void:
	if shop_interface.visible:
		_slide_out(shop_interface)
	else:
		if inventory_interface.visible:
			_slide_out(inventory_interface)
		shop_interface.shopkeeper_column.greet()
		_slide_in(shop_interface)

func _toggle_job_board() -> void:
	if job_board_menu.visible:
		_slide_out(job_board_menu)
	else:
		#TODO Greeting
		_slide_in(job_board_menu)


##DEBUG Currently
#func _update(_total_drunk:float)->void:
	##_label.add_text("%s\n\n" % str(_total_drunk))
	##_label.scroll_to_line(_label.get_line_count() - 1)
	#pass


func _on_settings_button_pressed() -> void:
	settings_menu.show()


func _on_water_fill_button_sip_taken(amount_ml: float) -> void:
	drink_button.sip_taken.connect(GameManager.drink)
