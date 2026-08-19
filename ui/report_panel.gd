extends PanelContainer
class_name ReportPanel

signal dismissed

@onready var item_grid: GridContainer = %ItemGrid
@onready var continue_button: Button = %ContinueButton
@onready var title_label: Label = %TitleLabel

const RARITY_COLORS := {
	Item.RARITY.COMMON: Color(0.6, 0.6, 0.6, 0.0),
	Item.RARITY.UNCOMMON: Color(0.3, 0.9, 0.3, 0.6),
	Item.RARITY.RARE: Color(0.3, 0.5, 1.0, 0.7),
	Item.RARITY.EPIC: Color(0.7, 0.3, 1.0, 0.8),
	Item.RARITY.LEGENDARY: Color(0.675, 0.812, 0.0, 0.8),
}

const SLOT_SIZE := Vector2(72, 72)
const REVEAL_DELAY := 0.12   # gap between each slot appearing
const POP_TIME := 0.25       # how long each slot's scale-up takes

func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue_pressed)

## [param title] overrides the default heading, so the same panel can be reused
## for cache finds, minigame reports and end-of-job rewards.
func populate(loot_earned: Array[Item], title: String = "") -> void:
	for child in item_grid.get_children():
		child.queue_free()

	if not title.is_empty():
		title_label.text = title
	elif loot_earned.is_empty():
		title_label.text = "No Loot Earned..."
	else:
		title_label.text = "Loot Earned!"

	# Don't let the player dismiss mid-reveal and cut off the payoff.
	continue_button.disabled = true
	
	# build all slots up front, hidden, so the grid layout is stable
	var slots: Array[Control] = []
	for item in loot_earned:
		if item == null:
			continue
		var slot := _make_slot(item)
		slot.modulate.a = 0.0
		item_grid.add_child(slot)
		slots.append(slot)
	_reveal_slots(slots)

func _reveal_slots(slots: Array[Control]) -> void:
	# wait one frame so the GridContainer has positioned everything
	await get_tree().process_frame

	for slot in slots:
		# pivot at center so the scale pop grows from the middle
		slot.pivot_offset = slot.size / 2.0
		slot.scale = Vector2(0.3, 0.3)

		var tween := create_tween().set_parallel()
		tween.tween_property(slot, "modulate:a", 1.0, POP_TIME)
		tween.tween_property(slot, "scale", Vector2.ONE, POP_TIME)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		# TODO: play a soft "tick" sound here, pitched up per slot maybe

		await get_tree().create_timer(REVEAL_DELAY).timeout

	continue_button.disabled = false

func _make_slot(item: Item) -> Control:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = SLOT_SIZE

	var style := StyleBoxFlat.new()
	var rarity := item.rarity
	var glow: Color = RARITY_COLORS.get(rarity, RARITY_COLORS[Item.RARITY.COMMON])
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_color = glow
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	slot.add_theme_stylebox_override("panel", style)

	var tex := TextureRect.new()
	tex.texture = item.icon
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot.add_child(tex)

	if rarity >= Item.RARITY.RARE:
		# start the pulse only after the slot has revealed
		_add_pulse_deferred(slot, glow)

	return slot

func _add_pulse_deferred(slot: PanelContainer, glow: Color) -> void:
	# small delay so the pulse doesn't fight the reveal pop
	await get_tree().create_timer(POP_TIME + 0.1).timeout
	if not is_instance_valid(slot):
		return
	var style: StyleBoxFlat = slot.get_theme_stylebox("panel")
	var bright := glow
	bright.a = 1.0
	var dim := glow
	dim.a = 0.4
	var tween := slot.create_tween().set_loops()
	tween.tween_method(func(c): style.border_color = c, dim, bright, 0.6)
	tween.tween_method(func(c): style.border_color = c, bright, dim, 0.6)


func change_title_text(title:String)->void:
	title_label.text = title


func _on_continue_pressed() -> void:
	visible = false
	dismissed.emit()
