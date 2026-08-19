extends PanelContainer

signal craft_requested(recipe: Recipe)

@export var unlocked := true
@export var unlock_hint := ""

var recipe: Recipe

@onready var output_icon: TextureRect = %OutputIcon
@onready var name_label: Label = %NameLabel
@onready var rarity_label: Label = %RarityLabel
@onready var craft_button: Button = %CraftButton
@onready var ingredient_row: HBoxContainer = %IngredientRow

@onready var labels: VBoxContainer = %Labels

const RARITY_COLORS := {
	Item.RARITY.COMMON: Color(0.75, 0.75, 0.75),
	Item.RARITY.UNCOMMON: Color(0.4, 0.9, 0.4),
	Item.RARITY.RARE: Color(0.35, 0.6, 1.0),
	Item.RARITY.EPIC: Color(0.75, 0.4, 1.0),
	Item.RARITY.LEGENDARY: Color(1.0, 0.75, 0.2),
}


func set_recipe(_recipe: Recipe) -> void:
	recipe = _recipe
	if not unlocked:
		_show_locked()
		return
	
	output_icon.texture = recipe.output.icon
	name_label.text = recipe.output.display_name if recipe.output_count <= 1 \
			else "%s x%d" % [recipe.output.display_name, recipe.output_count]
	rarity_label.text = Item.RARITY.keys()[recipe.output.rarity].capitalize()
	rarity_label.add_theme_color_override("font_color", RARITY_COLORS[recipe.output.rarity])
	refresh()

func refresh() -> void:
	if not unlocked:
		return
	
	var inv := GameManager.PLAYER_INVENTORY
	
	for child in ingredient_row.get_children():
		child.queue_free()
	
	var affordable := true
	for ing in recipe.ingredients:
		var have := inv.count_item(ing.material)
		if have < ing.count:
			affordable = false
		var chip := Label.new()
		chip.text = "%s %d/%d" % [ing.material.display_name, mini(have, ing.count), ing.count]
		chip.add_theme_font_size_override("font_size", 12)
		chip.add_theme_color_override("font_color",
				Color(0.4, 0.8, 0.5) if have >= ing.count else Color(0.524, 0.182, 0.154, 1.0))
		ingredient_row.add_child(chip)
	
	if recipe.output is ItemCosmetic and recipe.output in GameManager.owned_cosmetics():
		craft_button.text = "Owned"
		craft_button.disabled = true
		modulate.a = 0.75
	else:
		craft_button.text = "Craft"
		craft_button.disabled = not affordable
		modulate.a = 1.0

func _show_locked() -> void:
	output_icon.texture = null
	name_label.text = "???"
	rarity_label.text = unlock_hint
	craft_button.hide()
	modulate.a = 0.6

func _on_craft_button_pressed() -> void:
	craft_requested.emit(recipe)
