extends VBoxContainer

@onready var sprites := {
	ItemCosmetic.SLOT_TYPE.AVATAR: %AvatarSprite,
	ItemCosmetic.SLOT_TYPE.BOTTLE: %BottleSprite,
	ItemCosmetic.SLOT_TYPE.ACCESSORY: %AccessorySprite,
}

@export var default_avatar: Texture2D  # base look before any cosmetics

func _ready() -> void:
	SignalManager.cosmetic_equipped.connect(_on_cosmetic_equipped)
	_refresh_all()

func _refresh_all() -> void:
	for slot_type in sprites:
		var item := GameManager.equipped_in(slot_type)
		_apply(slot_type, item)

func _on_cosmetic_equipped(slot_type: ItemCosmetic.SLOT_TYPE, item: ItemCosmetic) -> void:
	_apply(slot_type, item)

func _apply(slot_type: ItemCosmetic.SLOT_TYPE, item: ItemCosmetic) -> void:
	var sprite: TextureRect = sprites[slot_type]
	if item:
		sprite.texture = item.icon  # or a dedicated preview_texture, see note
		sprite.show()
	elif slot_type == ItemCosmetic.SLOT_TYPE.AVATAR:
		sprite.texture = default_avatar
		sprite.show()
	else:
		sprite.hide()
