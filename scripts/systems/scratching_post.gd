class_name ScratchingPost extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite

var post_width: float = 20.0
var post_height: float = 50.0
var is_being_scratched: bool = false
var scratch_tween: Tween = null

func _ready():
	setup_visual()
	setup_collision()

func setup_visual():
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)

	# Create a scratching post texture (sisal-wrapped post with base)
	var texture = ImageTexture.new()
	var width = int(post_width)
	var height = int(post_height)
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)

	# Colors for the scratching post
	var sisal_light = Color(0.85, 0.75, 0.55)  # Light tan sisal
	var sisal_dark = Color(0.65, 0.55, 0.40)   # Darker tan for texture
	var wood_base = Color(0.55, 0.40, 0.30)    # Dark wood for base and top

	for x in range(width):
		for y in range(height):
			# Base (bottom platform)
			if y > height - 8:
				# Wooden base with slight gradient
				var shade = 1.0 - float(y - (height - 8)) / 8.0 * 0.2
				image.set_pixel(x, y, Color(wood_base.r * shade, wood_base.g * shade, wood_base.b * shade))
			# Top cap
			elif y < 6:
				var shade = 0.9 + float(y) / 6.0 * 0.1
				image.set_pixel(x, y, Color(wood_base.r * shade, wood_base.g * shade, wood_base.b * shade))
			# Post part - narrower than base
			elif x >= 4 and x < width - 4:
				# Sisal wrapping pattern (horizontal lines)
				var wrap_pattern = (y % 4) < 2
				var edge_shade = 1.0 - abs(x - width / 2.0) / (width / 2.0) * 0.15

				if wrap_pattern:
					# Add some random variation for texture
					var noise = sin(float(x) * 1.5 + float(y) * 0.3) * 0.1
					var color = sisal_light
					color.r = clampf(color.r + noise, 0.0, 1.0) * edge_shade
					color.g = clampf(color.g + noise * 0.8, 0.0, 1.0) * edge_shade
					color.b = clampf(color.b + noise * 0.6, 0.0, 1.0) * edge_shade
					image.set_pixel(x, y, color)
				else:
					var noise = sin(float(x) * 1.2 + float(y) * 0.5) * 0.08
					var color = sisal_dark
					color.r = clampf(color.r + noise, 0.0, 1.0) * edge_shade
					color.g = clampf(color.g + noise * 0.8, 0.0, 1.0) * edge_shade
					color.b = clampf(color.b + noise * 0.6, 0.0, 1.0) * edge_shade
					image.set_pixel(x, y, color)
			else:
				# Transparent edges of base area
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	texture.set_image(image)
	sprite.texture = texture
	# Offset so the post sits on the ground properly
	sprite.offset = Vector2(0, -post_height / 2)

func setup_collision():
	# Add a collision shape for the post
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(post_width - 8, post_height)
	collision.shape = shape
	collision.position = Vector2(0, -post_height / 2)
	add_child(collision)

func start_scratch():
	if is_being_scratched:
		return

	is_being_scratched = true
	_start_scratch_animation()

func stop_scratch():
	is_being_scratched = false
	_stop_scratch_animation()

func _start_scratch_animation():
	if scratch_tween and scratch_tween.is_valid():
		scratch_tween.kill()

	# Subtle shaking animation
	scratch_tween = create_tween()
	scratch_tween.set_loops()
	scratch_tween.tween_property(sprite, "position:x", 1.5, 0.05)
	scratch_tween.tween_property(sprite, "position:x", -1.5, 0.05)
	scratch_tween.tween_property(sprite, "position:x", 1.0, 0.05)
	scratch_tween.tween_property(sprite, "position:x", -1.0, 0.05)

func _stop_scratch_animation():
	if scratch_tween and scratch_tween.is_valid():
		scratch_tween.kill()

	if sprite:
		sprite.position.x = 0
