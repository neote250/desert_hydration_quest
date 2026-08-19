extends Node

## Autoload. Owns the water model, the save file, and screen transitions.
##
## UNITS: every water volume in this game is millilitres. BottleSize.measurement
## is a display preference and is applied only at the UI layer.
##
## Design notes that used to live at the top of this file have moved to
## docs/design_notes.md so the code reads as code.

# --- Constants ------------------------------------------------------

var PLAYER_INVENTORY: InventoryData = preload("uid://bmeja72l4gf4g")
const SAVE_PATH := "user://save.tres"

const ML_PER_OZ := 29.5735
const KG_PER_LB := 0.4536

## Estimated volume of one sip. The player's notes put a sip at 0.2-0.5 oz;
## 15 ml is the middle of that. Everything downstream is an estimate built on
## this, which is why bottle progress is shown vaguely rather than as a number.
const DEFAULT_SIP_ML := 15.0

## One oasis loot roll is earned per this much water banked since the last refill.
const OASIS_ML_PER_ROLL := 250.0

## Drinking more than this inside [constant OVERDRINK_WINDOW_SEC] is unsafe and
## should be discouraged rather than rewarded.
const OVERDRINK_WARN_ML := 800.0
const OVERDRINK_WINDOW_SEC := 3600.0

const SECONDS_PER_DAY := 86400

## Playable events kept in the queue. Anything beyond this auto-resolves into
## loot so a full workday away doesn't leave 48 minigames stacked up.
const MAX_PENDING_EVENTS := 10

# --- State ----------------------------------------------------------

var saved_game: SaveGame = null

## Rolling log of (unix_time, ml) sips, used only for the overdrink check.
var _recent_sips: Array[Vector2] = []

## Guards the daily-goal celebration so it only fires once per day.
var _daily_goal_announced := false

## The job the player just finished. QuestGoal reads this on _ready rather than
## listening for job_completed - the signal fires before that scene exists.
var last_completed_job: Job = null


func _ready() -> void:
	_load_or_create_save()

	SignalManager.bottle_size_selected.connect(change_bottle_size)
	SignalManager.water_drunk.connect(drink)
	# The oasis pool button emits this. Previously nothing listened, so
	# refilling gave no reward and never banked the bottle.
	SignalManager.bottle_completed.connect(refill_at_oasis)
	SignalManager.job_accepted.connect(start_job)
	SignalManager.job_canceled.connect(cancel_job)


# Catch mobile app backgrounding and resuming.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			saved_game.previous_login = Time.get_unix_time_from_system()
			save()
		NOTIFICATION_APPLICATION_RESUMED:
			load_data()


# --- Save / load ----------------------------------------------------

func _load_or_create_save() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		saved_game = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if saved_game == null:
		saved_game = SaveGame.new()
	if saved_game.player_bottles.is_empty():
		saved_game.player_bottles.append(BottleSize.new())
	_restore_inventory()
	_roll_over_day_if_needed()
	catch_up_journey_events()


func save() -> void:
	
	saved_game.player_inventory = PLAYER_INVENTORY.duplicate(true)
	ResourceSaver.save(saved_game, SAVE_PATH)


func load_data() -> void:
	var loaded: SaveGame = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded == null:
		return
	saved_game = loaded
	_restore_inventory()
	_roll_over_day_if_needed()
	catch_up_journey_events()
	Ui.player_character.apply_decay()


## Copy the saved bag back into the live res:// inventory resource, so every
## existing reference to PLAYER_INVENTORY keeps working.
func _restore_inventory() -> void:
	if saved_game.player_inventory == null:
		return
	PLAYER_INVENTORY.slot_datas = saved_game.player_inventory.slot_datas.duplicate(true)
	PLAYER_INVENTORY.inventory_updated.emit(PLAYER_INVENTORY)


## Zero the daily counters when the calendar day changes.
func _roll_over_day_if_needed() -> void:
	var today := int(Time.get_unix_time_from_system()) / SECONDS_PER_DAY
	if saved_game.current_day == today:
		return
	saved_game.current_day = today
	saved_game.daily_total_ml = 0.0
	saved_game.bottles_completed_today.clear()
	_daily_goal_announced = false


