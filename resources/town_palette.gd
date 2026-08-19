## A per-town colour flavour for the shared UI theme.
##
## The whole point: one atlas, one theme, many towns. [member tint] is
## *multiplied* into every themed StyleBoxTexture, so the same wood-and-parchment
## kit can read as sun-bleached high desert, a moonlit mystic quarter or a dusty
## western outpost without a single new sprite.
##
## Signals — water, danger, loot rarity — are deliberately NOT tinted. See
## ThemeTinter for the reasoning.
class_name TownPalette
extends Resource

## Stable identifier used by save data. Never localise this.
@export var id: StringName = &"guild"

## Shown to the player.
@export var display_name: String = "Guild Hall"

## Multiplied into every themed StyleBoxTexture.
## Color.WHITE means "exactly as authored in ui_theme.tres".
## Values above 1.0 brighten — that is intentional and safe.
@export var tint: Color = Color.WHITE

## Optional one-line flavour for loading screens / journey splash.
@export_multiline var blurb: String = ""


## Convenience for debug overlays and the town picker.
func _to_string() -> String:
	return "TownPalette<%s tint=%s>" % [id, tint]
