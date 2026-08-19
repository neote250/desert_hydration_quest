extends CanvasLayer

@onready var notification_scheduler: NotificationScheduler = $NotificationScheduler
@onready var _label: RichTextLabel = $Control/RichTextLabel
	

@export_category("Notification Channel")
@export var channel_id: String = "desert_hydration_quest"
@export var channel_name: String = "Desert Hydration Quest"
@export var channel_description: String = "Gamified Water Drinking App"
@export var channel_importance: NotificationChannel.Importance = NotificationChannel.Importance.DEFAULT

@export_category("Notification Content")
@export var notification_title: String = "Desert Hydration Quest"
@export var notification_text: String = "DRINK"


var _notification_id: int = 2525
var _channel_created: bool = false
var delay: int = 10
var interval: int = 15
var badge: int = 5



func _ready() -> void:
	notification_scheduler.initialize()




func _print_to_screen(a_message: String, a_is_error: bool = false) -> void:
	_label.add_text("%s\n\n" % a_message)
	if a_is_error:
		GmpLogger.log_error(a_message)
	else:
		GmpLogger.log_info(a_message)

	_label.scroll_to_line(_label.get_line_count() - 1)


func _on_notification_scheduler_initialization_completed() -> void:
	_print_to_screen("Initialization completed!")

	if notification_scheduler.has_post_notifications_permission():
		_print_to_screen("App has post notifications permission")
		_create_channel()
	else:
		_print_to_screen("App does not have post notification permissions!")
		notification_scheduler.request_post_notifications_permission()

	if notification_scheduler.has_battery_optimizations_permission():
		_print_to_screen("App is exempt from battery optimizations")
	else:
		_print_to_screen("App does not have battery optimization exemption permissions!")
		notification_scheduler.request_battery_optimizations_permission()

	if notification_scheduler.has_schedule_exact_alarm_permission():
		_print_to_screen("App has exact alarm permission")
	else:
		_print_to_screen("App does not have exact alarm permissions!")
		notification_scheduler.request_schedule_exact_alarm_permission()

func _on_notification_scheduler_post_notifications_permission_granted(permission_name: String) -> void:
	_print_to_screen("%s permission granted" % permission_name)

	_create_channel()

func _on_notification_scheduler_post_notifications_permission_denied(permission_name: String) -> void:
	_print_to_screen("%s permission denied" % permission_name)


func _create_channel() -> void:
	_print_to_screen("Creating notification channel...")
	var __result = notification_scheduler.create_notification_channel(
		(
			NotificationChannel
			. new()
			. set_id(channel_id)
			. set_name(channel_name)
			. set_description(channel_description)
			. set_importance(channel_importance)
		)
	)

	if __result == OK:
		_print_to_screen("Channel '%s' created successfully!" % channel_id)
		_channel_created = true
	elif __result == ERR_ALREADY_EXISTS:
		_print_to_screen("Channel '%s' already exists (this is OK)" % channel_id)
		_channel_created = true
	else:
		_channel_created = false
		match __result:
			ERR_UNCONFIGURED:
				_print_to_screen("Can't create channel %s - plugin not initialized!" % channel_id, true)
			ERR_INVALID_DATA:
				_print_to_screen("Can't create channel %s - channel data is invalid!" % channel_id, true)
			_:
				_print_to_screen("Can't create channel %s - unknown error: %d" % [channel_id, __result], true)



func _ensure_channel_exists() -> bool:
	if _channel_created:
		return true

	# Try to create the channel
	_print_to_screen("Ensuring notification channel exists...")
	var result = notification_scheduler.create_notification_channel(
		(
			NotificationChannel
			. new()
			. set_id(channel_id)
			. set_name(channel_name)
			. set_description(channel_description)
			. set_importance(channel_importance)
		)
	)

	if result == OK or result == ERR_ALREADY_EXISTS:
		_channel_created = true
		_print_to_screen("✓ Channel verified")
		return true
	else:
		_print_to_screen("Failed to create/verify channel. Error: %d" % result, true)
		return false




func _on_send_button_pressed() -> void:
	if not _ensure_channel_exists():
		_print_to_screen("Cannot schedule notification: Channel not available!", true)
		return
		
	var __notification_data = (
		NotificationData
		. new()
		. set_id(_notification_id)
		. set_channel_id(channel_id)
		. set_title(notification_title)
		. set_small_icon_name("ic_stat_local_drink")
		. set_large_icon_name("ic_stat_local_drink")
		. set_content(notification_text)
		. set_delay(delay)
	)
	 
	__notification_data.set_interval(interval)
	
	__notification_data.set_badge_count(badge)

	#__notification_data.set_large_icon_name(NotificationScheduler.DEFAULT_ICON_NAME)
	__notification_data.set_custom_data(
		CustomData.new()
		.set_int_property("my_test_int", 14)
		.set_string_property("my_test_string", "just testing")
	)

	_print_to_screen(
		(
			"Scheduling notification %d with%s a delay of %d seconds (badge count: %d)"
			% [
				_notification_id,
				(
					(" an interval of %d seconds and" % interval)
				),
				delay,
				badge
			]
		)
	)

	var __result = notification_scheduler.schedule(__notification_data)
	_print_to_screen("Schedule Result: %d" %__result)
