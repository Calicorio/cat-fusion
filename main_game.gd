extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var environment: Node2D = $Environment
@onready var cat_container: Node2D = $CatManager/CatContainer
@onready var room_background: Sprite2D = $Environment/RoomBackground

# UI elements directly embedded
@onready var currency_label: Label = $UI/GameHUD/VBox/CurrencyLabel
@onready var spawn_progress: ProgressBar = $UI/GameHUD/VBox/SpawnProgress
@onready var spawn_timer_label: Label = $UI/GameHUD/VBox/SpawnTimerLabel
@onready var info_label: Label = $UI/GameHUD/VBox/InfoLabel

# Settings UI
@onready var settings_button: Button = $UI/GameHUD/SettingsButton
@onready var settings_panel: PanelContainer = $UI/GameHUD/SettingsPanel
@onready var music_slider: HSlider = $UI/GameHUD/SettingsPanel/VBox/MusicSlider
@onready var sfx_slider: HSlider = $UI/GameHUD/SettingsPanel/VBox/SFXSlider
@onready var close_button: Button = $UI/GameHUD/SettingsPanel/VBox/CloseButton

var room_bounds: Rect2 = Rect2(50, 100, 700, 400)
var room_ball: Node2D = null

func _ready():
	setup_camera()
	setup_room()
	spawn_ball()
	connect_signals()
	start_first_spawn()
	# Start background music with a short delay for smooth loading
	get_tree().create_timer(0.5).timeout.connect(AudioManager.start_background_music)

func spawn_ball():
	var ball_scene = preload("res://ball.tscn")
	room_ball = ball_scene.instantiate()
	room_ball.global_position = Vector2(400, 350)  # Center of room
	room_ball.set_room_bounds(room_bounds)
	add_child(room_ball)

	# Register ball with GameManager so cats can find it
	GameManager.room_ball = room_ball

