extends VBoxContainer
class_name ShopWindow

## The clerk's portrait and speech bubble. Lines are chosen here; nothing
## outside the UI layer should be picking dialogue.

const GREETINGS := [
	"Glad to see ya!",
	"I'll craft for ya!",
	"Keep hydrated out there.",
]
const CRAFT_LINES := [
	"Turned out well!",
	"Some of my finer work.",
]
const CANT_AFFORD_LINES := [
	"Come back with more materials.",
	"Gather more.",
]
const PACK_FULL_LINES := [
	"Your pack's full, traveler.",
	"No room for it. Make some space.",
]

@onready var bubble_label: Label = %BubbleLabel
@onready var shopkeeper_sprite: TextureRect = %ShopkeeperSprite


func greet() -> void:
	say(GREETINGS.pick_random())


func crafted() -> void:
	say(CRAFT_LINES.pick_random())


func come_back_later() -> void:
	say(CANT_AFFORD_LINES.pick_random())


func pack_full() -> void:
	say(PACK_FULL_LINES.pick_random())


func say(line: String) -> void:
	bubble_label.text = line
