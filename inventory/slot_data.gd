extends Resource
class_name SlotData

const MAX_STACK_SIZE: int = 99

@export var item_data: Item
@export_range(1, MAX_STACK_SIZE) var quantity: int = 1: set = set_quantity

static func from_item(item: Item, count: int = 1) -> SlotData:
	var sd := SlotData.new()
	sd.item_data = item
	sd.quantity = clampi(count, 1, MAX_STACK_SIZE)
	return sd

func can_merge_with(other_slot_data:SlotData) -> bool:
	return item_data == other_slot_data.item_data \
		and quantity < MAX_STACK_SIZE


func can_fully_merge_with(other_slot_data:SlotData) -> bool:
	return item_data == other_slot_data.item_data \
		and quantity + other_slot_data.quantity <= MAX_STACK_SIZE

func fully_merge_with(other_slot_data:SlotData) -> void:
	quantity += other_slot_data.quantity

func create_single_slot_data() -> SlotData:
	var new_slot_data = duplicate() as SlotData
	new_slot_data.quantity = 1
	quantity -= 1
	return new_slot_data

func set_quantity(value:int) -> void:
	quantity = clampi(value, 0, MAX_STACK_SIZE)
