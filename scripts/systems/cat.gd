class_name Cat extends CharacterBody2D

@export var cat_data: CatData
@export var level: int = 1

@onready var sprite: Sprite2D = $Visuals/Sprite
@onready var behavior_controller: CatBehaviorController = $BehaviorController
@onready var currency_generator: CurrencyGenerator = $CurrencyGenerator
@onready var interaction_area: Area2D = $InteractionArea
@onready var selection_indicator: ColorRect = $Visuals/SelectionIndicator
@onready var level_label: Label = $Visuals/LevelLabel
@onready var collision_shape: CollisionShape2D = $Collision

var selected_for_fusion: bool = false
var is_walking: bool = false
var walk_target: Vector2
var walk_speed: float = 50.0
var room_bounds: Rect2 = Rect2(50, 100, 700, 400)  # Default room bounds

# Look at player variables
var look_target: Vector2 = Vector2.ZERO
var is_looking_at_player: bool = false
var look_timer: float = 0.0
const LOOK_DURATION: float = 2.0  # How long to look at touch position
const LOOK_CHANCE: float = 0.7  # 70% chance to look when player touches

# Nap/sleep variables
var is_napping: bool = false
var zzz_particles: CPUParticles2D = null

# Drag and drop variables
var is_being_dragged: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var is_struggling: bool = false
var struggle_tween: Tween = null

# Ball playing variables
var is_playing_with_ball: bool = false
var target_ball: Node2D = null
var play_state: String = "approaching"  # "approaching", "pushing", "pausing"
var play_pause_timer: float = 0.0
var _push_direction: Vector2 = Vector2.RIGHT
var _push_direction_timer: float = 0.0
const PLAY_PUSH_SPEED: float = 40.0  # Gentle push speed
const PLAY_APPROACH_DISTANCE: float = 45.0  # Must be > collision radii combined (~32px)
const PLAY_TOUCH_DISTANCE: float = 45.0  # Close enough to push

func _ready():
	# Defer setup to ensure all nodes are ready
	call_deferred("_setup_connections")

func _setup_connections():
	setup_input()
	if behavior_controller:
		behavior_controller.behavior_changed.connect(_on_behavior_changed)
	if currency_generator:
		currency_generator.currency_generated.connect(_on_currency_generated)
	GameManager.player_touched.connect(_on_player_touched)

func _process(delta):
	if is_walking and not is_being_dragged:
		process_walking(delta)

	# Handle ball playing
	if is_playing_with_ball and not is_being_dragged:
		process_ball_play(delta)

	# Handle look at player timer
	if is_looking_at_player:
		look_timer -= delta
		if look_timer <= 0:
			is_looking_at_player = false
			_reset_look_rotation()

	# Handle dragging with boundary constraints
	if is_being_dragged:
		var mouse_pos = get_global_mouse_position()
		var target_pos = mouse_pos - drag_offset

		# Check if trying to go outside bounds
		var was_clamped = false
		var clamped_pos = target_pos

		# Clamp to room boundaries
		if target_pos.x < room_bounds.position.x:
			clamped_pos.x = room_bounds.position.x
			was_clamped = true
		elif target_pos.x > room_bounds.position.x + room_bounds.size.x:
			clamped_pos.x = room_bounds.position.x + room_bounds.size.x
			was_clamped = true

		if target_pos.y < room_bounds.position.y:
			clamped_pos.y = room_bounds.position.y
			was_clamped = true
		elif target_pos.y > room_bounds.position.y + room_bounds.size.y:
			clamped_pos.y = room_bounds.position.y + room_bounds.size.y
			was_clamped = true

		global_position = clamped_pos

		# Trigger struggle animation when hitting wall
		if was_clamped and not is_struggling:
			_start_struggle_animation()
		elif not was_clamped and is_struggling:
			_stop_struggle_animation()

func _input(event: InputEvent):
	# Handle mouse/touch input for dragging
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_being_dragged:
			# Check if click is on this cat
			var mouse_pos = get_global_mouse_position()
			var distance = global_position.distance_to(mouse_pos)
			print("Cat %d: click distance = %.1f" % [level, distance])
			if distance < 40:  # Within cat's radius
				print("Starting drag on cat level %d" % level)
				start_drag()
				get_viewport().set_input_as_handled()
		elif not event.pressed and is_being_dragged:
			end_drag()

	elif event is InputEventScreenTouch:
		if event.pressed and not is_being_dragged:
			var touch_pos = event.position
			var distance = global_position.distance_to(touch_pos)
			if distance < 40:
				print("Starting drag on cat level %d (touch)" % level)
				start_drag()
				get_viewport().set_input_as_handled()
		elif not event.pressed and is_being_dragged:
			end_drag()

