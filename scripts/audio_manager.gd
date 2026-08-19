extends Node

# Persistent music player
@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

# Pool for overlap-safe SFX playback
var sfx_players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8

func _ready() -> void:
	# 1. Setup Music Player
	music_player.bus = &"Music"
	add_child(music_player)
	
	# 2. Setup SFX Player Pool
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		sfx_players.append(player)

## Play background music seamlessly across scenes
func play_music(stream: AudioStream, fade_duration: float = 0.5) -> void:
	if music_player.stream == stream and music_player.playing:
		return

	# If music is currently playing and a fade time is requested, fade out first
	if music_player.playing and fade_duration > 0.0:
		var tween = create_tween()
		
		# 1. Fade volume to silent (-80 dB)
		tween.tween_property(music_player, "volume_db", -80.0, fade_duration * 0.5)
		
		# 2. Swap stream and play
		tween.tween_callback(func():
			music_player.stream = stream
			music_player.play()
		)
		
		# 3. Fade volume back up to full (0 dB)
		tween.tween_property(music_player, "volume_db", 0.0, fade_duration * 0.5)
	else:
		# Direct play if nothing was playing or fade_duration is 0
		music_player.volume_db = 0.0
		music_player.stream = stream
		music_player.play()

## Play 2D/UI SFX with optional random pitch variation to avoid monotony
func play_sfx(stream: AudioStream, pitch_min: float = 0.95, pitch_max: float = 1.05) -> void:
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = randf_range(pitch_min, pitch_max)
			player.play()
			return
