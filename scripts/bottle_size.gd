class_name BottleSize
extends Resource

## A single drinking vessel the player owns.
##
## ALL volumes are stored in millilitres. [member measurement] is a display
## preference only — it never changes what is stored, just how it is shown.

enum MEASUREMENT { OZ, ML }

const ML_PER_OZ := 29.5735

@export var label: String = "Medium"

## Capacity of this bottle, in ml. (500 ml ~ a typical 16.9 oz bottle.)
@export var volume_ml: float = 500.0

## Estimated amount drunk from this bottle since it was last filled, in ml.
@export var current_drunk_ml: float = 0.0

## Display unit only. Does not affect any stored value.
@export var measurement: MEASUREMENT = MEASUREMENT.ML


## How full the bottle is estimated to be, 0.0 (fresh) to 1.0 (about empty).
## This is an estimate built from sip counts, so callers should treat it as
## a hint for visuals rather than a hard truth.
func fill_ratio() -> float:
	if volume_ml <= 0.0:
		return 0.0
	return current_drunk_ml / volume_ml


## Convert an internal ml value into the player's chosen display unit.
func to_display(ml: float) -> float:
	return ml / ML_PER_OZ if measurement == MEASUREMENT.OZ else ml


## Convert a number the player typed in their chosen unit back into ml.
func from_display(value: float) -> float:
	return value * ML_PER_OZ if measurement == MEASUREMENT.OZ else value


func unit_suffix() -> String:
	return "oz" if measurement == MEASUREMENT.OZ else "ml"


## Format an ml value for the UI, e.g. "16.9 oz" or "500 ml".
func format_volume(ml: float) -> String:
	if measurement == MEASUREMENT.OZ:
		return "%.1f oz" % to_display(ml)
	return "%d ml" % roundi(ml)