# --- Bottles --------------------------------------------------------

## The bottle the player is currently drinking from. Always returns something.
func current_bottle() -> BottleSize:
	if saved_game.player_bottles.is_empty():
		saved_game.player_bottles.append(BottleSize.new())
	saved_game.current_player_bottle_index = clampi(
		saved_game.current_player_bottle_index, 0, saved_game.player_bottles.size() - 1
	)
	return saved_game.player_bottles[saved_game.current_player_bottle_index]


## Swap the current bottle for a different one.
## [param keep_progress] carries the sips already logged across to the new
## bottle — for swapping vessels mid-drink rather than starting fresh.
func change_bottle_size(bottle_given: BottleSize, keep_progress: bool) -> void:
	var carried := current_bottle().current_drunk_ml
	saved_game.player_bottles[saved_game.current_player_bottle_index] = bottle_given
	bottle_given.current_drunk_ml = carried if keep_progress else 0.0
	save()


# --- Drinking -------------------------------------------------------

## Log one sip. Everything water-related flows through here.
func drink(amount_ml: float = DEFAULT_SIP_ML) -> void:
	var bottle := current_bottle()
	bottle.current_drunk_ml += amount_ml
	saved_game.daily_total_ml += amount_ml
	saved_game.ml_since_last_oasis += amount_ml
	if saved_game.current_job:
		saved_game.job_progress_ml += amount_ml

	Ui.player_character.drank_water()
	SignalManager.bottle_progress_updated.emit(bottle.current_drunk_ml, bottle.volume_ml)

	if _is_overdrinking(amount_ml):
		SignalManager.overdrink_warning.emit(OVERDRINK_WARN_ML)

	_check_daily_goal()
	_check_job_goal()


## The player's own daily target is separate from any job goal — hitting it is
## a congratulation, not a scene change.
func _check_daily_goal() -> void:
	if _daily_goal_announced:
		return
	if saved_game.daily_total_ml >= saved_game.daily_goal_ml:
		_daily_goal_announced = true
		SignalManager.daily_goal_reached.emit(saved_game.bottles_completed_today)


## True if the player has crossed the safe intake rate in the recent window.
func _is_overdrinking(amount_ml: float) -> bool:
	var now := Time.get_unix_time_from_system()
	_recent_sips.append(Vector2(now, amount_ml))
	var total := 0.0
	var kept: Array[Vector2] = []
	for sip in _recent_sips:
		if now - sip.x <= OVERDRINK_WINDOW_SEC:
			kept.append(sip)
			total += sip.y
	_recent_sips = kept
	return total > OVERDRINK_WARN_ML


# --- Oasis ----------------------------------------------------------

## The player decided this bottle is done and refilled at the oasis.
## Banks the bottle, pays out the water drunk since the last refill, resets it.
func refill_at_oasis() -> void:
	var bottle := current_bottle()
	saved_game.bottles_completed_today.append(bottle.duplicate())

	var earned := _oasis_cash_out()

	bottle.current_drunk_ml = 0.0
	save()

	SignalManager.oasis_reward_granted.emit(earned)
	SignalManager.bottle_progress_updated.emit(0.0, bottle.volume_ml)


## Spend the banked water on loot rolls. One roll per OASIS_ML_PER_ROLL.
func _oasis_cash_out() -> Array[Item]:
	var roll_count := int(saved_game.ml_since_last_oasis / OASIS_ML_PER_ROLL)
	var loot_earned: Array[Item] = []

	for _i in roll_count:
		var slot_data := LootTables.roll(LootTables.TABLES.OASIS)
		if slot_data == null:
			continue
		if not PLAYER_INVENTORY.pickup_slot_data(slot_data):
			break  # bag is full; stop rolling rather than silently dropping loot
		loot_earned.append(slot_data.item_data)

	saved_game.ml_since_last_oasis = 0.0
	return loot_earned


# --- Jobs -----------------------------------------------------------

