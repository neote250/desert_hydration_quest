class_name JourneyEvents
extends RefCounted

## Roll table and payout rules for journey events.
##
## Not an autoload — it's pure data plus static helpers, so it can be used from
## GameManager and from the UI without an instance.

## Relative weights for what a reminder interval turns into.
const WEIGHT_NOTHING := 50
const WEIGHT_FREE_LOOT := 30
const WEIGHT_MINIGAME := 20

## Minigames that can be rolled, and the loot table each pays from.
const MINIGAMES := [
	Screens.NAME.SCORPION_NEST_MG,
	Screens.NAME.FREE_LOOT_MG,
]

## How many rolls a minigame is worth when auto-resolved for "average" loot.
## Deliberately less than playing it well, more than skipping it.
const AUTO_RESOLVE_ROLLS := 2
const FREE_LOOT_ROLLS := 1


static func roll_kind(rng_value: int) -> JourneyEvent.KIND:
	var total := WEIGHT_NOTHING + WEIGHT_FREE_LOOT + WEIGHT_MINIGAME
	var pick := rng_value % total
	if pick < WEIGHT_NOTHING:
		return JourneyEvent.KIND.NOTHING
	if pick < WEIGHT_NOTHING + WEIGHT_FREE_LOOT:
		return JourneyEvent.KIND.FREE_LOOT
	return JourneyEvent.KIND.MINIGAME


static func random_minigame() -> Screens.NAME:
	return MINIGAMES.pick_random()


## Which loot table a given minigame pays from.
static func loot_table_for(minigame: Screens.NAME) -> LootTables.TABLES:
	match minigame:
		Screens.NAME.SCORPION_NEST_MG:
			return LootTables.TABLES.NEST_MG
		_:
			return LootTables.TABLES.OASIS


static func title_for(minigame: Screens.NAME) -> String:
	match minigame:
		Screens.NAME.SCORPION_NEST_MG:
			return "A scorpion nest"
		Screens.NAME.FREE_LOOT_MG:
			return "A scattered cache"
		_:
			return "Something stirs"
