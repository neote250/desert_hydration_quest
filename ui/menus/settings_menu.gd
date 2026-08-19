extends Control


##Settings values?
#Haptic feedback
#volume



func _on_delete_save_button_pressed() -> void:
	self.hide()
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists("save.tres"):
		var err := dir.remove("save.tres")
		if err != OK:
			push_warning("Could not delete save: %d" % err)
			return
	_reset_runtime_state()
	get_tree().change_scene_to_file("res://screens/main.tscn")


func _reset_runtime_state() -> void:
	GameManager.saved_game = SaveGame.new()
	GameManager.saved_game.player_bottles.append(BottleSize.new())
	GameManager.PLAYER_INVENTORY.slot_datas.clear()
	GameManager.PLAYER_INVENTORY.inventory_updated.emit(GameManager.PLAYER_INVENTORY)
	GameManager.last_completed_job = null
	GameManager._daily_goal_announced = false
	GameManager._recent_sips.clear()
	NotificationManager.stop_job_reminders()


func _on_close_button_pressed() -> void:
	self.hide()
