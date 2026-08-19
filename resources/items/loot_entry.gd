extends Resource
class_name LootEntry

@export var item: Item
@export_range(1, 1000) var weight: int = 100
# optional: roll a quantity range instead of always 1
@export var min_count: int = 1
@export var max_count: int = 1
