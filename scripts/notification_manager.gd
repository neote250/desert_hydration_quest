extends Node

## Autoload. Owns the Android notification channel and the recurring drink
## reminder that runs for the duration of a job.
##
## NOTE: the scheduler is built in code here, not placed in a scene, so its
## signals have to be connected by hand. They used to be editor-wired in
## notification_tester.tscn; that wiring did not come across, which meant
## permissions were never requested on a fresh install. It appeared to work on
## an emulator that had already been granted POST_NOTIFICATIONS by the tester
## scene, and because _ensure_channel_exists() creates the channel lazily at
## send time.

@export_category("Notification Channel")
@export var channel_id: String = "desert_hydration_quest"
@export var channel_name: String = "Desert Hydration Quest"
@export var channel_description: String = "Gamified Water Drinking App"
@export var channel_importance: NotificationChannel.Importance = NotificationChannel.Importance.DEFAULT

@export_category("Notification Content")
@export var notification_title: String = "Desert Hydration Quest"
@export var notification_text: String = "Time for a drink, traveler."

const JOB_REMINDER_ID := 2525
const SECONDS_PER_MINUTE := 60
## First reminder fires this long after the job starts.
const FIRST_REMINDER_DELAY_SEC := 60

## Testing aid: treat the job's interval as SECONDS instead of minutes, and fire
## the first reminder almost immediately. Turn off before shipping.
@export var debug_fast_reminders := true
const DEBUG_FIRST_DELAY_SEC := 10

var notification_scheduler: NotificationScheduler

var _channel_created := false
var _initialized := false
## Set when a job starts before the plugin finished initializing.
var _pending_interval_min := 0


func _ready() -> void:
	notification_scheduler = NotificationScheduler.new()
	add_child(notification_scheduler)

	notification_scheduler.initialization_completed.connect(_on_initialization_completed)
	notification_scheduler.post_notifications_permission_granted.connect(_on_permission_granted)
	notification_scheduler.post_notifications_permission_denied.connect(_on_permission_denied)

	notification_scheduler.initialize()


# --- Public API -----------------------------------------------------

## Start the recurring drink reminder for an active job.
func start_job_reminders(interval_min: int) -> void:
	if not _initialized:
		push_warning("Plugin not initialized yet; reminders queued.")
		_pending_interval_min = interval_min
		return
	if not _ensure_channel_exists():
		push_warning("No notification channel; reminders not scheduled.")
		return

	stop_job_reminders()

	var delay := DEBUG_FIRST_DELAY_SEC if debug_fast_reminders else FIRST_REMINDER_DELAY_SEC
	var interval_sec := interval_min if debug_fast_reminders else interval_min * SECONDS_PER_MINUTE

	var data := (
		NotificationData
		. new()
		. set_id(JOB_REMINDER_ID)
		. set_channel_id(channel_id)
		. set_title(notification_title)
		. set_content(notification_text)
		. set_small_icon_name("ic_stat_local_drink")
		. set_large_icon_name("ic_stat_local_drink")
		. set_delay(delay)
		. set_interval(interval_sec)
	)

	var result := notification_scheduler.schedule(data)
	if result == OK:
		print("[NotificationManager] scheduled: first in %ds, then every %ds" % [delay, interval_sec])
	else:
		push_warning("Could not schedule drink reminders: %d" % result)


## Stop reminders. Called when a job completes or is canceled.
func stop_job_reminders() -> void:
	if notification_scheduler:
		notification_scheduler.cancel(JOB_REMINDER_ID)


# --- Plugin lifecycle -----------------------------------------------

func _on_initialization_completed() -> void:
	_initialized = true
	print("[NotificationManager] plugin initialized; post-notifications permission: %s"
			% notification_scheduler.has_post_notifications_permission())

	# Clear anything left scheduled from a previous run of the app.
	notification_scheduler.cancel(JOB_REMINDER_ID)

	if notification_scheduler.has_post_notifications_permission():
		_create_channel()
	else:
		notification_scheduler.request_post_notifications_permission()

	if not notification_scheduler.has_battery_optimizations_permission():
		notification_scheduler.request_battery_optimizations_permission()

	if not notification_scheduler.has_schedule_exact_alarm_permission():
		notification_scheduler.request_schedule_exact_alarm_permission()

	if _pending_interval_min > 0:
		var interval := _pending_interval_min
		_pending_interval_min = 0
		start_job_reminders(interval)


func _on_permission_granted(_permission_name: String) -> void:
	_create_channel()


func _on_permission_denied(_permission_name: String) -> void:
	# TODO: surface this in-game — without it the whole reminder loop is dead.
	push_warning("Notification permission denied; drink reminders are unavailable.")


func _create_channel() -> void:
	var result := notification_scheduler.create_notification_channel(
		(
			NotificationChannel
			. new()
			. set_id(channel_id)
			. set_name(channel_name)
			. set_description(channel_description)
			. set_importance(channel_importance)
		)
	)
	_channel_created = result == OK or result == ERR_ALREADY_EXISTS
	if not _channel_created:
		push_warning("Could not create notification channel '%s': %d" % [channel_id, result])


func _ensure_channel_exists() -> bool:
	if _channel_created:
		return true
	_create_channel()
	return _channel_created
