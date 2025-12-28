extends Node

const SAVE_PATH = "user://game_save.tres"

signal save_loaded(save_data: GameSave)

var current_save: GameSave

func _ready():
	load_game()

func save_game():
	if not current_save:
		current_save = GameSave.new()

	current_save.last_save_timestamp = Time.get_unix_time_from_system()

	var error = ResourceSaver.save(current_save, SAVE_PATH)
	if error != OK:
		print("Error saving game: ", error)
	else:
		print("Game saved successfully")

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found, creating new game")
		current_save = GameSave.new()
		save_loaded.emit(current_save)
		return

	var loaded_save = ResourceLoader.load(SAVE_PATH) as GameSave
	if not loaded_save:
		print("Error loading save file, creating new game")
		current_save = GameSave.new()
	else:
		current_save = loaded_save
		print("Game loaded successfully")

	save_loaded.emit(current_save)

func get_save() -> GameSave:
	return current_save

func calculate_offline_earnings(offline_seconds: float) -> int:
	if not current_save or current_save.cats_on_field.is_empty():
		return 0

	var total_earnings = 0
	for saved_cat in current_save.cats_on_field:
		var rate = 1.0 * pow(saved_cat.level, 1.5)  # Base rate calculation
		var earnings_per_second = rate / 5.0  # Base 5 second interval
		var earnings = earnings_per_second * offline_seconds
		total_earnings += earnings * 0.5  # 50% efficiency when offline

	return int(total_earnings)

func get_total_cats_spawned() -> int:
	return current_save.total_cats_spawned if current_save else 0

func increment_cats_spawned():
	if current_save:
		current_save.total_cats_spawned += 1