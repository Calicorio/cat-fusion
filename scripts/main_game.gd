extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var environment: Node2D = $Environment
@onready var cat_container: Node2D = $CatManager/CatContainer
@onready var room_background: Sprite2D = $Environment/RoomBackground
@onready var game_hud: Control = $UI/GameHUD

var room_bounds: Rect2 = Rect2(50, 100, 700, 400)

func _ready():
	setup_camera()
	setup_room()
	connect_signals()
	start_first_spawn()

func setup_camera():
	if camera:
		camera.position = Vector2(400, 300)
		camera.zoom = Vector2(1, 1)

func setup_room():
	create_room_background()

func create_room_background():
	if room_background:
		# Create a simple room background
		var texture = ImageTexture.new()
		var image = Image.create(800, 600, false, Image.FORMAT_RGB8)

		# Fill with a cozy room color
		image.fill(Color(0.9, 0.8, 0.7))  # Light beige

		# Add some simple room elements
		# Floor
		for x in range(800):
			for y in range(500, 600):
				image.set_pixel(x, y, Color(0.6, 0.4, 0.2))  # Brown floor

		# Walls
		for x in range(800):
			for y in range(100):
				image.set_pixel(x, y, Color(0.8, 0.7, 0.6))  # Light wall

		texture.set_image(image)
		room_background.texture = texture

func connect_signals():
	GameManager.cat_spawned.connect(_on_cat_spawned)

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

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Save game before closing
		SaveManager.save_game()
		get_tree().quit()

func _on_save_timer_timeout():
	# Auto-save every 30 seconds
	SaveManager.save_game()