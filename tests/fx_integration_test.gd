# FXIntegrationTest.gd
#
# Purpose: Test scene for FX and Audio systems
# Usage: Run this scene in Godot to test all 4 systems
#
# Tests:
#   - Camera shake (priority, decay)
#   - Audio (positional, global, pool expansion)
#   - Impact effects (particles, cleanup)
#   - Projectile (movement, piercing, collision)

extends Node2D

#region Test Configuration
@export var test_auto_start: bool = false
@export var test_delay: float = 1.0
#endregion

#region Test State
var _test_timer: float = 0.0
var _current_test: int = 0
var _tests: Array[Callable] = []
#endregion

#region Node References
@onready var camera: Camera2D = $Camera2D
@onready var test_target: Area2D = $TestTarget
@onready var ui: CanvasLayer = $UI
@onready var log_label: RichTextLabel = $UI/LogLabel
#endregion


func _ready():
	"""Initialize test suite."""
	# Hide debug overlay
	var debug = get_node_or_null("/root/DebugOverlay")
	if debug:
		debug.hide()
	
	_setup_tests()
	_log("FX Integration Test Ready")
	_log("Press number keys to run tests:")
	_log("1 - Camera Shake Test")
	_log("2 - Audio Test (requires audio files)")
	_log("3 - Impact Effect Test")
	_log("4 - Projectile Test")
	_log("5 - Full Combat Sequence")
	_log("0 - Run All Tests")
	
	if test_auto_start:
		await get_tree().create_timer(test_delay).timeout
		_run_all_tests()


func _input(event):
	"""Handle test input."""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_test_camera_shake()
			KEY_2:
				_test_audio()
			KEY_3:
				_test_impact_fx()
			KEY_4:
				_test_projectile()
			KEY_5:
				_test_full_sequence()
			KEY_0:
				_run_all_tests()


#region Test Setup

func _setup_tests() -> void:
	"""Register all test functions."""
	_tests = [
		_test_camera_shake,
		_test_audio,
		_test_impact_fx,
		_test_projectile,
		_test_full_sequence
	]


func _log(message: String) -> void:
	"""Log to both console and UI."""
	print("[FX Test] " + message)
	if log_label:
		log_label.append_text(message + "\n")

#endregion


#region Test 1: Camera Shake

func _test_camera_shake() -> void:
	"""Test camera shake with different priorities."""
	_log("=== Camera Shake Test ===")
	
	# Test 1: Basic shake (STRONGER for visibility)
	_log("Test 1: Basic shake (1.0 strength, 0.8s) - WATCH SCREEN!")
	CameraShaker.shake(1.0, 0.8, 0)
	await get_tree().create_timer(1.0).timeout
	
	# Test 2: High priority shake should interrupt
	_log("Test 2: High priority interrupt")
	CameraShaker.shake(0.3, 1.0, 0)  # Low priority, long
	await get_tree().create_timer(0.1).timeout
	CameraShaker.shake(1.5, 0.5, 5)  # High priority, should interrupt
	await get_tree().create_timer(0.6).timeout
	
	# Test 3: Low priority should NOT interrupt
	_log("Test 3: Low priority blocked by high priority")
	CameraShaker.shake(1.2, 0.5, 5)  # High priority
	await get_tree().create_timer(0.1).timeout
	CameraShaker.shake(0.3, 0.5, 0)  # Low priority, should be ignored
	await get_tree().create_timer(0.6).timeout
	
	_log("Camera Shake Test Complete")

#endregion


#region Test 2: Audio

func _test_audio() -> void:
	"""Test audio manager (requires audio files)."""
	_log("=== Audio Test ===")
	
	# Note: This test requires actual audio files
	# Load placeholder or actual SFX
	var test_sfx = load("res://assets/sfx/test_sound.wav") if ResourceLoader.exists("res://assets/sfx/test_sound.wav") else null
	
	if test_sfx == null:
		_log("WARNING: No test audio file found at res://assets/sfx/test_sound.wav")
		_log("Skipping audio test - add audio files to test")
		return
	
	# Test 1: Global SFX
	_log("Test 1: Global SFX")
	AudioManager.play_sfx_global(test_sfx, 0.0, 1.0)
	await get_tree().create_timer(0.5).timeout
	
	# Test 2: Positional SFX
	_log("Test 2: Positional SFX at (100, 100)")
	AudioManager.play_sfx(test_sfx, Vector2(100, 100), 0.0, 1.0, 5)
	await get_tree().create_timer(0.5).timeout
	
	# Test 3: Multiple rapid SFX (pool test)
	_log("Test 3: Rapid SFX (pool stress test)")
	for i in 10:
		AudioManager.play_sfx(test_sfx, Vector2(randf_range(-200, 200), randf_range(-200, 200)), -10.0, 1.0, i % 10)
		await get_tree().create_timer(0.05).timeout
	
	await get_tree().create_timer(1.0).timeout
	_log("Audio Test Complete")

