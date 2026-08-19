extends Control

## Boot screen. Routes to onboarding on a first run, otherwise back to wherever
## the player left off. Onboarding is intentionally not in the Screens registry:
## nothing should ever route back to it.

const ONBOARDING: PackedScene = preload("uid://0h004cby31ql")


func _ready() -> void:
	await get_tree().process_frame

	if GameManager.saved_game.previous_save:
		GameManager.go_to(GameManager.saved_game.current_screen)
	else:
		Ui.hide()
		get_tree().change_scene_to_packed(ONBOARDING)
