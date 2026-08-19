extends Node2D
class_name DriftingMonster

signal reached_player

@export var start_scale := 0.2
@export var max_scale := 1.5      # "x size" = hits the player
@export var grow_time := 10.0      # seconds from spawn to reaching player
@export var drift_speed := 60.0

var drift_dir := Vector2.ZERO
var elapsed := 0.0
var alive := true

func setup(viewport_size: Vector2) -> void:
	# spawn somewhere in the middle-ish of the screen
	position = Vector2(
		randf_range(viewport_size.x * 0.2, viewport_size.x * 0.8),
		randf_range(viewport_size.y * 0.2, viewport_size.y * 0.8)
	)
	scale = Vector2.ONE * start_scale
	# pick a random diagonal
	drift_dir = [
		Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)
	].pick_random().normalized()

func _physics_process(delta: float) -> void:
	if not alive:
		return
	elapsed += delta
	# grow toward the player over time
	var t = clamp(elapsed / grow_time, 0.0, 1.0)
	scale = Vector2.ONE * lerp(start_scale, max_scale, t)
	position += drift_dir * drift_speed * delta
	if t >= 1.0:
		alive = false
		reached_player.emit()

func die() -> void:
	alive = false
	# TODO: play kill animation, then free
	# $AnimationPlayer.play("explode")
	# await $AnimationPlayer.animation_finished
	queue_free()

func leave() -> void:
	# TODO: fly-away animation after hitting player
	queue_free()