func setup_input():
	# Try to get the interaction area if @onready didn't work
	if not interaction_area:
		interaction_area = get_node_or_null("InteractionArea")

	if interaction_area:
		if not interaction_area.input_event.is_connected(_on_input_event):
			interaction_area.input_event.connect(_on_input_event)
		interaction_area.input_pickable = true
		print("Input connected for cat level %d" % level)
	else:
		print("ERROR: No interaction_area found for cat!")

func setup_cat(data: CatData):
	cat_data = data
	level = data.level

	# If nodes aren't ready yet, defer the setup
	if not currency_generator or not behavior_controller:
		call_deferred("_deferred_setup")
	else:
		_complete_setup()

func _deferred_setup():
	if cat_data:
		_complete_setup()

func _complete_setup():
	# Setup currency generator
	if currency_generator and cat_data:
		currency_generator.setup(cat_data.base_currency_rate, level)

	# Setup behavior controller
	if behavior_controller and cat_data:
		behavior_controller.setup(cat_data.behavior_set)

	# Setup visual
	setup_sprite()

func setup_sprite():
	if not sprite:
		return

	# Create a simple colored rectangle as placeholder
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)

	# Color based on level and archetype
	var color = get_cat_color()
	image.fill(color)
	texture.set_image(image)

	sprite.texture = texture
	update_sprite_size()
	update_level_label()

func update_level_label():
	if level_label:
		level_label.text = str(level)
		# Style the label
		level_label.add_theme_font_size_override("font_size", 14)
		level_label.add_theme_constant_override("outline_size", 2)
		level_label.add_theme_color_override("font_outline_color", Color.BLACK)
		level_label.add_theme_color_override("font_color", Color.WHITE)

func get_cat_color() -> Color:
	if not cat_data:
		return Color.ORANGE

	# Try to get color from progression data color palette
	var color_palette = _get_color_palette()
	if color_palette.has(cat_data.tier) and color_palette[cat_data.tier].has(cat_data.archetype):
		return Color.from_string(color_palette[cat_data.tier][cat_data.archetype], Color.ORANGE)

	# Fallback: use rarity_color if set
	if cat_data.rarity_color != Color.WHITE:
		return cat_data.rarity_color

	# Final fallback based on archetype
	match cat_data.archetype:
		"tabby", "orange":
			return Color.ORANGE
		"gray", "shorthair":
			return Color.GRAY
		"black", "shadow", "void":
			return Color.DIM_GRAY
		"white", "persian", "spirit":
			return Color.WHITE
		"calico":
			return Color.SANDY_BROWN
		"phoenix":
			return Color.ORANGE_RED
		"dragon":
			return Color.FOREST_GREEN
		"thunder":
			return Color.GOLD
		"frost":
			return Color.DEEP_SKY_BLUE
		"nebula":
			return Color.HOT_PINK
		"supernova":
			return Color.TOMATO
		"blackhole":
			return Color(0.1, 0.0, 0.2)
		"quantum":
			return Color.CYAN
		"infinity":
			return Color.WHITE
		_:
			return Color.ORANGE

func _get_color_palette() -> Dictionary:
	if not GameManager.progression_data:
		return {}
	if GameManager.progression_data.has("visual_design"):
		var visual_design = GameManager.progression_data.visual_design
		if visual_design is Dictionary and visual_design.has("color_palette"):
			return visual_design.color_palette
	return {}

func update_sprite_size():
	if not sprite or not cat_data:
		return

	# Get scale from progression data tier info
	var scale_factor = _get_tier_size_multiplier(cat_data.tier)
	sprite.scale = Vector2(scale_factor, scale_factor)

	# Add visual flair for higher tiers
	_apply_tier_effects()

