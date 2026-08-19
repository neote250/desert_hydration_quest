extends PanelContainer
class_name JobEntry

signal job_start(job: Job)

@export var unlocked := true
@export var unlock_hint := ""

var job: Job

@onready var reward_icon: TextureRect = %RewardIcon
@onready var labels: VBoxContainer = %Labels
@onready var job_name_label: Label = %JobNameLabel
@onready var accept_button: Button = %AcceptButton
@onready var description_row: HBoxContainer = %DescriptionRow
@onready var job_description: RichTextLabel = %JobDescription
@onready var job_type_label: Label = %JobTypeLabel
@onready var job_spin_box: SpinBox = %JobSpinBox


func set_job(_job:Job)->void:
	job = _job
	if not unlocked:
		_show_locked()
		return
	reward_icon.texture = job.reward.icon
	job_name_label.text = job.name
	job_type_label.text = Job.JOB_TYPE.keys()[job.job_type].capitalize()

	job_description.text = job.description
	if job_spin_box:
		job_spin_box.min_value = 5
		job_spin_box.max_value = 240
		job_spin_box.step = 5
		job_spin_box.value = job.notification_interval_min

func _show_locked() -> void:
	reward_icon.texture = null
	job_name_label.text = "???"
	job_description.text = unlock_hint
	accept_button.hide()
	modulate.a = 0.6

func _on_accept_button_pressed() -> void:
	if job == null:
		return
	if job_spin_box:
		job.notification_interval_min = int(job_spin_box.value)
	job_start.emit(job)
	SignalManager.toggle_job_board.emit()
