extends Control
class_name ShopInterface

## The crafter's window. Despite the "shop" filenames this is the CRAFTING UI —
## it trades materials for recipe output. The material shop (buy stock with
## currency, rotates daily) is a separate thing that doesn't exist yet.
##
## TODO: rename this file and its scene to craft_interface once you're ready to
## build the real shop, so the two don't collide.

const RECIPE_ENTRY = preload("uid://c6eypit4513fe")

@export var recipes: Array[Recipe] = []

@onready var recipe_list: VBoxContainer = %RecipeList
@onready var shopkeeper_column: ShopWindow = %ShopkeeperColumn


func _ready() -> void:
	GameManager.PLAYER_INVENTORY.inventory_updated.connect(_refresh)
	SignalManager.cosmetic_crafted.connect(_on_cosmetic_crafted)
	_populate()


func _populate() -> void:
	for child in recipe_list.get_children():
		child.queue_free()

	for recipe in recipes:
		var entry := RECIPE_ENTRY.instantiate()
		recipe_list.add_child(entry)
		entry.set_recipe(recipe)
		entry.craft_requested.connect(_on_craft_requested)


func _refresh(_inv: InventoryData = null) -> void:
	for entry in recipe_list.get_children():
		entry.refresh()


func _on_cosmetic_crafted(_item: ItemCosmetic) -> void:
	_refresh()


## The shopkeeper's dialogue lives here, not inside InventoryData — a data
## resource shouldn't know the shopkeeper exists.
func _on_craft_requested(recipe: Recipe) -> void:
	if GameManager.craft(recipe):
		shopkeeper_column.crafted()
	elif not GameManager.PLAYER_INVENTORY.can_afford(recipe):
		shopkeeper_column.come_back_later()
	else:
		shopkeeper_column.pack_full()


func _on_close_button_pressed() -> void:
	SignalManager.toggle_crafting.emit()


func _on_dimmer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		SignalManager.toggle_crafting.emit()