func _get_tier_size_multiplier(tier: String) -> float:
	if GameManager.game_config and GameManager.game_config.has("tiers"):
		var tiers = GameManager.game_config.tiers
		if tiers is Dictionary and tiers.has(tier):
			var tier_data = tiers[tier]
			if tier_data is Dictionary and tier_data.has("size_multiplier"):
				return float(tier_data.size_multiplier)
	# Fallback values
	match tier:
		"kitten":
			return 1.0
		"house":
			return 1.3
		"fancy":
			return 1.5
		"mystical":
			return 1.8
		"legendary":
			return 2.2
		"cosmic":
			return 2.5
		_:
			return 1.0

func _apply_tier_effects():
	if not cat_data:
		return
	# Add modulation tint based on tier for visual distinction
	match cat_data.tier:
		"mystical":
			# Slight ethereal glow
			modulate = Color(1.1, 1.1, 1.2)
		"legendary":
			# Golden tint
			modulate = Color(1.2, 1.15, 1.0)
		"cosmic":
			# Rainbow/shifting effect (static for now)
			modulate = Color(1.2, 1.1, 1.3)
		_:
			modulate = Color.WHITE

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	# Handle touch drag
	if event is InputEventScreenTouch:
		print("Touch event on cat level %d, pressed=%s" % [level, event.pressed])
		if event.pressed:
			start_drag()
		else:
			end_drag()
	# Handle mouse drag
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Mouse click on cat level %d, pressed=%s" % [level, event.pressed])
			if event.pressed:
				start_drag()
			else:
				end_drag()

func start_drag():
	is_being_dragged = true
	original_position = global_position
	# Calculate offset from current mouse position to cat position
	drag_offset = get_global_mouse_position() - global_position
	# Bring to front while dragging
	z_index = 100
	# Disable collision so cats can overlap for fusion
	if collision_shape:
		collision_shape.disabled = true
	# Visual feedback
	modulate = Color(1.2, 1.2, 1.2)
	if sprite:
		sprite.scale *= 1.1

func end_drag():
	if not is_being_dragged:
		return

	is_being_dragged = false
	z_index = 0

	# Re-enable collision
	if collision_shape:
		collision_shape.disabled = false

	# Stop struggle animation if active
	if is_struggling:
		_stop_struggle_animation()

	# Check if we're on top of another cat for fusion
	var fusion_result = try_fusion_with_nearby_cat()

	if fusion_result == "wrong_level":
		# Only return to original position if tried to fuse with wrong level
		var tween = create_tween()
		tween.tween_property(self, "global_position", original_position, 0.2)
	# Otherwise stay where dropped (fusion_result == "fused" or "no_target")

	# Reset visual
	_apply_tier_effects()
	update_sprite_size()

func try_fusion_with_nearby_cat() -> String:
	# Find cats we're overlapping with
	for cat in GameManager.cats_on_field:
		if cat == self:
			continue

		var distance = global_position.distance_to(cat.global_position)
		if distance < 40:  # Close enough to fuse
			if cat.get_level() == level:
				# Same level - fuse!
				GameManager.attempt_fusion(self, cat)
				return "fused"
			else:
				# Different level - show feedback
				_show_cannot_fuse_feedback()
				return "wrong_level"

	return "no_target"

func _show_cannot_fuse_feedback():
	# Flash red briefly
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	tween.tween_callback(_apply_tier_effects)

func _start_struggle_animation():
	is_struggling = true

	# Kill any existing struggle tween
	if struggle_tween and struggle_tween.is_valid():
		struggle_tween.kill()

	# Create shaking/struggling animation
	struggle_tween = create_tween()
	struggle_tween.set_loops()  # Loop forever until stopped

	# Rapid shaking like cat scratching at glass
	struggle_tween.tween_property(sprite, "rotation_degrees", 8, 0.05)
	struggle_tween.tween_property(sprite, "rotation_degrees", -8, 0.05)
	struggle_tween.tween_property(sprite, "rotation_degrees", 5, 0.05)
	struggle_tween.tween_property(sprite, "rotation_degrees", -5, 0.05)

func _stop_struggle_animation():
	is_struggling = false

	if struggle_tween and struggle_tween.is_valid():
		struggle_tween.kill()

	# Return to normal rotation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "rotation_degrees", 0, 0.1)

func handle_cat_touch():
	# Kept for backwards compatibility but drag is now primary
	pass

