extends Node

## PlaceholderGenerator - Creates simple placeholder graphics for testing

static func create_placeholder_sprite(name: String, size: Vector2, color: Color, label: String = "") -> Image:
	var img = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Draw background rectangle
	var rect_color = color
	_draw_rect(img, Rect2(0, 0, size.x, size.y), rect_color)
	
	# Draw border
	_draw_rect(img, Rect2(0, 0, size.x, size.y), Color(1, 1, 1, 0.5), false, 2)
	
	# Draw label (simple text representation)
	if label != "":
		_draw_text_placeholder(img, label, size)
	
	return img

static func _draw_rect(img: Image, rect: Rect2, color: Color, filled: bool = true, thickness: int = 1) -> void:
	var x1 = int(rect.position.x)
	var y1 = int(rect.position.y)
	var x2 = int(rect.position.x + rect.size.x)
	var y2 = int(rect.position.y + rect.size.y)
	
	if filled:
		for y in range(y1, y2):
			for x in range(x1, x2):
				img.set_pixel(x, y, color)
	else:
		# Top and bottom
		for x in range(x1, x2):
			for t in range(thickness):
				if y1 + t < y2:
					img.set_pixel(x, y1 + t, color)
				if y2 - 1 - t >= y1:
					img.set_pixel(x, y2 - 1 - t, color)
		# Left and right
		for y in range(y1, y2):
			for t in range(thickness):
				if x1 + t < x2:
					img.set_pixel(x1 + t, y, color)
				if x2 - 1 - t >= x1:
					img.set_pixel(x2 - 1 - t, y, color)

static func _draw_text_placeholder(img: Image, text: String, size: Vector2) -> void:
	# Simple block letter representation
	var chars = text.to_upper()
	var char_width = max(8, size.x / chars.length())
	var char_height = min(16, size.y / 2)
	var start_x = (size.x - chars.length() * char_width) / 2
	var start_y = (size.y - char_height) / 2
	
	for i, char in enumerate(chars):
		var cx = int(start_x + i * char_width)
		var cy = int(start_y)
		_draw_char_block(img, char, Vector2(cx, cy), char_width, char_height, Color(1, 1, 1, 0.8))

static func _draw_char_block(img: Image, char: String, pos: Vector2, w: int, h: int, color: Color) -> void:
	# Very basic character blocks
	var patterns = {
		"A": [[1,1,1],[1,0,1],[1,1,1],[1,0,1],[1,0,1]],
		"B": [[1,1,0],[1,0,1],[1,1,0],[1,0,1],[1,1,0]],
		"C": [[1,1,1],[1,0,0],[1,0,0],[1,0,0],[1,1,1]],
		"D": [[1,1,0],[1,0,1],[1,0,1],[1,0,1],[1,1,0]],
		"E": [[1,1,1],[1,0,0],[1,1,0],[1,0,0],[1,1,1]],
		"F": [[1,1,1],[1,0,0],[1,1,0],[1,0,0],[1,0,0]],
		"G": [[1,1,1],[1,0,0],[1,0,1],[1,0,1],[1,1,1]],
		"H": [[1,0,1],[1,0,1],[1,1,1],[1,0,1],[1,0,1]],
		"I": [[1,1,1],[0,1,0],[0,1,0],[0,1,0],[1,1,1]],
		"K": [[1,0,1],[1,0,1],[1,1,0],[1,0,1],[1,0,1]],
		"L": [[1,0,0],[1,0,0],[1,0,0],[1,0,0],[1,1,1]],
		"M": [[1,0,1],[1,1,1],[1,1,1],[1,0,1],[1,0,1]],
		"N": [[1,0,1],[1,1,1],[1,1,1],[1,1,1],[1,0,1]],
		"O": [[1,1,1],[1,0,1],[1,0,1],[1,0,1],[1,1,1]],
		"P": [[1,1,1],[1,0,1],[1,1,1],[1,0,0],[1,0,0]],
		"R": [[1,1,1],[1,0,1],[1,1,1],[1,0,1],[1,0,1]],
		"S": [[1,1,1],[1,0,0],[1,1,1],[0,0,1],[1,1,1]],
		"T": [[1,1,1],[0,1,0],[0,1,0],[0,1,0],[0,1,0]],
		"U": [[1,0,1],[1,0,1],[1,0,1],[1,0,1],[1,1,1]],
		"W": [[1,0,1],[1,0,1],[1,1,1],[1,1,1],[1,0,1]],
		"Y": [[1,0,1],[1,0,1],[0,1,0],[0,1,0],[0,1,0]],
	}
	
	var pattern = patterns.get(char, [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]])
	var block_w = w / 3
	var block_h = h / 5
	
	for py, row in enumerate(pattern):
		for px, val in enumerate(row):
			if val == 1:
				var bx = int(pos.x + px * block_w)
				var by = int(pos.y + py * block_h)
				for y in range(by, by + block_h):
					for x in range(bx, bx + block_w):
						if x < img.get_width() and y < img.get_height():
							img.set_pixel(x, y, color)

