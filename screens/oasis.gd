extends Control

## Refilling the bottle. This is the player declaring "that bottle is done",
## which banks it and cashes out the water drunk since the last refill.
@onready var report_panel: PanelContainer = %ReportPanel

var earned

func _ready() -> void:
	SignalManager.oasis_reward_granted.connect(_update_rewards)

func _on_oasis_pool_button_pressed() -> void:
	SignalManager.bottle_completed.emit()
	await get_tree().create_timer(1).timeout
	report_panel.visible = true
	report_panel.populate(earned)
	await report_panel.dismissed
	GameManager.go_to(Screens.NAME.JOURNEY)

func _update_rewards(_earned:Array[Item])-> void:
	earned = _earned
