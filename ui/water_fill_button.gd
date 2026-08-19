## Hold-to-drink button: a sloshing square of water under an optional canteen skin.
##
## Resting state is full. Pressing empties it instantly and it refills while
## held — so how long the player holds is how big the gulp is. Releasing emits
## [signal sip_taken] with the millilitres earned and eases back to full.
##
## Wire it up in ui.gd:
##     drink_button.sip_taken.connect(GameManager.drink)
##
## [b]Note on balance:[/b] GameManager.DEFAULT_SIP_ML is 15.0, so a full hold at
## the default [member max_sip_ml] logs three sips' worth in one action. That
## interacts with GameManager._is_overdrinking() — worth a pass on
## OVERDRINK_WARN_ML once this is in.
class_name WaterFillButton
extends Button

## Millilitres logged for a hold that reaches completely full.
signal sip_taken(amount_ml: float)

## Volume credited at fill == 1.0. A partial hold is scaled linearly.
@export var max_sip_ml: float = 45.0

## Seconds of holding to go from empty to full.
@export_range(0.2, 5.0, 0.05) var seconds_to_full: float = 1.2

## Seconds to ease back to the resting full state after release.
@export_range(0.05, 2.0, 0.05) var refill_seconds: float = 0.45

## Anything below this is treated as a mis-tap and logs nothing.
@export var minimum_sip_ml: float = 2.0

## Canteen silhouette. Its alpha masks the water; leave null for a plain square.
@export var canteen_mask: Texture2D:
	set(value):
		canteen_mask = value
		_apply_mask()

## Drawn on top of the water — rim, strap, highlights.
@export var canteen_overlay: Texture2D:
	set(value):
		canteen_overlay = value
		if is_instance_valid(_skin):
			_skin.texture = value

## Let the water lean with the device. Harmless on desktop.
@export var use_accelerometer: bool = true

@onready var _fill: ColorRect = %Fill
@onready var _skin: TextureRect = %Skin

var _material: ShaderMaterial
var _level: float = 1.0
var _holding: bool = false
var _tween: Tween


func _ready() -> void:
	_material = _fill.material as ShaderMaterial
	if _material == null:
		push_error("WaterFillButton: %Fill has no ShaderMaterial.")
		set_process(false)
		return

	_apply_mask()
	_skin.texture = canteen_overlay
	_set_level(1.0)

	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


func _process(delta: float) -> void:
	if _holding:
		_set_level(minf(_level + delta / seconds_to_full, 1.0))

	if use_accelerometer:
		var g := Input.get_accelerometer()
		if not g.is_zero_approx():
			# x is the left/right axis in portrait; 9.8 normalises to roughly -1..1.
			_material.set_shader_parameter("tilt", clampf(-g.x / 9.8, -1.0, 1.0))


func _on_button_down() -> void:
	_holding = true
	_kill_tween()
	_set_level(0.0)


func _on_button_up() -> void:
	if not _holding:
		return
	_holding = false

	var amount := _level * max_sip_ml
	if amount >= minimum_sip_ml:
		sip_taken.emit(amount)

	_kill_tween()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_level, _level, 1.0, refill_seconds)


## Current fill, 0..1. Useful for a HUD readout of the pending gulp.
func get_level() -> float:
	return _level


## Snap back to the resting full state without emitting.
func reset() -> void:
	_holding = false
	_kill_tween()
	_set_level(1.0)


func _set_level(value: float) -> void:
	_level = value
	if _material != null:
		_material.set_shader_parameter("fill", value)


func _apply_mask() -> void:
	if _material != null and canteen_mask != null:
		_material.set_shader_parameter("mask", canteen_mask)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