func start_job(job: Job) -> void:
	saved_game.current_job = job
	saved_game.job_progress_ml = 0.0
	saved_game.job_started_unix = Time.get_unix_time_from_system()
	saved_game.intervals_rolled = 0
	saved_game.pending_events.clear()
	saved_game.unseen_auto_loot.clear()
	NotificationManager.start_job_reminders(job.notification_interval_min)
	go_to(Screens.NAME.JOURNEY)


func cancel_job(_job: Job) -> void:
	# TODO: pay out reduced rewards for the portion completed.
	# Anything still queued pays out rather than evaporating.
	auto_resolve_all()
	saved_game.current_job = null
	NotificationManager.stop_job_reminders()
	go_to(saved_game.previous_town)


func _check_job_goal() -> void:
	var job := saved_game.current_job
	if job == null:
		return
	if saved_game.job_progress_ml >= job.water_goal_ml:
		complete_job()


func complete_job() -> void:
	var job := saved_game.current_job
	if job == null:
		return

	# Anything still queued pays out rather than evaporating.
	auto_resolve_all()

	saved_game.current_job = null
	last_completed_job = job
	NotificationManager.stop_job_reminders()

	if job.reward:
		PLAYER_INVENTORY.pickup_slot_data(SlotData.from_item(job.reward, job.reward_count))

	SignalManager.job_completed.emit(job)
	go_to(Screens.NAME.QUEST_GOAL)


## What the player earned for finishing the job, for the quest goal readout.
func job_reward_items(job: Job) -> Array[Item]:
	var items: Array[Item] = []
	if job and job.reward:
		for _i in job.reward_count:
			items.append(job.reward)
	return items


# --- Journey events -------------------------------------------------

## Turn every reminder interval that has elapsed since the job started into a
## queued event.
##
## The app cannot run code while it is closed, so events are rolled
## retroactively: we count how many intervals fit in the elapsed time, subtract
## the ones already rolled, and roll the difference. Being away costs the player
## nothing. Safe to call as often as you like — it is idempotent per interval.
func catch_up_journey_events() -> void:
	var job := saved_game.current_job
	if job == null or saved_game.job_started_unix <= 0.0:
		return

	var interval_sec := maxf(1.0, job.notification_interval_min * 60.0)
	if NotificationManager.debug_fast_reminders:
		interval_sec = maxf(1.0, float(job.notification_interval_min))

	var elapsed := Time.get_unix_time_from_system() - saved_game.job_started_unix
	var total_intervals := int(elapsed / interval_sec)
	var missed := total_intervals - saved_game.intervals_rolled
	if missed <= 0:
		return

	for i in missed:
		var when := saved_game.job_started_unix + (saved_game.intervals_rolled + i + 1) * interval_sec
		var event := _roll_event(when)
		if event.kind != JourneyEvent.KIND.NOTHING:
			saved_game.pending_events.append(event)

	saved_game.intervals_rolled = total_intervals
	_trim_pending_queue()
	save()


func _roll_event(when: float) -> JourneyEvent:
	var kind := JourneyEvents.roll_kind(randi())
	if kind == JourneyEvent.KIND.MINIGAME:
		return JourneyEvent.make(kind, when, JourneyEvents.random_minigame())
	return JourneyEvent.make(kind, when)


## Keep the backlog bounded. Oldest events past the cap pay out as loot instead
## of waiting to be played, and are held for one summary on return.
func _trim_pending_queue() -> void:
	while saved_game.pending_events.size() > MAX_PENDING_EVENTS:
		var overflow: JourneyEvent = saved_game.pending_events.pop_front()
		saved_game.unseen_auto_loot.append_array(_payout_for(overflow))


func pending_event_count() -> int:
	return saved_game.pending_events.size()


func next_event() -> JourneyEvent:
	if saved_game.pending_events.is_empty():
		return null
	return saved_game.pending_events[0]


## Take the next event off the queue. The caller decides what to do with it —
## journey.gd either grants the loot or launches the minigame.
func pop_next_event() -> JourneyEvent:
	if saved_game.pending_events.is_empty():
		return null
	var event: JourneyEvent = saved_game.pending_events.pop_front()
	save()
	return event


## Resolve one event without playing it, for the "I am busy" path. Returns the
## loot granted so the caller can show it.
func auto_resolve(event: JourneyEvent) -> Array[Item]:
	var loot := _payout_for(event)
	save()
	return loot


