extends Resource
class_name Item

@export var id: StringName
@export var display_name: String
@export_multiline var description: String = ""

@export var icon:Texture2D

enum RARITY {COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}
@export var rarity: RARITY = RARITY.COMMON


func use(target) -> void:
	pass
