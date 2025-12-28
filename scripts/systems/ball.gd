class_name Ball extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite
@onready var collision: CollisionShape2D = $Collision

var ball_color: Color = Color(0.85, 0.55, 0.65)  # Pink yarn ball
var ball_radius: float = 10.0
var friction: float = 0.92  # More friction - slows down faster
var min_velocity: float = 3.0
var bounce_factor: float = 0.5  # Less bouncy

var room_bounds: Rect2 = Rect2(50, 100, 700, 400)
var is_being_pushed: bool = false  # Visual indicator when cat is pushing

func _ready():
	setup_ball_visual()
	setup_collision()

func setup_ball_visual():
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)

	# Create a yarn ball texture
	var texture = ImageTexture.new()
	var size = int(ball_radius * 2)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Yarn ball colors
	var yarn_base = Color(0.9, 0.45, 0.55)  # Pink
	var yarn_dark = Color(0.7, 0.35, 0.45)  # Darker pink for strands
	var yarn_light = Color(1.0, 0.7, 0.75)  # Light pink highlight

	var center = Vector2(ball_radius, ball_radius)
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)

			if dist <= ball_radius:
				# Base shading
				var shade = 1.0 - (dist / ball_radius) * 0.25

				# Create yarn strand pattern using sin waves
				var strand1 = sin((x + y) * 0.8) * 0.5 + 0.5
				var strand2 = sin((x - y) * 0.6 + 1.5) * 0.5 + 0.5
				var strand3 = sin(x * 0.5 + y * 0.3) * 0.5 + 0.5

				# Combine strands
				var strand_val = (strand1 + strand2 + strand3) / 3.0

				# Mix colors based on strand pattern
				var final_color: Color
				if strand_val > 0.6:
					final_color = yarn_light.lerp(yarn_base, (strand_val - 0.6) / 0.4)
				elif strand_val < 0.4:
					final_color = yarn_dark.lerp(yarn_base, strand_val / 0.4)
				else:
					final_color = yarn_base

				final_color = final_color * shade
				final_color.a = 1.0
				image.set_pixel(x, y, final_color)
			elif dist <= ball_radius + 1:
				# Soft edge
				var alpha = 1.0 - (dist - ball_radius)
				image.set_pixel(x, y, Color(yarn_base.r, yarn_base.g, yarn_base.b, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	texture.set_image(image)
	sprite.texture = texture

func setup_collision():
	if not collision:
		collision = CollisionShape2D.new()
		add_child(collision)

	var shape = CircleShape2D.new()
	shape.radius = ball_radius
	collision.shape = shape

func _physics_process(delta):
	# Apply friction (less if being pushed)
	if not is_being_pushed:
		velocity *= friction

	# Stop if moving very slowly
	if velocity.length() < min_velocity:
		velocity = Vector2.ZERO
		is_being_pushed = false
		return

	# Rotate sprite based on movement (rolling effect)
	if sprite and velocity.length() > 0:
		var roll_speed = velocity.length() * 0.1
		sprite.rotation += roll_speed * delta * sign(velocity.x)

	# Move and handle room boundary collision
	var collision_info = move_and_collide(velocity * delta)

	if collision_info:
		velocity = velocity.bounce(collision_info.get_normal()) * bounce_factor

	# Bounce off room boundaries
	check_room_bounds()

func check_room_bounds():
	var bounced = false

	if global_position.x - ball_radius < room_bounds.position.x:
		global_position.x = room_bounds.position.x + ball_radius
		velocity.x = abs(velocity.x) * bounce_factor
		bounced = true
	elif global_position.x + ball_radius > room_bounds.position.x + room_bounds.size.x:
		global_position.x = room_bounds.position.x + room_bounds.size.x - ball_radius
		velocity.x = -abs(velocity.x) * bounce_factor
		bounced = true

	if global_position.y - ball_radius < room_bounds.position.y:
		global_position.y = room_bounds.position.y + ball_radius
		velocity.y = abs(velocity.y) * bounce_factor
		bounced = true
	elif global_position.y + ball_radius > room_bounds.position.y + room_bounds.size.y:
		global_position.y = room_bounds.position.y + room_bounds.size.y - ball_radius
		velocity.y = -abs(velocity.y) * bounce_factor
		bounced = true

	return bounced

func push(direction: Vector2, force: float):
	velocity += direction.normalized() * force

	# Visual feedback - squish effect
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.05)
		tween.tween_property(sprite, "scale", Vector2(0.9, 1.1), 0.05)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

func gentle_push(direction: Vector2, speed: float):
	# Gentle continuous push - used when cat is walking with ball
	velocity = direction.normalized() * speed
	is_being_pushed = true

func stop_push():
	is_being_pushed = false

func set_room_bounds(bounds: Rect2):
	room_bounds = bounds

func get_radius() -> float:
	return ball_radius

func is_moving() -> bool:
	return velocity.length() > min_velocity