func select_for_fusion():
	selected_for_fusion = true
	set_selected(true)
	GameManager.register_fusion_candidate(self)

func cancel_fusion_selection():
	selected_for_fusion = false
	set_selected(false)

func set_selected(selected: bool):
	selected_for_fusion = selected
	if selection_indicator:
		selection_indicator.visible = selected

	# Visual feedback - restore tier effects when deselected
	if selected:
		modulate = Color.YELLOW
	else:
		_apply_tier_effects()

func _on_behavior_changed(new_behavior: String):
	# Stop napping if we were napping and behavior changed
	if is_napping and new_behavior != "nap":
		stop_napping()

	# Stop ball playing if behavior changed
	if is_playing_with_ball and new_behavior != "play":
		stop_playing_with_ball()

	play_animation(new_behavior)

func play_animation(animation_name: String):
	# Visual feedback for different behaviors
	match animation_name:
		"meow":
			modulate = Color(1.2, 1.2, 1.2)
			create_tween().tween_property(self, "modulate", Color.WHITE, 0.5)
			if sprite:
				sprite.rotation_degrees = 0
		"sit":
			if sprite:
				sprite.rotation_degrees = 5
		"walk":
			if sprite:
				sprite.rotation_degrees = 0
		"nap":
			# Darken slightly and lay down
			modulate = Color(0.8, 0.8, 0.9)
			if sprite:
				sprite.rotation_degrees = 90  # Lay on side
		"groom":
			# Slight tilt while grooming
			if sprite:
				var tween = create_tween()
				tween.set_loops(3)
				tween.tween_property(sprite, "rotation_degrees", 10, 0.3)
				tween.tween_property(sprite, "rotation_degrees", -10, 0.3)
				tween.tween_callback(func(): sprite.rotation_degrees = 0)
		"play":
			# Bounce effect while playing
			if sprite:
				var tween = create_tween()
				tween.set_loops(2)
				tween.tween_property(sprite, "position:y", sprite.position.y - 5, 0.2)
				tween.tween_property(sprite, "position:y", sprite.position.y, 0.2)
		_:
			if sprite:
				sprite.rotation_degrees = 0

func start_walking():
	is_walking = true
	# Pick a random target within room bounds
	walk_target = Vector2(
		randf_range(room_bounds.position.x, room_bounds.position.x + room_bounds.size.x),
		randf_range(room_bounds.position.y, room_bounds.position.y + room_bounds.size.y)
	)

func process_walking(_delta):
	var direction = (walk_target - global_position).normalized()
	var distance = global_position.distance_to(walk_target)

	if distance < 5.0:
		is_walking = false
		return

	velocity = direction * walk_speed
	move_and_slide()

	# Face the direction we're walking
	if sprite:
		sprite.flip_h = direction.x < 0

# --- Ball Playing Behavior ---

func start_playing_with_ball(ball: Node2D):
	if not ball:
		print("Cat %d: start_playing_with_ball called but ball is null!" % level)
		return

	# Don't reset if already playing with this ball
	if is_playing_with_ball and target_ball == ball:
		print("Cat %d: Already playing with ball, continuing..." % level)
		return

	print("Cat %d: START PLAYING WITH BALL!" % level)
	is_playing_with_ball = true
	target_ball = ball
	play_state = "approaching"
	_push_direction_timer = 0.0

	# Visual indicator: slightly brighter/excited look
	modulate = Color(1.1, 1.15, 1.0)  # Warm excited tint

	# Face the ball
	if sprite:
		sprite.flip_h = ball.global_position.x < global_position.x

func stop_playing_with_ball():
	# Stop pushing the ball
	if target_ball and target_ball.has_method("stop_push"):
		target_ball.stop_push()

	is_playing_with_ball = false
	target_ball = null
	play_state = "approaching"
	_push_direction_timer = 0.0
	velocity = Vector2.ZERO

	# Stop paw animation and reset rotation
	_stop_paw_animation()

	# Reset visual modulation
	_apply_tier_effects()

var _debug_timer: float = 0.0

