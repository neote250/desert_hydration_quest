class_name Job
extends Resource

## A job is a gamified water goal: drink [member water_goal_ml] and you finish it.

enum JOB_TYPE {
	## Short outing, ~1 bottle. Accelerometer walk for bonus loot, boss minigame.
	HUNT,
	## The default. A regular day out, refills and bottle swaps expected.
	QUEST,
	## Full day, passive. For players who don't want to open the app much.
	DELIVERY,
}

@export var name: String = ""
@export var job_type: JOB_TYPE = JOB_TYPE.QUEST
@export_multiline var description: String = ""

## How much water finishing this job takes, in ml.
## (Roughly: HUNT ~500, QUEST ~1000, DELIVERY ~2500.)
@export var water_goal_ml: float = 1000.0

## Minutes between drink reminders while this job is active. The player
## overrides this on the job board before accepting; 10 is the recommendation.
@export_range(5, 240, 5) var notification_interval_min: int = 10

@export var reward: Item
@export_range(1, 99) var reward_count: int = 1

@export var unlock_hint: String = ""
