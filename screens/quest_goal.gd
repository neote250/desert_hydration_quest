extends Control

## Shown when a job's water goal is met.
##
## Reads GameManager.last_completed_job on _ready rather than listening for
## SignalManager.job_completed: that signal fires inside complete_job(), before
## this scene has been instantiated, so a listener here would never hear it.

## Beat before the reward lands, so arriving doesn't feel abrupt.
const REVEAL_DELAY := 1.5

@onready var report_panel: ReportPanel = %ReportPanel


func _ready() -> void:
	Ui.drink_button.visible = false
	_present_rewards()


func _present_rewards() -> void:
	var job := GameManager.last_completed_job
	Ui.hide()
	await get_tree().create_timer(REVEAL_DELAY).timeout

	report_panel.visible = true
	report_panel.populate(GameManager.job_reward_items(job), _title_for(job))
	await report_panel.dismissed
	Ui.show()
	GameManager.last_completed_job = null
	return_to_town()


func _title_for(job: Job) -> String:
	if job == null:
		return "Journey complete!"
	return "%s complete!" % job.name


func return_to_town() -> void:
	Ui.drink_button.visible = true
	GameManager.go_to(GameManager.saved_game.previous_town)
