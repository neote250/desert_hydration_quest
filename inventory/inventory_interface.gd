extends Control

signal drop_slot_data(slot_data: SlotData)

const GRAB_OFFSET := Vector2(0, -80)

var grabbed_slot_data: SlotData
@onready var player_inventory: PanelContainer = %PlayerInventory
@onready var grabbed_slot: PanelContainer = %GrabbedSlot


var _dim_touch_start := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if not grabbed_slot.visible:
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		grabbed_slot.global_position = event.position + GRAB_OFFSET

func set_player_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)

func on_inventory_interact(inventory_data: InventoryData, index: int, button: int) -> void:
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.grab_slot_data(index)
		[_, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
		[null, MOUSE_BUTTON_RIGHT]:
			inventory_data.use_slot_data(index)
		[_, MOUSE_BUTTON_RIGHT]:
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)
	update_grabbed_slot()

func update_grabbed_slot() -> void:
	if grabbed_slot_data:
		grabbed_slot.show()
		grabbed_slot.set_slot_data(grabbed_slot_data)
	else:
		grabbed_slot.hide()

func _on_gui_input(event: InputEvent) -> void:
	# Tap on empty/dim space while holding an item -> return it to inventory
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_dim_touch_start = event.position
			# Tap on dim space while holding an item -> return it
			if grabbed_slot_data:
				if GameManager.PLAYER_INVENTORY.pickup_slot_data(grabbed_slot_data):
					grabbed_slot_data = null
				update_grabbed_slot()
	else:
		# Released: was it a downward swipe?
		var delta: Vector2 = event.position - _dim_touch_start
		if delta.y > 120.0 and absf(delta.x) < 100.0:
			SignalManager.toggle_inventory.emit()

func _on_visibility_changed() -> void:
	if not visible and grabbed_slot_data:
		GameManager.PLAYER_INVENTORY.pickup_slot_data(grabbed_slot_data)
		grabbed_slot_data = null
		update_grabbed_slot()
