class_name JourneyEvent
extends Resource

## One thing that happened at a reminder interval while the player was on a job.
##
## These are rolled retroactively: the app can't run code while it's closed, so
## on resume GameManager works out how many intervals elapsed and rolls one of
## these per missed interval. Nothing is lost by being away.

enum KIND {
	## Scenery or a critter. Flavour only, no reward.
	NOTHING,
	## A hidden cache. Resolves straight into a loot roll.
	FREE_LOOT,
	## A playable minigame, or auto-resolvable for average loot.
	MINIGAME,
}

@export var kind: KIND = KIND.NOTHING

## Which minigame to launch. Only meaningful when [member kind] is MINIGAME.
@export var minigame: Screens.NAME = Screens.NAME.SCORPION_NEST_MG

## When this event's interval elapsed, so the journal can order them.
@export var rolled_at_unix: float = 0.0


static func make(event_kind: KIND, when: float, game: Screens.NAME = Screens.NAME.SCORPION_NEST_MG) -> JourneyEvent:
	var e := JourneyEvent.new()
	e.kind = event_kind
	e.rolled_at_unix = when
	e.minigame = game
	return e


func describe() -> String:
	match kind:
		KIND.FREE_LOOT:
			return "A hidden cache"
		KIND.MINIGAME:
			return JourneyEvents.title_for(minigame)
		_:
			return "Quiet travel"
