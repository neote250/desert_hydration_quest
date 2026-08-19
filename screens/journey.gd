extends Control

## The main "on a journey" splash screen. The drink button lives in the global
## Ui layer; this screen owns the oasis mirage and the journey event queue.

## The mirage fades in as the current bottle empties. Deliberately vague - we
## only ever estimate how much the player actually drank, so the player decides
## when the bottle is really done.
const MIRAGE_MIN_ALPHA := 0.12
const MIRAGE_MAX_ALPHA := 1.0

@onready var oasis_mirage_button: TextureButton = $PanelContainer/OasisMirageButton

# The event banner is optional so this screen still runs if the nodes are not
# in the scene yet. Add them with unique names to switch the feature on.
@onready var event_banner: Control = get_node_or_null("%EventBanner")
@onready var event_label: Label = get_node_or_null("%EventLabel")
@onready var event_button: Button = get_node_or_null("%EventButton")
@onready var skip_button: Button = get_node_or_null("%SkipButton")
@onready var report_panel = get_node_or_null("%ReportPanel")


func _ready() -> void:
	SignalManager.bottle_progress_updated.connect(_on_bottle_progress)
	_refresh_mirage()

	if event_button:
		event_button.pressed.connect(_on_event_pressed)
	if skip_button:
		skip_button.pressed.connect(_on_skip_all_pressed)

	# Roll anything that elapsed while the app was closed, then show what is
	# waiting. Cheap and idempotent, so doing it on every entry is fine.
	GameManager.catch_up_journey_events()
	_show_away_loot()
	_refresh_event_banner()


func _notification(what: int) -> void:
	# Coming back from the background is the main way a backlog appears.
	if what == NOTIFICATION_APPLICATION_RESUMED and is_inside_tree():
		GameManager.catch_up_journey_events()
		_show_away_loot()
		_refresh_event_banner()


# --- Oasis mirage ---------------------------------------------------

func _on_bottle_progress(_current_drunk_ml: float, _volume_ml: float) -> void:
	_refresh_mirage()


func _refresh_mirage() -> void:
	var ratio := clampf(GameManager.current_bottle().fill_ratio(), 0.0, 1.0)
	oasis_mirage_button.modulate.a = lerpf(MIRAGE_MIN_ALPHA, MIRAGE_MAX_ALPHA, ratio)


func _on_oasis_mirage_button_pressed() -> void:
	GameManager.go_to(Screens.NAME.OASIS)


# --- Journey events -------------------------------------------------

func _refresh_event_banner() -> void:
	if event_banner == null:
		return

	var count := GameManager.pending_event_count()
	event_banner.visible = count > 0
	if count == 0:
		return

	var event := GameManager.next_event()
	if event_label:
		event_label.text = event.describe() if count == 1 \
				else "%s  (+%d more)" % [event.describe(), count - 1]
	if event_button:
		event_button.text = "Investigate"
	if skip_button:
		skip_button.text = "Skip all (%d)" % count


## Play or collect the next event.
func _on_event_pressed() -> void:
	var event := GameManager.pop_next_event()
	if event == null:
		_refresh_event_banner()
		return

	match event.kind:
		JourneyEvent.KIND.MINIGAME:
			GameManager.go_to(event.minigame)
		JourneyEvent.KIND.FREE_LOOT:
			var loot := GameManager.grant_loot(
				LootTables.TABLES.OASIS, JourneyEvents.FREE_LOOT_ROLLS
			)
			GameManager.save()
			await _show_loot("Hidden cache!", loot)
			_refresh_event_banner()
		_:
			_refresh_event_banner()


## The "I'm busy" path - clear the whole queue for average loot.
func _on_skip_all_pressed() -> void:
	var loot := GameManager.auto_resolve_all()
	await _show_loot("Collected along the way", loot)
	_refresh_event_banner()


## Loot that auto-resolved past the queue cap while the player was away.
func _show_away_loot() -> void:
	var loot := GameManager.take_unseen_auto_loot()
	if loot.is_empty():
		return
	await _show_loot("Found while you were away", loot)


func _show_loot(title: String, loot: Array[Item]) -> void:
	if report_panel == null:
		return
	report_panel.visible = true
	report_panel.populate(loot, title)
	await report_panel.dismissed
