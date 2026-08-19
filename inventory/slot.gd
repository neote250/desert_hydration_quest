extends PanelContainer


signal slot_clicked(index:int, button:int)

const LONG_PRESS_TIME := 0.45

@onready var texture_rect: TextureRect = $MarginContainer/TextureRect
@onready var quantity_label: Label = $QuantityLabel

var _pressed := false
var _long_press_fired := false


func set_slot_data(slot_data:SlotData) -> void:
	var item := slot_data.item_data
	texture_rect.texture = item.icon
	
	if slot_data.quantity > 1:
		quantity_label.text = "x%s" % slot_data.quantity
		quantity_label.show()
	else:
		quantity_label.hide()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_pressed = true
			_long_press_fired = false
			_start_long_press_timer()
		else:
			# Released before long press fired -> it's a tap
			if _pressed and not _long_press_fired:
				slot_clicked.emit(get_index(), MOUSE_BUTTON_LEFT)
			_pressed = false

func _start_long_press_timer() -> void:
	get_tree().create_timer(LONG_PRESS_TIME).timeout.connect(func():
		if _pressed and not _long_press_fired:
			_long_press_fired = true
			slot_clicked.emit(get_index(), MOUSE_BUTTON_RIGHT)
	)

func _on_mouse_exited() -> void:
	# Finger slid off the slot — cancel the press
	_pressed = false
