extends Resource
class_name Recipe

@export var output: Item
@export_range(1, 99) var output_count: int = 1  # craft yields, e.g. 1 chitin plate per 5 chitin
@export var unlock_hint: String = ""
@export var ingredients: Array[RecipeIngredient] = []
