extends PanelContainer


signal hot_bar_use(index:int)
signal swiped_up

const SWIPE_MIN_DISTANCE := 100.0
const SWIPE_MAX_TIME := 0.5
const SWIPE_MAX_SIDEWAYS := 100.0

var _swipe_start_pos := Vector2.ZERO
var _swipe_start_time := 0.0
var _swipe_tracking := false



const SLOT = preload("uid://c2e17xc0y3iyy")
const HOT_BAR_SIZE := 6

var inventory_data: InventoryData


@onready var h_box_container: HBoxContainer = $MarginContainer/HBoxContainer


func set_inventory_data(_inventory_data: InventoryData) -> void:
	inventory_data = _inventory_data
	inventory_data.inventory_updated.connect(populate_hot_bar)
	populate_hot_bar(inventory_data)

func populate_hot_bar(_inv: InventoryData) -> void:
	for child in h_box_container.get_children():
		child.queue_free()
	
	for slot_data in inventory_data.slot_datas.slice(0, HOT_BAR_SIZE):
		var slot = SLOT.instantiate()
		h_box_container.add_child(slot)
		slot.slot_clicked.connect(_on_slot_clicked)
		if slot_data:
			slot.set_slot_data(slot_data)

func _on_slot_clicked(index: int, button: int) -> void:
	if button == MOUSE_BUTTON_LEFT:
		inventory_data.use_slot_data(index)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			if get_global_rect().has_point(event.position):
				_swipe_start_pos = event.position
				_swipe_start_time = Time.get_ticks_msec() / 1000.0
				_swipe_tracking = true
		elif _swipe_tracking:
			_swipe_tracking = false
			_check_swipe(event.position)

func _check_swipe(end_pos: Vector2) -> void:
	var elapsed := Time.get_ticks_msec() / 1000.0 - _swipe_start_time
	if elapsed > SWIPE_MAX_TIME:
		return
	
	var delta := end_pos - _swipe_start_pos
	if absf(delta.x) > SWIPE_MAX_SIDEWAYS:
		return
	
	if delta.y < -SWIPE_MIN_DISTANCE:
		swiped_up.emit()
