@tool
extends EditorScript

func _run():
	var combat_img = load("res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Combat.png")
	var noncombat_img = load("res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Non-Combat.png")
	
	if not combat_img or not noncombat_img:
		print("ERROR: Could not load images")
		return
	
	print("Combat image size: ", combat_img.get_size())
	print("Non-combat image size: ", noncombat_img.get_size())
	
	# Just print info about first few frames to verify slicing
	print("\nChecking attack frames (row 0, cols 0-3):")
	for col in range(4):
		var region = Rect2i(col * 16, 0, 16, 16)
		print("Col ", col, " region: ", region)
