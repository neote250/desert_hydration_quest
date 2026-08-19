# How to apply

This zip contains ONLY the 34 files that changed, at their correct paths
relative to your project root. Nothing else in your project is touched.

## Option A — extract over the project (simplest)

Unzip into
`C:\Workspace\GodotProjects\GameEnginesClass\oasis-in-a-desert-adventure\`
and let it overwrite.

Then delete `APPLY_THESE_CHANGES.diff` and `APPLY_README.md` from the project
folder - they're only here for convenience.

## Option B — git apply

If the project is a git repo, from the project root:

    git apply --stat  APPLY_THESE_CHANGES.diff   # preview
    git apply --check APPLY_THESE_CHANGES.diff   # verify it applies cleanly
    git apply         APPLY_THESE_CHANGES.diff

The diff was generated against a copy with `addons/`, `android/` and `.godot/`
excluded; none of those are touched.

## Then, in the Godot editor

1. Delete `old_inventory_interface.gd` (root) and `ui/menus/shop.gd`.
   Both have been replaced with deprecation stubs so the project still parses;
   the originals are preserved in `.archive/`, which Godot ignores.
2. Optionally move `player_character.gd` into `ui/` (use the FileSystem dock so
   the `.uid` follows it). It was left at the root deliberately - writing it to
   `ui/` while the root copy still existed would have created a duplicate
   `class_name PlayerCharacter` and broken the parse.
3. Connect `MeasurementOptionBtn`'s `item_selected` signal in
   `bottle_selection_menu.tscn` to `_on_measurement_option_btn_item_selected`.

## Delete your old save first

`SaveGame`'s fields changed names and types, and none of them were ever
actually being written (they lacked `@export`). Any existing `user://save.tres`
will not load cleanly - delete it before the first run.

## Still scene work, not script work

- Job board needs the notification-interval SpinBox + label.
- `quest_goal.tscn` is still a bare Control; `quest_goal.gd` has the hooks.
- Nothing listens to `SignalManager.overdrink_warning` yet.