func process_ball_play(delta):
	if not target_ball or not is_instance_valid(target_ball):
		stop_playing_with_ball()
		return

	# Update pause timer
	if play_pause_timer > 0:
		play_pause_timer -= delta

	var ball_pos = target_ball.global_position
	var distance_to_ball = global_position.distance_to(ball_pos)

	# Debug print every second
	_debug_timer += delta
	if _debug_timer > 1.0:
		_debug_timer = 0.0
		print("Cat %d: play_state=%s dist=%.1f (approach=%.1f touch=%.1f)" % [level, play_state, distance_to_ball, PLAY_APPROACH_DISTANCE, PLAY_TOUCH_DISTANCE])

	match play_state:
		"approaching":
			# Walk toward the ball
			var direction = (ball_pos - global_position).normalized()
			velocity = direction * walk_speed
			move_and_slide()

			# Face the ball
			if sprite:
				sprite.flip_h = direction.x < 0

			# Close enough to start pushing?
			if distance_to_ball < PLAY_APPROACH_DISTANCE:
				play_state = "pushing"
				_start_paw_animation()

		"pushing":
			# If ball got too far, go back to approaching
			if distance_to_ball > PLAY_APPROACH_DISTANCE * 2.0:
				play_state = "approaching"
				_stop_paw_animation()
				if target_ball.has_method("stop_push"):
					target_ball.stop_push()
				return

			# Walk slowly while pushing the ball
			var push_direction = _get_random_push_direction(delta)

			# Move cat in push direction
			velocity = push_direction * PLAY_PUSH_SPEED
			move_and_slide()

			# Face movement direction
			if sprite:
				sprite.flip_h = push_direction.x < 0

			# Gently push the ball - push force is higher than cat's speed
			if distance_to_ball < PLAY_TOUCH_DISTANCE:
				if target_ball.has_method("gentle_push"):
					target_ball.gentle_push(push_direction, PLAY_PUSH_SPEED * 1.5)
				else:
					print("Cat %d: ball has no gentle_push method!" % level)

			# Occasionally pause to look at ball
			if randf() < 0.008:  # Small chance each frame
				play_state = "pausing"
				play_pause_timer = randf_range(0.8, 2.0)
				velocity = Vector2.ZERO
				_stop_paw_animation()
				if target_ball.has_method("stop_push"):
					target_ball.stop_push()

		"pausing":
			velocity = Vector2.ZERO

			# Look at the ball
			if sprite:
				sprite.flip_h = ball_pos.x < global_position.x

			# Resume pushing after pause
			if play_pause_timer <= 0:
				if distance_to_ball > PLAY_APPROACH_DISTANCE:
					play_state = "approaching"
				else:
					play_state = "pushing"
					_start_paw_animation()

func _get_random_push_direction(delta: float) -> Vector2:
	_push_direction_timer -= delta

	# Change direction occasionally
	if _push_direction_timer <= 0:
		_push_direction_timer = randf_range(1.5, 3.0)
		# Pick a random direction, slightly favoring forward
		var angle = randf_range(-PI * 0.7, PI * 0.7)
		_push_direction = Vector2.RIGHT.rotated(angle)

		# Make sure we stay in bounds
		var future_pos = global_position + _push_direction * 100
		if not room_bounds.has_point(future_pos):
			_push_direction = (Vector2(room_bounds.get_center()) - global_position).normalized()

	return _push_direction

var paw_tween: Tween = null

func _start_paw_animation():
	if not sprite:
		return

	# Kill existing paw animation if any
	if paw_tween and paw_tween.is_valid():
		paw_tween.kill()

	# Gentle walking/pawing animation - loops forever until stopped
	paw_tween = create_tween()
	paw_tween.set_loops()  # Infinite looping
	paw_tween.tween_property(sprite, "rotation_degrees", 8, 0.12)
	paw_tween.tween_property(sprite, "rotation_degrees", -8, 0.12)

func _stop_paw_animation():
	if paw_tween and paw_tween.is_valid():
		paw_tween.kill()
	if sprite:
		sprite.rotation_degrees = 0

func _on_currency_generated(amount: int, _gen_position: Vector2):
	show_currency_popup(amount)

