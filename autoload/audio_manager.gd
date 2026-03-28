# AudioManager.gd
#
# Purpose: Efficient audio pooling with 2D positional audio and bus management
# Autoload: Yes (registered in project.godot)
# Depends: None (self-contained)
#
# Usage:
#   Positional: AudioManager.play_sfx(stream, global_position, 0.0, 1.0, 5)
#   Global:     AudioManager.play_sfx_global(stream, 0.0, 1.0)
#   Music:      AudioManager.play_music(stream, -10.0)
#
# Required Audio Buses (create in Godot Editor if not exist):
#   - Master
#   - Music
#   - SFX
#
# Implementation based on Kimberlyclaw's professional review
# Date: 2026-03-25

extends Node

#region Exported Configuration
## Initial pool size for SFX players (expands on demand)
@export var pool_size: int = 8

## Maximum distance for 2D audio falloff
@export var max_distance: float = 1000.0

## Default volume for music (dB)
@export var music_volume_db: float = -10.0
#endregion

#region Private State
var _sfx_players: Array[AudioStreamPlayer2D] = []
var _music_player: AudioStreamPlayer = null
var _original_music_volume: float = 0.0
#endregion


func _ready():
	"""Initialize the audio manager with pools and music player."""
	# Create initial SFX pool
	_expand_pool(pool_size)
	
	# Setup dedicated music player
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	add_child(_music_player)


#region Public API - Positional SFX

func play_sfx(stream: AudioStream, pos: Vector2, volume_db: float = 0.0, 
			 pitch_scale: float = 1.0, priority: int = 0) -> AudioStreamPlayer2D:
	"""Play a sound effect at a world position.
	
	Args:
		stream: The audio stream to play
		pos: World position for the sound
		volume_db: Volume in decibels (0.0 = normal)
		pitch_scale: Pitch multiplier (1.0 = normal, 0.5 = half speed, 2.0 = double)
		priority: 0=low (can be interrupted), 10=critical (always plays, expands pool)
	
	Returns:
		The AudioStreamPlayer2D instance, or null if couldn't play
	"""
	if stream == null:
		push_warning("AudioManager: Attempted to play null stream")
		return null
	
	var player = _get_player(priority)
	if player == null:
		return null  # Pool full and low priority
	
	player.stream = stream
	player.global_position = pos
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.max_distance = max_distance
	player.attenuation = 1.0  # Linear falloff
	player.play()
	
	# Auto-return to pool when done
	if not player.finished.is_connected(_return_player):
		player.finished.connect(_return_player.bind(player), CONNECT_ONE_SHOT)
	
	return player


func play_sfx_with_pitch_variation(stream: AudioStream, pos: Vector2, 
								   volume_db: float = 0.0, 
								   pitch_variation: float = 0.1,
								   priority: int = 0) -> AudioStreamPlayer2D:
	"""Play SFX with random pitch variation for variety.
	
	Args:
		stream: The audio stream to play
		pos: World position
		volume_db: Volume in decibels
		pitch_variation: Random variation range (0.1 = ±10%)
		priority: Priority level
	"""
	var pitch = 1.0 + randf_range(-pitch_variation, pitch_variation)
	return play_sfx(stream, pos, volume_db, pitch, priority)

#endregion


#region Public API - Global SFX (UI, Ambient)

func play_sfx_global(stream: AudioStream, volume_db: float = 0.0, 
					 pitch_scale: float = 1.0) -> AudioStreamPlayer:
	"""Play a non-positional sound (UI, ambient) that self-destructs.
	
	Args:
		stream: The audio stream to play
		volume_db: Volume in decibels
		pitch_scale: Pitch multiplier
	
	Returns:
		The AudioStreamPlayer instance
	"""
	if stream == null:
		push_warning("AudioManager: Attempted to play null stream")
		return null
	
	var player = AudioStreamPlayer.new()
	player.name = "GlobalSFX_" + str(Time.get_ticks_msec())
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.bus = "SFX"
	add_child(player)
	player.play()
	
	# Self-destruct when done
	player.finished.connect(player.queue_free)
	
	return player

#endregion


#region Public API - Music

func play_music(stream: AudioStream, fade_duration: float = 1.0) -> void:
	"""Play background music with optional crossfade.
	
	Args:
		stream: The music stream to play
		fade_duration: Seconds to fade in/out
	"""
	if stream == null:
		push_warning("AudioManager: Attempted to play null music stream")
		return
	
	if _music_player.playing:
		# Fade out current, then fade in new
		var tween = create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, fade_duration * 0.5)
		tween.tween_callback(_switch_music.bind(stream, fade_duration * 0.5))
	else:
		# Just fade in
		_switch_music(stream, fade_duration)


func stop_music(fade_duration: float = 1.0) -> void:
	"""Stop music with fade out.
	
	Args:
		fade_duration: Seconds to fade out
	"""
	if not _music_player.playing:
		return
	
	var tween = create_tween()
	tween.tween_property(_music_player, "volume_db", -80.0, fade_duration)
	tween.tween_callback(_music_player.stop)
	tween.tween_callback(func(): _music_player.volume_db = music_volume_db)


func set_music_volume(volume_db: float) -> void:
	"""Set music volume immediately.
	
	Args:
		volume_db: Volume in decibels (0.0 = max, -80.0 = silent)
	"""
	music_volume_db = volume_db
	if _music_player:
		_music_player.volume_db = volume_db


func pause_music() -> void:
	"""Pause music playback."""
	if _music_player:
		_music_player.stream_paused = true


func resume_music() -> void:
	"""Resume music playback."""
	if _music_player:
		_music_player.stream_paused = false

#endregion


#region Private Methods

func _expand_pool(count: int) -> void:
	"""Add new players to the SFX pool."""
	for i in count:
		var player = AudioStreamPlayer2D.new()
		player.name = "SFXPlayer_" + str(_sfx_players.size())
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)


func _get_player(priority: int) -> AudioStreamPlayer2D:
	"""Get an available SFX player, optionally expanding pool for high priority."""
	# Find available player
	for player in _sfx_players:
		if not player.playing:
			return player
	
	# All busy - expand pool for high priority
	if priority >= 5:
		var new_index = _sfx_players.size()
		_expand_pool(2)  # Add 2 more players
		return _sfx_players[new_index]
	
	# Low priority, no slots free - steal from oldest (first in array)
	if priority >= 1:
		var oldest = _sfx_players[0]
		oldest.stop()
		return oldest
	
	return null  # Too low priority, drop the sound


func _return_player(player: AudioStreamPlayer2D) -> void:
	"""Reset player state for reuse."""
	if player == null:
		return
	player.position = Vector2.ZERO
	player.volume_db = 0.0
	player.pitch_scale = 1.0
	player.stream = null


func _switch_music(stream: AudioStream, fade_in_duration: float) -> void:
	"""Switch music stream and fade in."""
	_music_player.stream = stream
	_music_player.volume_db = -80.0  # Start silent
	_music_player.play()
	
	var tween = create_tween()
	tween.tween_property(_music_player, "volume_db", music_volume_db, fade_in_duration)

#endregion
