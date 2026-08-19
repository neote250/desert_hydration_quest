class_name SaveGame
extends Resource

## Everything that survives closing the app.
##
## IMPORTANT: only @export'ed properties are written by ResourceSaver. A plain
## `var` here will silently vanish on save/load, which is what was happening to
## this whole resource before.
##
## All water volumes are stored in millilitres.

# --- Player profile -------------------------------------------------

@export var username: String = "player"
## Player weight in whichever unit [member weight_is_lb] selects.
@export var weight: float = 170.0
@export var weight_is_lb: bool = true
## True once onboarding has been completed at least once.
@export var previous_save: bool = false

# --- Bottles --------------------------------------------------------

@export var player_bottles: Array[BottleSize] = []
@export var current_player_bottle_index: int = 0
## Snapshots of each bottle the player finished today, for the end-of-day recap.
@export var bottles_completed_today: Array[BottleSize] = []

# --- Water totals (all ml) ------------------------------------------

## Total drunk today. Reset by GameManager on day rollover.
@export var daily_total_ml: float = 0.0
## The player's own daily target, set during onboarding.
@export var daily_goal_ml: float = 2500.0
## Banked since the last oasis refill; spent as loot rolls when they cash out.
@export var ml_since_last_oasis: float = 0.0
## Drunk toward the current job's goal.
@export var job_progress_ml: float = 0.0

# --- Journey events -------------------------------------------------

## When the current job started, so missed reminder intervals can be counted.
@export var job_started_unix: float = 0.0
## How many reminder intervals have already been turned into events. Prevents
## the same interval being rolled twice across resumes.
@export var intervals_rolled: int = 0
## Events waiting for the player. Survives the app being closed - that is the
## whole point of rolling them retroactively.
@export var pending_events: Array[JourneyEvent] = []
## Loot that auto-resolved while the player was away (queue overflow), waiting
## to be shown once on return.
@export var unseen_auto_loot: Array[Item] = []

# --- Session / timing -----------------------------------------------

## 0.0 = fully dehydrated (max red tint), 1.0 = fully hydrated.
@export var player_hydration: float = 1.0
## Unix timestamp of the last time the app was backgrounded.
@export var previous_login: float = 0.0
## Unix day index the daily totals belong to, so they reset at midnight.
@export var current_day: int = 0

# --- Where the player was -------------------------------------------

@export var current_screen: Screens.NAME = Screens.NAME.ROOM
@export var previous_town: Screens.NAME = Screens.NAME.GUILD_HALL
@export var current_job: Job = null

# --- Progression ----------------------------------------------------

## A snapshot of the player's bag. GameManager keeps the live InventoryData in
## [constant GameManager.PLAYER_INVENTORY] (a res:// resource, which is
## read-only once exported to Android), and mirrors it in and out of here.
@export var player_inventory: InventoryData = null

## Cosmetics moved here from GameManager so they actually persist.
@export var owned_cosmetics: Array[ItemCosmetic] = []
## ItemCosmetic.SLOT_TYPE -> ItemCosmetic
@export var equipped: Dictionary = {}
