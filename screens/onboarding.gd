extends Control

## First-run setup. Reached exactly once, straight from main.gd, and never
## routed back to — which is why it has no entry in the Screens registry.

@onready var bottle_bar: TabBar = %BottleBar
@onready var tab_container: TabContainer = %TabContainer


func _ready() -> void:
	Ui.hide()
	SignalManager.bottle_size_selected.connect(_finish_onboarding)


func _finish_onboarding(_bottle: BottleSize, _keep_progress: bool) -> void:
	Ui.show()
	GameManager.saved_game.previous_save = true
	GameManager.save()  # flips previous_save, so this scene is never seen again
	GameManager.go_to(Screens.NAME.GUILD_HALL)