func show_currency_popup(amount: int):
	# Create stylized popup text
	var popup = Label.new()
	popup.text = "+%d 🐟" % amount  # Add fish emoji as currency icon
	popup.position = global_position + Vector2(randf_range(-20, 20), -30)

	# Style based on amount
	if amount >= 50:
		popup.modulate = Color.GOLD
		popup.add_theme_font_size_override("font_size", 20)
	elif amount >= 20:
		popup.modulate = Color.LIME_GREEN
		popup.add_theme_font_size_override("font_size", 16)
	else:
		popup.modulate = Color.GREEN
		popup.add_theme_font_size_override("font_size", 14)

	# Add outline for visibility
	popup.add_theme_constant_override("outline_size", 2)
	popup.add_theme_color_override("font_outline_color", Color.BLACK)

	get_tree().current_scene.add_child(popup)

	# Start with scale 0 and pop in
	popup.scale = Vector2.ZERO
	popup.pivot_offset = popup.size / 2

	var tween = create_tween()
	# Pop in effect
	tween.tween_property(popup, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(popup, "scale", Vector2(1.0, 1.0), 0.1)
	# Float up and fade out
	tween.parallel().tween_property(popup, "position", popup.position + Vector2(0, -60), 1.2).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.8).set_delay(0.4)
	tween.tween_callback(popup.queue_free)

func get_level() -> int:
	return level

func get_cat_data() -> CatData:
	return cat_data

func set_room_bounds(bounds: Rect2):
	room_bounds = bounds

# --- Fusion Effect ---

func play_spawn_effect():
	# Called when this cat is created from fusion
	if not sprite:
		return

	# Start small and pop to full size
	var original_scale = sprite.scale
	sprite.scale = Vector2.ZERO

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(sprite, "scale", original_scale, 0.5)

	# Flash bright briefly
	modulate = Color(2.0, 2.0, 2.0)  # Bright flash
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	flash_tween.tween_callback(_apply_tier_effects)

# --- Nap/Sleep Behavior ---

func start_napping():
	is_napping = true
	play_animation("nap")
	_create_zzz_particles()

func stop_napping():
	is_napping = false
	_remove_zzz_particles()

func _create_zzz_particles():
	if zzz_particles:
		return  # Already have particles

	zzz_particles = CPUParticles2D.new()
	zzz_particles.position = Vector2(20, -20)  # Above the cat
	zzz_particles.emitting = true
	zzz_particles.amount = 3
	zzz_particles.lifetime = 2.0
	zzz_particles.one_shot = false

	# Floating up motion
	zzz_particles.direction = Vector2(-0.5, -1)
	zzz_particles.spread = 20.0
	zzz_particles.initial_velocity_min = 15.0
	zzz_particles.initial_velocity_max = 25.0
	zzz_particles.gravity = Vector2(0, -10)  # Float up

	# Appearance
	zzz_particles.scale_amount_min = 2.0
	zzz_particles.scale_amount_max = 4.0
	zzz_particles.color = Color(0.7, 0.7, 1.0, 0.8)  # Light blue

	# Fade out
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.7, 0.7, 1.0, 0.8))
	gradient.set_color(1, Color(0.7, 0.7, 1.0, 0.0))
	zzz_particles.color_ramp = gradient

	add_child(zzz_particles)

func _remove_zzz_particles():
	if zzz_particles:
		zzz_particles.emitting = false
		# Wait a bit then remove
		var tween = create_tween()
		tween.tween_interval(1.0)
		tween.tween_callback(func():
			if zzz_particles:
				zzz_particles.queue_free()
				zzz_particles = null
		)

# --- Look at Player Behavior ---

func _on_player_touched(touch_pos: Vector2):
	# Random chance to look at player
	if randf() > LOOK_CHANCE:
		return

	# Don't interrupt walking
	if is_walking:
		return

	look_target = touch_pos
	is_looking_at_player = true
	look_timer = LOOK_DURATION

	_apply_look_rotation()

func _apply_look_rotation():
	if not sprite:
		return

	var direction = look_target - global_position

	# Flip sprite to face the touch position
	sprite.flip_h = direction.x < 0

	# Subtle head tilt toward the player (rotation)
	var angle = direction.angle()
	# Clamp rotation to a subtle range (-15 to 15 degrees)
	var tilt = clamp(sin(angle) * 15.0, -15.0, 15.0)

	# Smoothly rotate to look at player
	var tween = create_tween()
	tween.tween_property(sprite, "rotation_degrees", tilt, 0.2)

func _reset_look_rotation():
	if not sprite:
		return

	# Smoothly return to normal rotation
	var tween = create_tween()
	tween.tween_property(sprite, "rotation_degrees", 0.0, 0.3)