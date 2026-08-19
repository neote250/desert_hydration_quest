## Retints the shared UI theme per town.
##
## Register as an autoload named `ThemeTinter` (Project Settings > Globals).
##
## HOW IT WORKS
## Every themed StyleBoxTexture has an *authored* modulate_color baked into
## ui_theme.tres — Button/hover is 1.15 brighter, Button/disabled is 0.5 darker,
## and so on. Those encode the widget's *state*, not its town.
##
## So a town tint must be MULTIPLIED into the authored value, never assigned
## over it. Assigning would flatten hover and disabled into identical slabs the
## first time the player walked into a town. `_authored` caches the original
## values once at startup so `authored * tint` is always computable.
##
## Because every Control in the game resolves to these same shared StyleBox
## instances, changing them here repaints the entire UI — including scenes that
## have not been instantiated yet. No traversal, no signals.
##
## SAFETY
## Do NOT mark this script @tool. Mutating a loaded Resource only touches the
## in-memory copy — nothing reaches disk unless ResourceSaver.save() is called —
## but a @tool script would apply these writes inside the editor and silently
## re-save ui_theme.tres with whatever tint happened to be active.
extends Node

const THEME: Theme = preload("res://resources/ui_theme.tres")

## Theme type -> stylebox items that carry the town's flavour.
##
## Deliberately absent: WaterButton, DangerButton and the LootCard* variations.
## Those are signals, not scenery. Water reads as water in every town, and Epic
## has to look Epic everywhere or the rarity tier stops carrying information.
## Font colours are absent for the same reason — tinting the wood shifts the
## background while the outlined bone text holds its contrast, but tint the text
## too and the darker palettes drop below AA.
const TINTED: Dictionary = {
	"Panel": ["panel"],
	"PanelContainer": ["panel"],
	"Banner": ["panel"],
	"Slot": ["panel"],
	"Button": ["normal", "hover", "pressed", "disabled"],
	"IconButton": ["normal", "hover", "pressed", "disabled"],
	"LineEdit": ["normal", "focus", "read_only"],
	"SpinBox": ["up_background", "down_background", "up_background_pressed", "down_background_pressed"],
	"TabBar": ["tab_selected", "tab_unselected", "tab_hovered"],
	"TabContainer": ["panel", "tab_selected", "tab_unselected", "tab_hovered"],
}

signal tint_changed(tint: Color)

## StyleBoxTexture -> its authored modulate_color.
var _authored: Dictionary = {}
var _current: Color = Color.WHITE
var _tween: Tween


func _ready() -> void:
	_cache_authored()


## Snapshot every tintable stylebox's authored modulate exactly once.
##
## Keying by the StyleBox instance dedupes for free: Button/disabled and
## IconButton/disabled are literally the same resource, as are LineEdit/normal
## and LineEdit/read_only. Each is cached once and tinted once.
func _cache_authored() -> void:
	for type_name: String in TINTED:
		for item_name: String in TINTED[type_name]:
			if not THEME.has_stylebox(item_name, type_name):
				push_warning("ThemeTinter: no stylebox '%s' on type '%s'" % [item_name, type_name])
				continue
			var box := THEME.get_stylebox(item_name, type_name)
			if box is StyleBoxTexture and not _authored.has(box):
				_authored[box] = (box as StyleBoxTexture).modulate_color


## Snap to a palette with no transition. Use on load / scene boot.
func apply(palette: TownPalette) -> void:
	if palette == null:
		push_warning("ThemeTinter.apply: null palette, ignoring")
		return
	_kill_tween()
	_set_tint(palette.tint)


## Cross-fade to a palette. Use when the player travels between towns.
func transition_to(palette: TownPalette, duration: float = 0.7) -> void:
	if palette == null:
		push_warning("ThemeTinter.transition_to: null palette, ignoring")
		return
	if duration <= 0.0:
		apply(palette)
		return
	_kill_tween()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_method(_set_tint, _current, palette.tint, duration)


## Return the UI to exactly how it is authored in ui_theme.tres.
func reset() -> void:
	_kill_tween()
	_set_tint(Color.WHITE)


func get_tint() -> Color:
	return _current


func _set_tint(tint: Color) -> void:
	_current = tint
	for box: StyleBoxTexture in _authored:
		box.modulate_color = _authored[box] * tint
	tint_changed.emit(tint)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
