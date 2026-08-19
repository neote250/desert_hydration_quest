class_name Screens
extends RefCounted

## Central registry of every full-screen scene in the game.
##
## This lives outside GameManager so that other scripts — SaveGame in
## particular — can refer to [enum Screens.NAME] as a real type. An autoload
## singleton is an object, not a type, so `GameManager.SCREEN_NAME` cannot be
## used in an @export declaration.
##
## Onboarding is deliberately absent: it is reached exactly once, directly from
## main.gd, and nothing should ever route back to it.

enum NAME {
	ROOM,
	JOURNEY,
	OASIS,
	GUILD_HALL,
	QUEST_GOAL,
	SCORPION_NEST_MG,
	FREE_LOOT_MG,
}

const PACKED := {
	NAME.ROOM: preload("res://screens/room.tscn"),
	NAME.JOURNEY: preload("res://screens/journey.tscn"),
	NAME.OASIS: preload("res://screens/oasis.tscn"),
	NAME.GUILD_HALL: preload("res://screens/guild_hall.tscn"),
	NAME.QUEST_GOAL: preload("res://screens/quest_goal.tscn"),
	NAME.SCORPION_NEST_MG: preload("res://minigames/scorpion_nest_mg.tscn"),
	NAME.FREE_LOOT_MG: preload("res://minigames/free_loot_mg.tscn"),
}

## Screens the player can be sent "home" to after a job ends.
const TOWNS: Array[NAME] = [NAME.ROOM, NAME.GUILD_HALL]
