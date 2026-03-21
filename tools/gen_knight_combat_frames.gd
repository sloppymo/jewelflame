@tool
extends EditorScript

## Run via: Tools → Execute Script
## Generates: res://assets/animations/knight_combat.tres
##
## SOURCE SHEET SPECS:
##   File:  2-Handed_Swordsman_Combat.png
##   Size:  128 x 384 px
##   Frame: 32 x 32 px
##   Grid:  4 cols x 12 rows
##
## ROWS:
##   00-07: attack_light (8 directions)
##   08-15: attack_heavy (8 directions)
##   16-23: hurt (8 directions)

func _run() -> void:
	var tex_path := "res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Combat.png"
	var out_path := "res://assets/animations/knight_combat.tres"

	var texture := load(tex_path)
	if texture == null:
		push_error("Cannot load: " + tex_path)
		return

	var sf := SpriteFrames.new()
	sf.remove_animation("default")

	var fw := 32
	var fh := 32

	# Direction order in the sheet
	var dirs: Array[String] = ["s", "n", "se", "ne", "e", "w", "sw", "nw"]

	# [anim_base, start_row, fps]
	var anim_groups: Array = [
		["attack_light", 0,  12.0],
		["attack_heavy", 8,  10.0],
		["hurt",         16, 8.0],
	]

	for group in anim_groups:
		var base_name : String = group[0]
		var base_row  : int    = group[1]
		var fps       : float  = group[2]

		for i in range(8):
			var dir: String = dirs[i]
			var anim_name := base_name + "_" + dir
			var row := base_row + i

			sf.add_animation(anim_name)
			sf.set_animation_speed(anim_name, fps)
			sf.set_animation_loop(anim_name, false)

			for col in range(4):
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(col * fw, row * fh, fw, fh)
				atlas.filter_clip = true
				sf.add_frame(anim_name, atlas)

	var err := ResourceSaver.save(sf, out_path)
	if err == OK:
		print("[OK] Saved: ", out_path)
		print("     Animations: ", sf.get_animation_names().size())
	else:
		push_error("ResourceSaver failed: " + str(err))
