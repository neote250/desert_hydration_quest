extends Node2D

##Transition to game scene
#Countdown for game start
# - show story blurb while waiting (such as accidently stumbled on desert scourge nest hunting grounds)
#Monsters start out small and increase in size to signify them getting closer
#pick a diagonal and they also travel in that direction while getting closer
#player tries to line up a targetting reticle, using the virtual joystick, with the approaching monsters
#player presses touch screen button when target is lined up with monster
#quick animation of monster being blown up
#If monster reaches x size, they hit the player
#If the player takes y hits or z monsters have been killed or left after hitting player, the minigame ends
#For each monster killed they get a roll on the minigame's loot table
# - calculate this after each kill and put it in players inventory so loot is always distributed
#Show off the loot earned during this minigame to the player in a report of sorts
#Handle clean up and then transition back to journey scene

enum State { COUNTDOWN, PLAYING, REPORT, DONE }

@onready var virtual_joystick: VirtualJoystick = $GameUI/VirtualJoystick
@onready var touch_screen_button: TouchScreenButton = $GameUI/TouchScreenButton
@onready var reticle:= $Reticle

@onready var countdown_label := $GameUI/CountdownLabel
@onready var story_label := $GameUI/StoryLabel
@onready var monster_container := $Monsters
@onready var report_panel := $GameUI/ReportPanel

@export var speed:= 500.0
@export var countdown_time := 3.0
@export var max_player_hits := 3
@export var monsters_to_resolve := 10
@export var spawn_interval := 1.5
@export var hit_radius := 48.0

var intro:= "Stumbled on a nest, freeze the attacking bats!"

var state: State = State.COUNTDOWN
var player_hits := 0
var monsters_resolved := 0
var loot_earned: Array[Item] = []

const monster_scene = preload("uid://ju7k66vphm8")

func _ready() -> void:
	enter()

func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return
	var input_vec := Input.get_vector("ui_left", "ui_right","ui_up", "ui_down")
	reticle.position += input_vec * speed * delta
	reticle.position = reticle.position.clamp(Vector2.ZERO, get_viewport_rect().size)


func enter()-> void:
	Ui.drink_button.visible = false
	reticle.position =  get_viewport_rect().size / 2.0
	story_label.text = intro
	_start_countdown()

func exit() -> void:
	Ui.drink_button.visible = true
	# A Node isn't iterable — you have to ask it for its children. No need to
	# disconnect first; queue_free() drops the node's connections with it.
	for monster in monster_container.get_children():
		monster.queue_free()
	GameManager.go_to(Screens.NAME.JOURNEY)



# --- Countdown -------------------------------------------------

func _start_countdown() -> void:
	state = State.COUNTDOWN
	countdown_label.visible = true
	story_label.visible = true
	for i in range(int(countdown_time), 0, -1):
		countdown_label.text = str(i)
		await get_tree().create_timer(1.0).timeout
	countdown_label.visible = false
	story_label.visible = false
	_start_game()


# --- Game loop -------------------------------------------------

func _start_game() -> void:
	state = State.PLAYING
	_spawn_loop()

func _spawn_loop() -> void:
	while state == State.PLAYING:
		_spawn_monster()
		await get_tree().create_timer(spawn_interval).timeout

func _spawn_monster() -> void:
	var m = monster_scene.instantiate()
	monster_container.add_child(m)
	m.setup(get_viewport_rect().size)
	m.reached_player.connect(_on_monster_reached_player.bind(m))

func _on_touch_screen_button_pressed() -> void:
	if state != State.PLAYING:
		return
	_try_shoot()

func _try_shoot() -> void:
	# find closest monster within hit_radius of the reticle
	var best: Node2D = null
	var best_dist := hit_radius
	for m in monster_container.get_children():
		var d = reticle.position.distance_to(m.position)
		if d < best_dist:
			best_dist = d
			best = m
	if best:
		_kill_monster(best)
	# else: TODO maybe play a "miss" sound/flash

func _kill_monster(m: Node2D) -> void:
	m.die()
	monsters_resolved += 1
	_roll_loot()
	_check_end_conditions()

func _on_monster_reached_player(m: Node2D) -> void:
	player_hits += 1
	monsters_resolved += 1
	# TODO: screen shake / damage flash
	m.leave()
	_check_end_conditions()

func _check_end_conditions() -> void:
	if player_hits >= max_player_hits or monsters_resolved >= monsters_to_resolve:
		_end_game()

# --- Loot ------------------------------------------------------

func _roll_loot() -> void:
	var slot_data := LootTables.roll(LootTables.TABLES.NEST_MG)
	if slot_data == null:
		return
	if GameManager.PLAYER_INVENTORY.pickup_slot_data(slot_data):
		loot_earned.append(slot_data.item_data)
	
# --- End / report ----------------------------------------------

func _end_game() -> void:
	state = State.REPORT
	for m in monster_container.get_children():
		m.queue_free()
	_show_report()

func _show_report() -> void:
	report_panel.visible = true
	report_panel.populate(loot_earned, "Nest cleared!")
	await report_panel.dismissed
	state = State.DONE
	exit()
