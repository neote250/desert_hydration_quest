class_name LootTable
extends Resource

@export var entries: Array[LootEntry] = []


## Weighted pick. Returns null on an empty table rather than indexing off the end.
func roll() -> LootEntry:
	if entries.is_empty():
		return null

	var total := 0
	for e in entries:
		total += e.weight
	if total <= 0:
		return entries[-1]

	var pick := randi_range(1, total)
	for e in entries:
		pick -= e.weight
		if pick <= 0:
			return e
	return entries[-1]


## Weighted pick restricted to [param minimum_rarity] or better.
## Falls back to a normal roll if nothing in the table qualifies.
func roll_rarity_or_better(minimum_rarity: Item.RARITY) -> LootEntry:
	if entries.is_empty():
		return null

	var total := 0
	for e in entries:
		if e.item and e.item.rarity >= minimum_rarity:
			total += e.weight
	if total <= 0:
		return roll()

	var pick := randi_range(1, total)
	for e in entries:
		if e.item and e.item.rarity >= minimum_rarity:
			pick -= e.weight
			if pick <= 0:
				return e
	return roll()