#endregion


#region Test 3: Impact Effects

func _test_impact_fx() -> void:
	"""Test impact effect spawning."""
	_log("=== Impact Effect Test ===")
	
	# Test 1: Blood splash
	_log("Test 1: Blood Splash x3")
	for i in 3:
		var fx = preload("res://scenes/effects/blood_splash.tscn").instantiate()
		fx.global_position = Vector2(randf_range(-150, 150), randf_range(-100, 100))
		fx.rotation = randf() * TAU
		add_child(fx)
		await get_tree().create_timer(0.2).timeout
	
	await get_tree().create_timer(1.0).timeout
	
	# Test 2: Hit spark
	_log("Test 2: Hit Spark x3")
	for i in 3:
		var fx = preload("res://scenes/effects/hit_spark.tscn").instantiate()
		fx.global_position = Vector2(randf_range(-150, 150), randf_range(-100, 100))
		fx.rotation = randf() * TAU
		add_child(fx)
		await get_tree().create_timer(0.2).timeout
	
	await get_tree().create_timer(1.5).timeout
	_log("Impact Effect Test Complete")

#endregion


#region Test 4: Projectile

func _test_projectile() -> void:
	"""Test projectile spawning and behavior."""
	_log("=== Projectile Test ===")
	
	# Test 1: Basic projectile
	_log("Test 1: Basic projectile (no pierce)")
	_spawn_projectile(Vector2(-200, 0), Vector2.RIGHT, 0)
	await get_tree().create_timer(1.0).timeout
	
	# Test 2: Piercing projectile
	_log("Test 2: Piercing projectile (pierce=2)")
	_spawn_projectile(Vector2(-200, 50), Vector2.RIGHT, 2)
	await get_tree().create_timer(1.0).timeout
	
	# Test 3: Multiple directions
	_log("Test 3: 8-directional projectiles")
	for i in 8:
		var angle = i * PI / 4
		var dir = Vector2.RIGHT.rotated(angle)
		_spawn_projectile(Vector2.ZERO + dir * 50, dir, 0)
		await get_tree().create_timer(0.1).timeout
	
	await get_tree().create_timer(2.0).timeout
	_log("Projectile Test Complete")


func _spawn_projectile(pos: Vector2, dir: Vector2, pierce_count: int) -> void:
	"""Helper to spawn a test projectile."""
	var proj = preload("res://scenes/combat/projectile.tscn").instantiate()
	proj.global_position = pos
	proj.setup(dir, 25.0, 200.0)
	proj.pierce = pierce_count
	proj.impact_fx = preload("res://scenes/effects/hit_spark.tscn")
	proj.target_groups = ["test_target"]
	proj.hit.connect(_on_projectile_hit)
	add_child(proj)


func _on_projectile_hit(target: Node2D, pos: Vector2) -> void:
	"""Handle projectile hit."""
	_log("Projectile HIT at " + str(pos))
	print("TEST: Projectile hit confirmed at ", pos)

#endregion


#region Test 5: Full Sequence

func _test_full_sequence() -> void:
	"""Test full combat sequence with all systems."""
	_log("=== Full Combat Sequence Test ===")
	
	# Spawn projectile that will hit target
	_log("Firing projectile...")
	var proj = preload("res://scenes/combat/projectile.tscn").instantiate()
	proj.global_position = Vector2(-200, 0)
	proj.setup(Vector2.RIGHT, 50.0, 300.0)
	proj.pierce = 0
	proj.impact_fx = preload("res://scenes/effects/blood_splash.tscn")
	proj.target_groups = ["test_target"]
	
	# Connect to see the full chain
	proj.hit.connect(func(target, pos):
		_log("Hit! Damage applied, FX spawned, camera should shake")
	)
	
	add_child(proj)
	
	await get_tree().create_timer(2.0).timeout
	_log("Full Sequence Test Complete")

#endregion


#region Test Runner

func _run_all_tests() -> void:
	"""Run all tests in sequence."""
	_log("\n=== RUNNING ALL TESTS ===\n")
	
	for test in _tests:
		await test.call()
		await get_tree().create_timer(0.5).timeout
	
	_log("\n=== ALL TESTS COMPLETE ===")

#endregion
