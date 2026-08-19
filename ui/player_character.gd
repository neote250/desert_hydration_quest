extends ColorRect
class_name PlayerCharacter

## Drives the sun-damage red overlay. Hydration drifts down in real time and is
## topped back up whenever the player logs a drink.
##
## TODO: swap the ColorRect for an actual red-tinted version of the character art.

## Set true to run decay at 120x so a full dry-out takes seconds, not hours.
@export var debug_fast_decay := true
const DEBUG_TIME_SCALE := 120.0

const SECONDS_PER_HOUR := 3600.0

## How long from fully hydrated to fully red with no drinking.
@export var hours_to_max_dehydration: float = 4.0

## How much of the bar one logged drink restores.
@export var hydration_per_drink: float = 0.25

## Only push the overlay when it actually moved; avoids per-frame churn.
const TINT_EPSILON := 0.002

## 1.0 = fully hydrated (no red), 0.0 = max dehydrated (full red).
var hydration_level: float = 1.0

var _last_applied_alpha := -1.0

@onready var red_overlay: CanvasItem = $"../RedTint"


func _ready() -> void:
	hydration_level = GameManager.saved_game.player_hydration
	_apply_tint()


func _process(delta: float) -> void:
	_decay(delta * (DEBUG_TIME_SCALE * 10 if debug_fast_decay else 1.0))


## Catch up on the time the app spent closed. Called on resume.
func apply_decay() -> void:
	hydration_level = GameManager.saved_game.player_hydration
	var seconds_away := maxf(
		0.0, Time.get_unix_time_from_system() - GameManager.saved_game.previous_login
	)
	_decay(seconds_away * (DEBUG_TIME_SCALE if debug_fast_decay else 1.0))


func _decay(seconds: float) -> void:
	var hours := seconds / SECONDS_PER_HOUR
	hydration_level = clampf(hydration_level - hours / hours_to_max_dehydration, 0.0, 1.0)
	_apply_tint()


## Called by GameManager.drink(). Does not write the save file — GameManager
## owns saving, and writing to disk on every sip was hammering storage.
func drank_water(amount: float = -1.0) -> void:
	var gain := hydration_per_drink if amount < 0.0 else amount
	hydration_level = clampf(hydration_level + gain, 0.0, 1.0)
	_apply_tint()


func _apply_tint() -> void:
	var red_alpha := 1.0 - hydration_level
	GameManager.saved_game.player_hydration = hydration_level

	if absf(red_alpha - _last_applied_alpha) < TINT_EPSILON:
		return
	_last_applied_alpha = red_alpha
	red_overlay.modulate.a = red_alpha