func _input(event: InputEvent):
	# Capture touch/click events for "look at player" behavior
	if event is InputEventScreenTouch and event.pressed:
		GameManager.broadcast_player_touch(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GameManager.broadcast_player_touch(event.position)

func setup_camera():
	if camera:
		camera.position = Vector2(400, 300)
		camera.zoom = Vector2(1, 1)

func setup_room():
	create_room_background()

func create_room_background():
	if room_background:
		# Create a cozy room background
		var texture = ImageTexture.new()
		var image = Image.create(800, 600, false, Image.FORMAT_RGB8)

		# Fill with a cozy wallpaper color
		image.fill(Color(0.95, 0.9, 0.85))  # Warm cream

		# === WALL (top area with subtle pattern) ===
		for x in range(800):
			for y in range(100):
				# Subtle vertical stripe wallpaper pattern
				var stripe_val = 0.0 if (x / 20) % 2 == 0 else 0.02
				var base_color = Color(0.88 + stripe_val, 0.82 + stripe_val, 0.76 + stripe_val)
				image.set_pixel(x, y, base_color)

		# === MAIN WALL AREA ===
		for x in range(800):
			for y in range(100, 480):
				# Subtle vertical stripe wallpaper
				var stripe_val = 0.0 if (x / 20) % 2 == 0 else 0.015
				var base_color = Color(0.92 + stripe_val, 0.87 + stripe_val, 0.82 + stripe_val)
				image.set_pixel(x, y, base_color)

		# === WINDOW (on left side) ===
		_draw_window(image, 80, 120, 180, 200)

		# === PICTURE FRAME (on right side) ===
		_draw_picture_frame(image, 550, 150, 120, 100)

		# === BASEBOARD (trim between wall and floor) ===
		for x in range(800):
			for y in range(480, 500):
				image.set_pixel(x, y, Color(0.5, 0.35, 0.2))  # Dark wood trim

		# === FLOOR (wood planks) ===
		for x in range(800):
			for y in range(500, 600):
				# Wood plank pattern
				var plank_index = y / 15
				var plank_offset = (plank_index * 100) % 200
				var is_gap = ((x + plank_offset) % 80) < 2 or (y % 15) == 0

				if is_gap:
					image.set_pixel(x, y, Color(0.4, 0.28, 0.15))  # Dark gap
				else:
					# Vary wood color slightly per plank
					var color_var = (plank_index % 3) * 0.03
					image.set_pixel(x, y, Color(0.65 + color_var, 0.45 + color_var, 0.25 + color_var))

		# === COZY RUG (center of room) ===
		_draw_rug(image, 300, 520, 200, 60)

		# === CAT BED (bottom right) ===
		_draw_cat_bed(image, 650, 530, 80, 40)

		texture.set_image(image)
		room_background.texture = texture

func _draw_window(image: Image, x: int, y: int, width: int, height: int):
	# Window frame (dark wood)
	var frame_color = Color(0.4, 0.3, 0.2)
	var sky_color = Color(0.6, 0.8, 0.95)  # Light blue sky
	var cloud_color = Color(0.95, 0.95, 1.0)

	# Draw frame border
	for px in range(x, x + width):
		for py in range(y, y + height):
			var in_frame = (px < x + 8 or px >= x + width - 8 or
						   py < y + 8 or py >= y + height - 8)
			var is_center_bar = (px >= x + width/2 - 4 and px < x + width/2 + 4)
			var is_horizontal_bar = (py >= y + height/2 - 4 and py < y + height/2 + 4)

			if in_frame or is_center_bar or is_horizontal_bar:
				image.set_pixel(px, py, frame_color)
			else:
				# Sky with simple clouds
				var cloud_noise = sin(px * 0.1) * cos(py * 0.15) * 0.5 + 0.5
				if cloud_noise > 0.6:
					image.set_pixel(px, py, cloud_color)
				else:
					image.set_pixel(px, py, sky_color)

func _draw_picture_frame(image: Image, x: int, y: int, width: int, height: int):
	var frame_color = Color(0.5, 0.35, 0.2)  # Wood frame
	var picture_color = Color(0.7, 0.85, 0.7)  # Light green (landscape)
	var accent_color = Color(0.4, 0.6, 0.4)  # Dark green (hills)

	for px in range(x, x + width):
		for py in range(y, y + height):
			var in_frame = (px < x + 6 or px >= x + width - 6 or
						   py < y + 6 or py >= y + height - 6)

			if in_frame:
				image.set_pixel(px, py, frame_color)
			else:
				# Simple landscape picture
				var hill_height = y + height/2 + int(sin((px - x) * 0.08) * 15)
				if py > hill_height:
					image.set_pixel(px, py, accent_color)
				else:
					image.set_pixel(px, py, picture_color)

func _draw_rug(image: Image, x: int, y: int, width: int, height: int):
	var rug_color1 = Color(0.7, 0.5, 0.4)  # Warm brown-red
	var rug_color2 = Color(0.8, 0.6, 0.5)  # Lighter accent
	var rug_border = Color(0.5, 0.35, 0.3)  # Dark border

	for px in range(x, x + width):
		for py in range(y, y + height):
			if py >= 600:
				continue  # Stay within image bounds

			var in_border = (px < x + 5 or px >= x + width - 5 or
						   py < y + 3 or py >= y + height - 3)

			if in_border:
				image.set_pixel(px, py, rug_border)
			else:
				# Pattern on rug
				var pattern = ((px - x) / 10 + (py - y) / 8) % 2
				if pattern == 0:
					image.set_pixel(px, py, rug_color1)
				else:
					image.set_pixel(px, py, rug_color2)

func _draw_cat_bed(image: Image, x: int, y: int, width: int, height: int):
	var bed_outer = Color(0.6, 0.5, 0.45)  # Taupe outer
	var bed_inner = Color(0.85, 0.8, 0.75)  # Cream inner cushion

	for px in range(x, x + width):
		for py in range(y, y + height):
			if py >= 600:
				continue

			# Elliptical bed shape
			var center_x = x + width / 2.0
			var center_y = y + height / 2.0
			var norm_x = (px - center_x) / (width / 2.0)
			var norm_y = (py - center_y) / (height / 2.0)
			var dist = norm_x * norm_x + norm_y * norm_y

			if dist < 1.0:
				if dist < 0.5:
					image.set_pixel(px, py, bed_inner)
				else:
					image.set_pixel(px, py, bed_outer)

func connect_signals():
	GameManager.cat_spawned.connect(_on_cat_spawned)
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.spawn_timer_updated.connect(_on_spawn_timer_updated)
	GameManager.fusion_completed.connect(_on_fusion_completed)

	# Settings UI
	settings_button.pressed.connect(_on_settings_button_pressed)
	close_button.pressed.connect(_on_close_settings_pressed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	# Initialize sliders with current AudioManager values
	music_slider.value = AudioManager.music_volume * 100
	sfx_slider.value = AudioManager.sfx_volume * 100

func start_first_spawn():
	# Start the first spawn timer
	GameManager.spawn_timer = 3.0  # First cat spawns quickly

func _on_cat_spawned(cat: Node2D):
	if cat_container and cat:
		cat_container.add_child(cat)

		# Set random position within room bounds
		var spawn_position = Vector2(
			randf_range(room_bounds.position.x, room_bounds.position.x + room_bounds.size.x),
			randf_range(room_bounds.position.y, room_bounds.position.y + room_bounds.size.y)
		)
		cat.global_position = spawn_position

		# Set room bounds for cat movement
		if cat.has_method("set_room_bounds"):
			cat.set_room_bounds(room_bounds)

func _on_currency_changed(new_amount: int):
	if currency_label:
		currency_label.text = "Tunca Cans: %d" % new_amount

func _on_spawn_timer_updated(current_time: float, max_time: float):
	if spawn_progress:
		var progress = 1.0 - (current_time / max_time) if max_time > 0 else 0.0
		spawn_progress.value = progress * 100

	if spawn_timer_label:
		spawn_timer_label.text = "Next Cat: %.1fs" % max(0, current_time)

func _on_fusion_completed(result_cat: Node2D, level: int):
	if info_label:
		info_label.text = "Fused to Level %d!" % level
		# Hide the message after 2 seconds
		create_tween().tween_callback(clear_info_message).set_delay(2.0)

	# Add the fused cat to the scene and play effects
	if result_cat:
		# Add to scene tree
		if cat_container:
			cat_container.add_child(result_cat)

		# Set room bounds for movement
		if result_cat.has_method("set_room_bounds"):
			result_cat.set_room_bounds(room_bounds)

		# Spawn fusion particles and play effect
		spawn_fusion_effect(result_cat.global_position, level)
		if result_cat.has_method("play_spawn_effect"):
			result_cat.play_spawn_effect()

func clear_info_message():
	if info_label:
		info_label.text = ""

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Save game before closing
		SaveManager.save_game()
		get_tree().quit()

func _on_save_timer_timeout():
	# Auto-save every 30 seconds
	SaveManager.save_game()

func spawn_fusion_effect(pos: Vector2, level: int):
	# Create particle effect for fusion
	var particles = CPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = 20 + level * 2  # More particles for higher levels
	particles.lifetime = 0.8

	# Particle movement
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 150.0
	particles.gravity = Vector2(0, 200)

	# Particle appearance
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0

	# Color based on tier
	var tier = GameManager.get_tier_for_level(level)
	var color = _get_fusion_particle_color(tier)
	particles.color = color

	add_child(particles)

	# Auto-cleanup after particles finish
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): particles.queue_free())

func _get_fusion_particle_color(tier: String) -> Color:
	match tier:
		"kitten":
			return Color.WHITE
		"house":
			return Color.LIME_GREEN
		"fancy":
			return Color.CORNFLOWER_BLUE
		"mystical":
			return Color.MEDIUM_PURPLE
		"legendary":
			return Color.GOLD
		"cosmic":
			return Color.HOT_PINK
		_:
			return Color.WHITE

# --- Settings UI ---

func _on_settings_button_pressed():
	settings_panel.visible = true
	AudioManager.play_ui_click()

func _on_close_settings_pressed():
	settings_panel.visible = false
	AudioManager.play_ui_click()

func _on_music_slider_changed(value: float):
	AudioManager.music_volume = value / 100.0

func _on_sfx_slider_changed(value: float):
	AudioManager.sfx_volume = value / 100.0