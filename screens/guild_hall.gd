extends Control

## Where gameplay decisions get made.

@onready var stairs_button: TextureButton = %StairsButton
@onready var craft_clerk_button: TextureButton = %CraftClerkButton
@onready var shop_clerk_button: TextureButton = %ShopClerkButton
@onready var job_clerk_button: TextureButton = %JobClerkButton


## TODO: animations — people moving around the hall, clerks idling at their stalls.


func _on_job_clerk_button_pressed() -> void:
	SignalManager.toggle_job_board.emit()


## The crafter. Their recipe list grows with job completion; the recipes bound
## to the crafter themselves don't rotate, so progression is never lost.
func _on_craft_clerk_button_pressed() -> void:
	SignalManager.toggle_crafting.emit()


## TODO: the material shop — daily rotating stock the player buys with materials.
## Slot count grows with job completion. Not built yet.
func _on_shop_clerk_button_pressed() -> void:
	pass


func _on_stairs_button_pressed() -> void:
	GameManager.go_to(Screens.NAME.ROOM)
