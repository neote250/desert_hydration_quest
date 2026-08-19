extends Control

## A scattered cache. Pickups spawn around the centre; tapping one banks a loot
## roll. Ends when everything is gathered or the timer runs out - whichever
## comes first, the player keeps what they already picked up.
##

## Scene instanced for each pickup. Must emit `pressed` (Button, TextureButton…).
@export var pickup_scene: PackedScene

## How many pickups to scatter.
@export var pickup_count := 5
## Generous - this is a reward, not a test.
@export var time_limit := 20.0
## How far from the centre pickups can land.
@export var spread := Vector2(240, 360)
## Loot rolls granted per pickup.
@export var rolls_per_pickup := 1

@onready var container_for_random_spawn: Control = $ContainerForRandomSpawn
@onready var report_panel = $ReportPanel

var loot_earned: Array[Item] = []
var _remaining := 0
var _finished := false


func _ready() -> void:
	Ui.drink_button.visible = false
	_spawn_pickups()
	_start_timeout()


func _spawn_pickups() -> void:
	var centre := get_viewport_rect().size / 2.0
	_remaining = pickup_count

	for i in pickup_count:
		var pickup := _make_pickup()
		container_for_random_spawn.add_child(pickup)
		pickup.position = centre + Vector2(
			randf_range(-spread.x, spread.x),
			randf_range(-spread.y, spread.y)
		)
		pickup.pressed.connect(_on_pickup_taken.bind(pickup))


func _make_pickup() -> Control:
	if pickup_scene:
		var instanced := pickup_scene.instantiate()
		if instanced is Control and instanced.has_signal("pressed"):
			return instanced
		push_warning("pickup_scene must be a Control that emits 'pressed'; using a placeholder.")
		instanced.queue_free()

	var placeholder := Button.new()
	placeholder.text = "?"
	placeholder.custom_minimum_size = Vector2(96, 96)
	return placeholder


func _on_pickup_taken(pickup: Node) -> void:
	if _finished:
		return

	loot_earned.append_array(
		GameManager.grant_loot(LootTables.TABLES.NEST_MG, rolls_per_pickup)
	)
	pickup.queue_free()

	_remaining -= 1
	if _remaining <= 0:
		_finish()


func _start_timeout() -> void:
	await get_tree().create_timer(time_limit).timeout
	if not _finished:
		_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true

	for pickup in container_for_random_spawn.get_children():
		pickup.queue_free()

	GameManager.save()
	report_panel.visible = true
	report_panel.populate(loot_earned, "Cache gathered!")
	await report_panel.dismissed
	exit()


func exit() -> void:
	Ui.drink_button.visible = true
	GameManager.go_to(Screens.NAME.JOURNEY)