## Clear the whole queue for average loot. Also used when a job ends with
## events still pending, so nothing is silently thrown away.
func auto_resolve_all() -> Array[Item]:
	var loot: Array[Item] = []
	loot.append_array(saved_game.unseen_auto_loot)
	saved_game.unseen_auto_loot.clear()

	while not saved_game.pending_events.is_empty():
		var event: JourneyEvent = saved_game.pending_events.pop_front()
		loot.append_array(_payout_for(event))

	save()
	return loot


## Loot that auto-resolved while the player was away. Reading it clears it.
func take_unseen_auto_loot() -> Array[Item]:
	var loot: Array[Item] = saved_game.unseen_auto_loot.duplicate()
	saved_game.unseen_auto_loot.clear()
	return loot


func _payout_for(event: JourneyEvent) -> Array[Item]:
	match event.kind:
		JourneyEvent.KIND.FREE_LOOT:
			return grant_loot(LootTables.TABLES.OASIS, JourneyEvents.FREE_LOOT_ROLLS)
		JourneyEvent.KIND.MINIGAME:
			return grant_loot(
				JourneyEvents.loot_table_for(event.minigame), JourneyEvents.AUTO_RESOLVE_ROLLS
			)
		_:
			return []


## Roll a loot table [param rolls] times and put the results in the bag.
## Stops early if the bag fills up rather than dropping items on the floor.
func grant_loot(table: LootTables.TABLES, rolls: int) -> Array[Item]:
	var earned: Array[Item] = []
	for _i in rolls:
		var slot_data := LootTables.roll(table)
		if slot_data == null:
			continue
		if not PLAYER_INVENTORY.pickup_slot_data(slot_data):
			break
		earned.append(slot_data.item_data)
	return earned


# --- Screens --------------------------------------------------------

## Single entry point for changing screens. Records where the player is so a
## cold start can put them back there.
func go_to(screen: Screens.NAME) -> void:
	saved_game.current_screen = screen
	if screen in Screens.TOWNS:
		saved_game.previous_town = screen
	save()
	get_tree().change_scene_to_packed(Screens.PACKED[screen])


# --- Crafting -------------------------------------------------------

## Returns false (and consumes nothing) if the player can't afford the recipe
## or has no room for the result.
func craft(recipe: Recipe) -> bool:
	if not PLAYER_INVENTORY.can_afford(recipe):
		return false
	PLAYER_INVENTORY.consume(recipe)

	if recipe.output is ItemCosmetic:
		own_cosmetic(recipe.output)
		SignalManager.cosmetic_crafted.emit(recipe.output)
	else:
		var result := SlotData.from_item(recipe.output, recipe.output_count)
		if not PLAYER_INVENTORY.pickup_slot_data(result):
			_refund(recipe)
			return false
		SignalManager.item_crafted.emit(recipe.output, recipe.output_count)

	save()
	return true


func _refund(recipe: Recipe) -> void:
	for ing in recipe.ingredients:
		PLAYER_INVENTORY.pickup_slot_data(SlotData.from_item(ing.material, ing.count))


# --- Cosmetics ------------------------------------------------------

## Add to the player's wardrobe. Returns false if it was already owned.
func own_cosmetic(item: ItemCosmetic) -> bool:
	if item in saved_game.owned_cosmetics:
		return false
	saved_game.owned_cosmetics.append(item)
	return true


func owned_cosmetics() -> Array[ItemCosmetic]:
	return saved_game.owned_cosmetics


func equipped_in(slot_type: ItemCosmetic.SLOT_TYPE) -> ItemCosmetic:
	return saved_game.equipped.get(slot_type)


## Equip, or unequip if this exact item is already in the slot.
func equip(item: ItemCosmetic) -> void:
	if saved_game.equipped.get(item.slot_type) == item:
		saved_game.equipped.erase(item.slot_type)
	else:
		saved_game.equipped[item.slot_type] = item
	SignalManager.cosmetic_equipped.emit(item.slot_type, saved_game.equipped.get(item.slot_type))
	save()
