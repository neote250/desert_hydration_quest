extends Control

## TODO swap between different idle animations depending on room furniture:
##   RestSpot - sleep on bed, relax on beanbag
##   WorkSpot - study at desk, whittle wood at table
##   FunSpot  - handheld console on the floor, read a book in the chair


func _on_button_pressed() -> void:
	GameManager.go_to(Screens.NAME.GUILD_HALL)
