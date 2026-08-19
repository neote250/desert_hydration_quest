extends Control

## The job board. A job is a water goal plus a reminder cadence.
##
## Short  = Hunt     - quick outing, ~1 bottle, accelerometer walk for bonus loot
## Medium = Quest    - the default day out; refills and bottle swaps expected
## Long   = Delivery - full day, passive, for players who don't want to menu

const JOB_ENTRY = preload("uid://ccvdky2q0oaox")

## Default minutes between drink reminders, overridable per job on the entry.
const DEFAULT_INTERVAL_MIN := 10

@export var jobs: Array[Job] = []

@onready var job_list: VBoxContainer = %JobList


func _ready() -> void:
	_populate()


func _populate() -> void:
	for child in job_list.get_children():
		child.queue_free()

	for job in jobs:
		var entry := JOB_ENTRY.instantiate()
		job_list.add_child(entry)
		entry.set_job(job)
		entry.job_start.connect(_on_job_accepted)


func _on_job_accepted(job: Job) -> void:
	SignalManager.job_accepted.emit(job)


func _on_close_button_pressed() -> void:
	SignalManager.toggle_job_board.emit()


func _on_dimmer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		SignalManager.toggle_job_board.emit()
