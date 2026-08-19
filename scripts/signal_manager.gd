extends Node

## Autoload. Cross-scene events only.
##
## Rule of thumb: if GameManager can just call the thing directly (it and Ui are
## both autoloads), do that instead of adding a signal here. Signals earn their
## place when a scene that may or may not exist needs to react.

# --- Water ----------------------------------------------------------

## Player picked or created a bottle. [param keep_progress] carries the sips
## already logged over to the new bottle.
signal bottle_size_selected(bottle: BottleSize, keep_progress: bool)

## A sip was taken. [param amount_ml] is always millilitres.
signal water_drunk(amount_ml: float)

## Emitted on every sip and on refill. Drives the oasis mirage opacity.
signal bottle_progress_updated(current_drunk_ml: float, volume_ml: float)

## The player refilled at the oasis (i.e. declared the bottle finished).
signal bottle_completed

## Loot paid out for the water banked since the last refill.
signal oasis_reward_granted(loot: Array[Item])

## The player's own daily target was reached.
signal daily_goal_reached(bottles_today: Array[BottleSize])

## Intake crossed the safe rate. UI should discourage, not celebrate.
signal overdrink_warning(limit_ml: float)

# --- Jobs -----------------------------------------------------------

signal job_accepted(job: Job)
signal job_canceled(job: Job)
signal job_completed(job: Job)

# --- Items ----------------------------------------------------------

signal item_crafted(item: Item, count: int)
signal item_used(item: Item)
signal loot_granted(slot_data: SlotData)

signal cosmetic_crafted(item: ItemCosmetic)
signal cosmetic_equipped(slot_type: ItemCosmetic.SLOT_TYPE, item: ItemCosmetic)

# --- UI panels ------------------------------------------------------

signal toggle_inventory
signal toggle_crafting
signal toggle_job_board
