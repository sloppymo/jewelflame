@tool
extends EditorScript

## Run via: Tools → Execute Script
## Generates: res://assets/animations/heavy_knight_thrust_nodash.tres
##            res://assets/animations/heavy_knight_thrust_dash.tres
##
## Both thrust sheets share IDENTICAL dimensions and structure:
##   Size:  256 x 128 px  |  RGBA
##   Frame: 32 x 32 px
##   Grid:  8 cols x 4 rows = 32 total frames each
##
## MIRROR ROWS (mathematically confirmed, identical on both sheets):
##   R00 vs R01: flipped_diff = 0.0 → thrust_left = thrust_right mirrored
##   R02 vs R03: flipped_diff = 62.2 → DISTINCT (down and up are unique poses)
##
## IMPACT FRAMES (white sword-flash pixel detection):
##   Frames 0-2: wind-up / approach  (0 white pixels)
##   Frame 3:    impact begins       (~31-34 white pixels)
##   Frame 4:    peak impact         (~29-44 white pixels) ← deal damage here
##   Frames 5-6: follow-through      (trailing flash)
##   Frame 7:    recovery            (0 white pixels)
##
## NODASH vs DASH difference:
##   Both sheets have same pixel mass X centers across all 8 frames.
##   Dash version has very slightly different mid-animation X distribution
##   (character displacement during frames 3-6), but the difference is subtle.
##   Use nodash for stationary attacks, dash for attacks that move the character.

func _run() -> void:
	var fw := 32
	var fh := 32

	# [anim_name, start_row, num_frames, fps, loop]
	var animations: Array = [
		# Impact frames 3-4 (white flash peaks). Deal damage at frame 4.
		# R00/R01 are mirrors. R02/R03 are distinct (down/up).
		["thrust_right",  0,  8, 12.0, false],
		["thrust_left",   1,  8, 12.0, false],  # mirror of thrust_right
		["thrust_down",   2,  8, 12.0, false],
		["thrust_up",     3,  8, 12.0, false],
	]

	# ── Generate NO-DASH version ───────────────────────────────────────────────
	var nodash_path := "res://assets/Citizens - Guards - Warriors/Warriors/Heavy_Knight_Thrust_Attack_Non-Dash-Version.png"
	var nodash_out  := "res://assets/animations/heavy_knight_thrust_nodash.tres"

	var tex_nd := load(nodash_path)
	if tex_nd == null:
		push_error("Cannot load: " + nodash_path)
	else:
		var sf_nd := SpriteFrames.new()
		sf_nd.remove_animation("default")
		_populate(sf_nd, tex_nd, animations, fw, fh)
		var err := ResourceSaver.save(sf_nd, nodash_out)
		if err == OK:
			print("[OK] Saved nodash: ", nodash_out)
		else:
			push_error("ResourceSaver failed for nodash")

	# ── Generate DASH version ──────────────────────────────────────────────────
	var dash_path := "res://assets/Citizens - Guards - Warriors/Warriors/Heavy_Knight_Thrust_Dash_Attack.png"
	var dash_out  := "res://assets/animations/heavy_knight_thrust_dash.tres"

	var tex_d := load(dash_path)
	if tex_d == null:
		push_error("Cannot load: " + dash_path)
	else:
		var sf_d := SpriteFrames.new()
		sf_d.remove_animation("default")
		_populate(sf_d, tex_d, animations, fw, fh)
		var err2 := ResourceSaver.save(sf_d, dash_out)
		if err2 == OK:
			print("[OK] Saved dash: ", dash_out)
		else:
			push_error("ResourceSaver failed for dash")


func _populate(sf: SpriteFrames, tex: Texture2D, anims: Array, fw: int, fh: int) -> void:
	for anim_data in anims:
		var anim_name   : String = anim_data[0]
		var start_row   : int    = anim_data[1]
		var num_frames  : int    = anim_data[2]
		var fps         : float  = anim_data[3]
		var should_loop : bool   = anim_data[4]

		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, fps)
		sf.set_animation_loop(anim_name, should_loop)

		for col in range(num_frames):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * fw, start_row * fh, fw, fh)
			atlas.filter_clip = true
			sf.add_frame(anim_name, atlas)
