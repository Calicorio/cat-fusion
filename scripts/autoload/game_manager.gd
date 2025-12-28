extends Node

signal currency_changed(new_amount: int)
signal cat_spawned(cat: Node2D)
signal fusion_completed(result_cat: Node2D, level: int)
signal spawn_timer_updated(current_time: float, max_time: float)
signal player_touched(touch_position: Vector2)

@export var currency: int = 0
@export var cats_on_field: Array = []
@export var spawn_timer: float = 0.0
@export var current_spawn_interval: float = 30.0

var game_config: Dictionary
var progression_data: Dictionary
var cat_data_library: Dictionary = {}
var fusion_mode_active: bool = false
var selected_fusion_cats: Array = []
var room_ball: Node2D = null  # Reference to the room's ball for cat play behavior

func _ready():
	load_game_config()
	load_progression_data()
	setup_cat_data_library()
	SaveManager.save_loaded.connect(_on_save_loaded)

func _process(delta):
	update_spawn_timer(delta)

func load_game_config():
	var file = FileAccess.open("res://data/config/game_config.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			game_config = json.data
			print("Game config loaded successfully")
		else:
			print("Error parsing game config")
	else:
		print("Error loading game config")

func load_progression_data():
	var file = FileAccess.open("res://data/config/progression_design.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			progression_data = json.data
			print("Progression data loaded successfully")
			if progression_data.has("cats"):
				print("  - Found %d cats in progression data" % progression_data.cats.size())
			if progression_data.has("tiers"):
				print("  - Found %d tiers" % progression_data.tiers.size())
		else:
			print("Error parsing progression data: %s" % json.get_error_message())
			progression_data = {}
	else:
		print("Error loading progression data file")
		progression_data = {}

func setup_cat_data_library():
	# Load all 30 cat levels from progression data
	if progression_data.has("cats") and progression_data.cats is Array:
		for cat_entry in progression_data.cats:
			var cat_data = CatData.new()
			cat_data.id = int(cat_entry.level)
			cat_data.level = int(cat_entry.level)
			cat_data.name = str(cat_entry.name)
			cat_data.tier = str(cat_entry.tier)
			cat_data.archetype = str(cat_entry.archetype)
			cat_data.base_currency_rate = float(cat_entry.base_rate)

			# Get tier info for behaviors and size
			var tier_info = get_tier_info(cat_entry.tier)
			if tier_info.has("behaviors") and tier_info.behaviors is Array:
				cat_data.behavior_set = tier_info.behaviors.duplicate()
			else:
				cat_data.behavior_set = ["idle", "walk", "sit", "meow"]

			var size_mult = float(tier_info.get("size_multiplier", 1.0))
			cat_data.sprite_size = Vector2(32, 32) * size_mult

			var rarity_str = str(tier_info.get("rarity_color", "#FFFFFF"))
			cat_data.rarity_color = Color.from_string(rarity_str, Color.WHITE)

			cat_data_library[cat_data.level] = cat_data
		print("Loaded %d cat levels" % cat_data_library.size())
	else:
		# Fallback to basic generation if no progression data
		print("No cats array found in progression data, using fallback")
		_setup_fallback_cat_library()

func _setup_fallback_cat_library():
	print("Using fallback cat library")
	for level in range(1, 31):
		var cat_data = CatData.new()
		cat_data.id = level
		cat_data.level = level
		cat_data.name = "Cat Level %d" % level
		cat_data.base_currency_rate = 1.0
		cat_data.sprite_size = Vector2(32, 32)
		cat_data.behavior_set = ["idle", "walk", "sit", "meow", "play"]
		cat_data.tier = get_tier_for_level(level)
		cat_data_library[level] = cat_data
	print("Fallback library created with %d levels" % cat_data_library.size())

func get_tier_for_level(level: int) -> String:
	if level <= 5:
		return "kitten"
	elif level <= 10:
		return "house"
	elif level <= 15:
		return "fancy"
	elif level <= 20:
		return "mystical"
	elif level <= 25:
		return "legendary"
	else:
		return "cosmic"

func get_tier_info(tier_name: String) -> Dictionary:
	if progression_data.has("tiers") and progression_data.tiers.has(tier_name):
		return progression_data.tiers[tier_name]
	# Fallback defaults
	return {
		"size_multiplier": 1.0,
		"rarity_color": "#FFFFFF",
		"behaviors": ["idle", "walk", "sit", "meow", "play"]
	}

func _on_save_loaded(save_data: GameSave):
	currency = save_data.player_currency
	currency_changed.emit(currency)

	# Calculate offline earnings
	var current_time = Time.get_unix_time_from_system()
	var offline_time = current_time - save_data.last_save_timestamp
	if offline_time > 60: # Only if offline for more than 1 minute
		var offline_earnings = SaveManager.calculate_offline_earnings(offline_time)
		if offline_earnings > 0:
			add_currency(offline_earnings)
			show_offline_earnings_notification(offline_earnings, offline_time)

func show_offline_earnings_notification(earnings: int, time_offline: float):
	var hours = int(time_offline / 3600)
	@warning_ignore("integer_division")
	var minutes = int((int(time_offline) % 3600) / 60)
	var time_string = ""
	if hours > 0:
		time_string = "%dh %dm" % [hours, minutes]
	else:
		time_string = "%dm" % minutes

	print("Welcome back! You were away for %s and earned %d Tunca Cans!" % [time_string, earnings])

func add_currency(amount: int):
	currency += amount
	currency_changed.emit(currency)

	# Update save
	var save = SaveManager.get_save()
	if save:
		save.player_currency = currency

func update_spawn_timer(delta):
	spawn_timer -= delta
	spawn_timer_updated.emit(spawn_timer, current_spawn_interval)

	if spawn_timer <= 0:
		attempt_spawn_cat()

func attempt_spawn_cat():
	var max_cats = 10  # Default
	if game_config.has("spawn_settings"):
		var spawn_settings = game_config.spawn_settings
		if spawn_settings is Dictionary and spawn_settings.has("max_cats_on_screen"):
			max_cats = int(spawn_settings.max_cats_on_screen)

	if cats_on_field.size() >= max_cats:
		spawn_timer = 5.0  # Try again in 5 seconds
		return

	spawn_new_cat()
	calculate_next_spawn_time()

func spawn_new_cat():
	print("Attempting to spawn new cat...")
	var new_cat = create_cat(1)  # Always spawn level 1
	if new_cat:
		cats_on_field.append(new_cat)
		cat_spawned.emit(new_cat)
		SaveManager.increment_cats_spawned()
		print("Cat spawned successfully!")
	else:
		print("Failed to spawn cat!")

func create_cat(level: int) -> Node2D:
	if not cat_data_library.has(level):
		print("ERROR: No cat data for level %d. Available levels: %s" % [level, cat_data_library.keys()])
		return null

	var cat_scene = preload("res://cat.tscn")
	var cat_instance = cat_scene.instantiate()
	var cat_data = cat_data_library[level]
	cat_instance.setup_cat(cat_data)

	return cat_instance

func calculate_next_spawn_time():
	var base_time = 20.0
	var multiplier = 1.15
	var max_time = 300.0

	if game_config.has("spawn_settings"):
		var spawn_settings = game_config.spawn_settings
		if spawn_settings is Dictionary:
			base_time = float(spawn_settings.get("base_spawn_time", 20.0))
			multiplier = float(spawn_settings.get("spawn_time_multiplier", 1.15))
			max_time = float(spawn_settings.get("max_spawn_time", 300.0))

	var spawn_count = SaveManager.get_total_cats_spawned()
	# Formula: base * (multiplier ^ (spawn_count * 0.05)), capped at max_time
	# Slower growth rate (0.05) for smoother progression
	current_spawn_interval = min(base_time * pow(multiplier, spawn_count * 0.05), max_time)
	spawn_timer = current_spawn_interval

func attempt_fusion(cat1: Node2D, cat2: Node2D) -> bool:
	if not cat1 or not cat2 or cat1 == cat2:
		return false

	var level1 = cat1.get_level()
	var level2 = cat2.get_level()

	if level1 != level2:
		print("Fusion failed: Cats must be the same level")
		return false

	var new_level = level1 + 1
	if not cat_data_library.has(new_level):
		print("Fusion failed: No data for level ", new_level)
		return false

	# Calculate fusion position
	var fusion_position = (cat1.global_position + cat2.global_position) / 2

	# Remove old cats
	remove_cat(cat1)
	remove_cat(cat2)

	# Create new cat
	var fused_cat = create_cat(new_level)
	if fused_cat:
		fused_cat.global_position = fusion_position
		cats_on_field.append(fused_cat)

		# Currency bonus
		var bonus = calculate_fusion_bonus(new_level)
		add_currency(bonus)

		fusion_completed.emit(fused_cat, new_level)

		# Update highest level reached
		var save = SaveManager.get_save()
		if save:
			save.highest_level_reached = max(save.highest_level_reached, new_level)
			save.cats_fused_count += 1

		print("Fusion successful! Created level %d cat. Bonus: %d Tunca Cans" % [new_level, bonus])
		return true

	return false

func calculate_fusion_bonus(level: int) -> int:
	var base_rate = 1.0
	var rate_exponent = game_config.currency_settings.rate_exponent if game_config.has("currency_settings") else 1.5

	# Get tier-based bonus percentage
	var tier = get_tier_for_level(level)
	var bonus_percentage = 0.1
	if game_config.has("fusion_settings") and game_config.fusion_settings.has("tier_bonus_multipliers"):
		var tier_bonuses = game_config.fusion_settings.tier_bonus_multipliers
		if tier_bonuses.has(tier):
			bonus_percentage = tier_bonuses[tier]

	var hourly_production = base_rate * pow(level, rate_exponent) * 720  # 720 = 3600 / 5 (5 second intervals)
	return int(hourly_production * bonus_percentage)

func remove_cat(cat: Node2D):
	if cat in cats_on_field:
		cats_on_field.erase(cat)

	if cat.get_parent():
		cat.get_parent().remove_child(cat)

	cat.queue_free()

func register_fusion_candidate(cat: Node2D):
	if cat in selected_fusion_cats:
		return

	selected_fusion_cats.append(cat)

	if selected_fusion_cats.size() >= 2:
		var cat1 = selected_fusion_cats[0]
		var cat2 = selected_fusion_cats[1]
		selected_fusion_cats.clear()

		# Clear visual selection
		for selected_cat in [cat1, cat2]:
			if selected_cat and selected_cat.has_method("set_selected"):
				selected_cat.set_selected(false)

		attempt_fusion(cat1, cat2)

func clear_fusion_selection():
	for cat in selected_fusion_cats:
		if cat and cat.has_method("set_selected"):
			cat.set_selected(false)
	selected_fusion_cats.clear()

func get_cat_data(level: int) -> CatData:
	return cat_data_library.get(level)

func broadcast_player_touch(touch_pos: Vector2):
	player_touched.emit(touch_pos)