extends Control

## Onboarding step: name a bottle, give its size, pick a display unit.
##
## The spin box value is entered in whatever unit the player selected, and is
## converted to ml immediately. Nothing downstream ever sees ounces.

@onready var spin_box: SpinBox = %SpinBox
@onready var custom_bottle_btn: TextureButton = %CustomBottleBtn
@onready var measurement_option_btn: OptionButton = %MeasurementOptionBtn
@onready var player_input: LineEdit = %PlayerInput


## Sensible SpinBox bounds per unit. Without this the box keeps its ml range
## when the player switches to oz (and vice versa), so "8" can mean 8 ml.
const RANGE_OZ := Vector2(4, 128)
const RANGE_ML := Vector2(100, 3000)


func _ready() -> void:
	open_menu()
	_apply_unit_range()


## Connect the OptionButton's item_selected signal to this in the scene.
func _on_measurement_option_btn_item_selected(_index: int) -> void:
	_apply_unit_range()


func _apply_unit_range() -> void:
	var is_oz := measurement_option_btn.selected == BottleSize.MEASUREMENT.OZ
	var r := RANGE_OZ if is_oz else RANGE_ML
	spin_box.min_value = r.x
	spin_box.max_value = r.y
	spin_box.step = 1 if is_oz else 50
	spin_box.value = clampf(spin_box.value, r.x, r.y)


func open_menu() -> void:
	Ui.drink_button.visible = false


func close_menu() -> void:
	visible = false
	Ui.drink_button.visible = true


func _on_custom_bottle_btn_pressed() -> void:
	var bottle := BottleSize.new()
	bottle.measurement = measurement_option_btn.selected as BottleSize.MEASUREMENT
	bottle.volume_ml = bottle.from_display(spin_box.value)
	bottle.label = player_input.text if not player_input.text.is_empty() else "bottle"

	SignalManager.bottle_size_selected.emit(bottle, false)
	close_menu()


func _on_measurement_option_btn_pressed() -> void:
	pass # Replace with function body.
