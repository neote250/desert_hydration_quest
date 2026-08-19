extends PanelContainer

const RECIPE_ENTRY = preload("uid://c6eypit4513fe")

@export var recipes: Array[Recipe] = []

@onready var recipe_list: VBoxContainer = $MarginContainer/RecipeList

func _ready() -> void:
	GameManager.player_inventory_data.inventory_updated.connect(_refresh)
	_populate()

func _populate() -> void:
	for recipe in recipes:
		var entry = RECIPE_ENTRY.instantiate()
		recipe_list.add_child(entry)
		entry.set_recipe(recipe)
		entry.craft_requested.connect(_on_craft_requested)

func _refresh(_inv: InventoryData) -> void:
	for entry in recipe_list.get_children():
		entry.refresh()

func _on_craft_requested(recipe: Recipe) -> void:
	var inv := GameManager.PLAYER_INVENTORY
	if not inv.consume(recipe):
		return
	if GameManager.own_cosmetic(recipe.output):
		SignalManager.cosmetic_crafted.emit(recipe.output)
