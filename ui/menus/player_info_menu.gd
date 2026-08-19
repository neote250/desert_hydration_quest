extends Control

## Onboarding step: name and weight. Weight feeds the recommended daily goal.

## Rough guideline: about 30 ml of water per kg of body weight per day.
const ML_PER_KG_PER_DAY := 30.0

@onready var name_input: LineEdit = %NameInput
@onready var weight_sb: SpinBox = %WeightSB
@onready var weight_option_btn: OptionButton = %WeightOptionBtn


func _on_name_input_text_changed(new_text: String) -> void:
	GameManager.saved_game.username = new_text


func _on_weight_sb_value_changed(value: float) -> void:
	GameManager.saved_game.weight = value
	_update_recommended_goal()


func _on_weight_option_btn_item_selected(index: int) -> void:
	GameManager.saved_game.weight_is_lb = index == 0
	_update_recommended_goal()


## Suggest a daily target from body weight. The player can still override it.
func _update_recommended_goal() -> void:
	var save := GameManager.saved_game
	var kg: float = save.weight * GameManager.KG_PER_LB if save.weight_is_lb else save.weight
	save.daily_goal_ml = kg * ML_PER_KG_PER_DAY