static func generate_all_placeholders() -> void:
	var base_path = "res://assets/placeholder/"
	DirAccess.make_dir_recursive_absolute(base_path)
	
	# Character placeholders
	var char_anims = ["idle", "walk", "run", "crouch", "aim", "melee", "reload", "death"]
	for anim in char_anims:
		var img = create_placeholder_sprite("player_%s" % anim, Vector2(64, 128), Color(0.4, 0.3, 0.2, 1), "PLAYER")
		img.save_png(base_path + "player_%s.png" % anim)
	
	# Zombie placeholders
	var zombie_types = ["walker", "runner", "tank", "screamer", "crawler"]
	var zombie_colors = {
		"walker": Color(0.3, 0.25, 0.2, 1),
		"runner": Color(0.4, 0.2, 0.15, 1),
		"tank": Color(0.2, 0.2, 0.25, 1),
		"screamer": Color(0.35, 0.15, 0.2, 1),
		"crawler": Color(0.25, 0.2, 0.15, 1)
	}
	
	for ztype in zombie_types:
		var color = zombie_colors.get(ztype, Color(0.3, 0.25, 0.2, 1))
		var zsize = Vector2(64, 128) if ztype != "crawler" else Vector2(80, 60)
		var anims = ["idle", "walk", "run", "attack", "death"]
		if ztype == "runner":
			anims.append("lunge")
		elif ztype == "tank":
			anims.extend(["charge", "slam"])
		elif ztype == "screamer":
			anims.append("scream")
		elif ztype == "crawler":
			anims.append("pounce")
		
		for anim in anims:
			var img = create_placeholder_sprite("%s_%s" % [ztype, anim], zsize, color, ztype.to_upper())
			img.save_png(base_path + "%s_%s.png" % [ztype, anim])
	
	# Weapon placeholders
	var weapons = {
		"pistol": Vector2(48, 24),
		"shotgun": Vector2(80, 24),
		"rifle": Vector2(96, 24),
		"baseball_bat": Vector2(64, 16),
		"knife": Vector2(48, 12),
		"fire_axe": Vector2(56, 32)
	}
	
	for name, size in weapons:
		var img = create_placeholder_sprite(name, size, Color(0.3, 0.25, 0.2, 1), name.to_upper())
		img.save_png(base_path + "%s.png" % name)
	
	# Item placeholders
	var items = [
		"bandage", "medkit", "antibiotics", "painkillers",
		"water_bottle", "dirty_water", "canned_food", "energy_bar",
		"raw_meat", "cooked_meat", "pistol_ammo", "shotgun_ammo",
		"rifle_ammo", "scrap_metal", "wood", "cloth", "chemicals",
		"electronics", "duct_tape", "rope", "battery", "flashlight",
		"lockpick", "repair_kit", "molotov", "trap", "noise_maker",
		"backpack", "barricade_kit", "advanced_barricade"
	]
	
	for item in items:
		var img = create_placeholder_sprite(item, Vector2(32, 32), Color(0.4, 0.35, 0.3, 1), item.to_upper()[0])
		img.save_png(base_path + "%s.png" % item)
	
	# UI icons
	var ui_icons = ["map_safehouse", "map_mission", "map_exit"]
	for icon in ui_icons:
		var img = create_placeholder_sprite(icon, Vector2(24, 24), Color(0.5, 0.5, 0.5, 1), "")
		img.save_png(base_path + "%s.png" % icon)
	
	print("Generated all placeholder assets to %s" % base_path)