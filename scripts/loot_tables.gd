extends Node

## Autoload. Wraps the loot tables and applies pity so a dry streak ends.

enum TABLES { NEST_MG, OASIS }

## Rolls without a rare-or-better before one is guaranteed.
const PITY_THRESHOLD := 25

var _tables := {
	TABLES.NEST_MG: preload("res://resources/loot_tables/ScorpionNestLT.tres"),
	TABLES.OASIS: preload("res://resources/loot_tables/OasisLT.tres"),
}

var _rolls_since_rare := 0


## Returns null if the table is missing or empty; callers must handle that.
func roll(table_name: TABLES) -> SlotData:
	var table: LootTable = _tables.get(table_name)
	if table == null:
		push_error("Unknown loot table: %s" % table_name)
		return null

	var entry := table.roll()
	if entry == null or entry.item == null:
		return null

	if entry.item.rarity >= Item.RARITY.RARE:
		_rolls_since_rare = 0
	else:
		_rolls_since_rare += 1
		if _rolls_since_rare >= PITY_THRESHOLD:
			var upgraded := table.roll_rarity_or_better(Item.RARITY.RARE)
			if upgraded and upgraded.item:
				entry = upgraded
			_rolls_since_rare = 0

	return SlotData.from_item(entry.item, randi_range(entry.min_count, entry.max_count))
