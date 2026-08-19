extends Control

const JOURNEY = preload("uid://bcrwp75bbkcex")

@onready var quest_spin_box: SpinBox = %QuestSpinBox

func _ready() -> void:
	pass
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and self.visible:
		close_menu()

func close_menu() -> void:
	hide()

##TODO
#Select a journey length (water bottle goal)
#
func _on_med_quest_button_pressed() -> void:
	get_tree().change_scene_to_packed(JOURNEY)
