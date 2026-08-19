extends Resource
class_name InventoryData

signal inventory_updated(inventory_data:InventoryData)
signal inventory_interact(inventory_data:InventoryData, index:int, button:int)

@export var slot_datas: Array[SlotData]

func grab_slot_data(index:int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if slot_data:
		slot_datas[index] = null
		inventory_updated.emit(self)
		return slot_data
	else:
		return null

func drop_slot_data(grabbed_slot_data: SlotData, index:int) -> SlotData:
	var slot_data = slot_datas[index]
	var return_slot_data:SlotData
	
	if slot_data and slot_data.can_fully_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data)
	else:
		slot_datas[index] = grabbed_slot_data
		return_slot_data = slot_data
	
	inventory_updated.emit(self)
	return return_slot_data

func drop_single_slot_data(grabbed_slot_data: SlotData, index:int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if not slot_data:
		slot_datas[index] = grabbed_slot_data.create_single_slot_data()
	elif slot_data.can_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data.create_single_slot_data())
	
	inventory_updated.emit(self)
	
	if grabbed_slot_data.quantity>0:
		return grabbed_slot_data
	else:
		return null


## Long-press on a slot. Cosmetics equip; consumables are spent.
func use_slot_data(index:int) -> void:
	var slot_data = slot_datas[index]
	if not slot_data:
		return

	if slot_data.item_data is ItemCosmetic:
		GameManager.equip(slot_data.item_data)
	elif slot_data.item_data is ItemConsumable:
		slot_data.item_data.use(GameManager)
		SignalManager.item_used.emit(slot_data.item_data)
		slot_data.quantity -= 1
		if slot_data.quantity < 1:
			slot_datas[index] = null

	inventory_updated.emit(self)



func pickup_slot_data(slot_data:SlotData) -> bool:
		
	for index in slot_datas.size():
		if slot_datas[index] and slot_datas[index].can_fully_merge_with(slot_data):
			slot_datas[index].fully_merge_with(slot_data)
			inventory_updated.emit(self)
			return true
	
	for index in slot_datas.size():
		if not slot_datas[index]:
			slot_datas[index] = slot_data
			inventory_updated.emit(self)
			return true
	
	return false


func on_slot_clicked(index:int, button:int) -> void:
	inventory_interact.emit(self,index,button)






func count_item(item: Item) -> int:
	var total := 0
	for slot_data in slot_datas:
		if slot_data and slot_data.item_data == item:
			total += slot_data.quantity
	return total

func can_afford(recipe: Recipe) -> bool:
	for ing in recipe.ingredients:
		if count_item(ing.material) < ing.count:
			return false
	return true

## Spend a recipe's ingredients. A data resource should not know the shopkeeper
## exists, so telling the player about it is the caller's job.
func consume(recipe: Recipe) -> bool:
	if not can_afford(recipe):
		return false
	for ing in recipe.ingredients:
		_remove_item(ing.material, ing.count)
	inventory_updated.emit(self)
	return true

func _remove_item(item: Item, count: int) -> void:
	for index in slot_datas.size():
		var slot_data = slot_datas[index]
		if not slot_data or slot_data.item_data != item:
			continue
		var taken = mini(slot_data.quantity, count)
		slot_data.quantity -= taken
		count -= taken
		if slot_data.quantity < 1:
			slot_datas[index] = null
		if count <= 0:
			return
