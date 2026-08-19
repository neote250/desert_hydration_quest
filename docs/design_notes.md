# Oasis in a Desert Adventure — design notes

Moved out of the top of `game_manager.gd` so that file reads as code.

## Units

Every water volume in the game is **millilitres**. `BottleSize.measurement` is a
display preference and is applied only at the UI layer, via
`BottleSize.to_display()` / `from_display()` / `format_volume()`.

A sip is estimated at ~15 ml (the player's own notes put it at 0.2–0.5 oz).
Because that is an estimate, bottle progress is never shown as a hard number —
the oasis mirage just fades in as the estimate approaches the bottle's capacity,
and the player decides when the bottle is actually done.

## New player setup

- Player chooses an avatar (adventurer / merchant / …) — stretch goal
- Player gives weight, or skips
- Player sets a hydration goal (offer an estimate from weight; ~30 ml/kg/day)
- Player sets the size of their first bottle
- Player chooses a liquid (water, juice, milk …) for efficiency toward the goal — stretch goal

## Bottles

- The player can hold up to ~5 bottle sizes and equip one to drink from
- Bottles can be created, modified, or deleted during play
- Swapping a bottle mid-drink carries progress across (`keep_progress`)
- Dumping the rest clears the bottle's progress

## Gameplay loop

1. Player starts in their room
2. Leaves via the stairs texture button → guild hall
3. Clicks the job clerk → job board
4. Picks a job. A job is a water goal plus a reminder cadence:
   - **Long / Delivery** — passive, whole day, option for no minigames
   - **Medium / Quest** — the default; average minigames, engaged play
   - **Short / Hunt** — boss minigame at the end, accelerometer run for a bigger
     monster and better loot
   - Reminder interval is chosen on the board (10 min recommended)
   - A job can be ended early for reduced rewards
5. Character sets out → journey screen (splash, animation, occasional tips)
6. Reminders fire at the chosen interval. Each one rolls:
   - a critter / scenery animation (nothing)
   - free loot (a hidden cache)
   - a minigame (may be saved for later or skipped for average loot)
   - *(not implemented yet — see `journey.job_event_happened()`)*
7. The longer the player waits to press Drink, the redder the character gets.
   Each drink pushes the tint back.
8. When the bottle is done, the player refills at the oasis. That cashes out the
   water banked since the last refill as loot rolls — time-gated by design, so
   sipping is encouraged over chugging.
9. When the job's water goal is met → quest goal screen with rewards.
10. Then either journey back or auto-transport to the previous town. **Undecided.**

## Open questions

- Does hitting the *daily* goal deserve its own screen, or just the celebration
  it currently gets? (`SignalManager.daily_goal_reached`)
- Overdrinking: `GameManager` detects >800 ml in an hour and emits
  `overdrink_warning`. Nothing listens yet. What should it do — refuse to log
  the sip, log it but pay no loot, or just warn?
- After the quest goal screen: journey back, or auto-transport?

## Not in the MVP

- `ui/menus/custom_quest_menu.*` — player-defined goals. Parked.
- The material shop (buy stock with currency, rotates daily). The *crafter*
  exists as `shop_interface`; the shop clerk button is still a no-op.
- Room animation spots (RestSpot / WorkSpot / FunSpot).
