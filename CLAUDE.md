# Godot 4.5.1 Game Development Best Practices & Learnings

> **IMPORTANT: This is a living document that MUST be updated continuously.**
> After implementing any feature, fixing any bug, or encountering any new pattern:
> 1. Document what you learned
> 2. Add common errors and their solutions
> 3. Update best practices based on real experience
> 4. Remove outdated information that no longer applies
>
> This ensures institutional knowledge is preserved and future development is smoother.

This document contains best practices, common pitfalls, and solutions learned during the development of CatFusion with Godot 4.5.1.

## Table of Contents
1. [Game Vision](#game-vision)
2. [Development Roadmap](#development-roadmap)
3. [Type System & Arrays](#type-system--arrays)
4. [Scene Architecture](#scene-architecture)
5. [Resource System](#resource-system)
6. [Node Initialization Order](#node-initialization-order)
7. [Mobile Development](#mobile-development)
8. [Project Configuration](#project-configuration)
9. [Performance Considerations](#performance-considerations)
10. [Common Errors & Solutions](#common-errors--solutions)

---

## Game Vision

**CatFusion** is an idle/evolution/fusion mobile game with pixel art aesthetics for Android.

### Core Loop
1. Player starts with one basic pixel-art cat
2. Cats generate "Tunca Cans" (currency) over time
3. New cats spawn automatically every X seconds
4. Two same-level cats can be fused into one higher-level cat
5. Long progression with many cat levels and visual variations

### Visual Style
- Pixel art, minimalistic but charming
- Consistent art style across all levels
- Each cat level has distinct sprite with visual progression (size, details, accessories, expressions)

### Cat Behaviors
Cats exist in a cozy room and can:
- Look at the player
- Meow occasionally
- Walk around the room
- Sit, lick themselves, nap
- Play with props (ball, toys)

### Technical Requirements
- Engine: Godot 4.5.1
- Platform: Android (mobile-first)
- Performance-friendly and scalable
- Idle progression when game is closed

---

## Development Roadmap

### Phase 1: Core Systems ✅ COMPLETE
- [x] Project setup and structure
- [x] Currency system (Tunca Cans)
- [x] Currency generation per cat
- [x] Cat spawning system with timer
- [x] Fusion logic (same level → level+1)
- [x] Save/Load system with Resources
- [x] Offline earnings calculation
- [x] Basic HUD (currency, spawn timer, info)
- [x] Touch input for cat selection
- [x] Basic cat behaviors (idle, walk, sit, meow, play)
- [x] Behavior state machine

### Phase 2: Progression System ✅ COMPLETE
- [x] Design full cat evolution tree (30 levels across 6 tiers)
- [x] Define progression curve (spawn times, currency rates per level)
- [x] Balance fusion rewards (tier-based bonus multipliers)
- [x] Implement tier system with meaningful differences:
  - [x] Kitten tier (levels 1-5) - Basic kittens, small size
  - [x] House cat tier (levels 6-10) - Adult cats, 1.3x size
  - [x] Fancy tier (levels 11-15) - Purebreds, 1.5x size
  - [x] Mystical tier (levels 16-20) - Magical cats with glow, 1.8x size
  - [x] Legendary tier (levels 21-25) - Mythical cats with golden tint, 2.2x size
  - [x] Cosmic tier (levels 26-30) - Universe-level cats, 2.5x size
- [x] Max cats on screen balancing (10 cats)
- [x] Offline earnings balancing (50% rate, 24h cap)
- [x] Created progression_design.json with full cat definitions
- [x] Tier-based color palettes and visual effects

### Phase 3: Art & Animation 🔄 PARTIALLY COMPLETE
- [ ] Define pixel art specifications:
  - [x] Base sprite size (32x32 base, scaled by tier)
  - [x] Color palette per tier (defined in progression_design.json)
  - [ ] Animation frame counts
- [ ] Create/source cat sprites for each level
- [ ] Implement AnimatedSprite2D for cats
- [ ] Create sprite sheets for behaviors:
  - [ ] Idle animation (2-4 frames)
  - [ ] Walk animation (4-6 frames)
  - [ ] Sit animation (2-3 frames)
  - [ ] Meow animation (2-3 frames)
  - [ ] Sleep/nap animation (2-3 frames)
  - [ ] Licking animation (3-4 frames)
  - [ ] Play animation (4-6 frames)
- [x] Visual progression per level (size scaling, tier tints)
- [x] Fusion animation/effect (particles + pop scale effect)
- [x] Currency popup improvements (styled, sized by amount, pop animation)

### Phase 4: Environment & Room 🔄 PARTIALLY COMPLETE
- [x] Design cozy room background (procedurally generated)
  - [x] Striped wallpaper pattern
  - [x] Wood plank floor with gaps
  - [x] Baseboard trim between wall and floor
  - [x] Window with sky and clouds view
  - [x] Picture frame with landscape painting
  - [x] Decorative rug in center
  - [x] Cat bed in corner
- [ ] Upgrade to actual pixel art sprites (replace procedural)
- [x] Interactive props:
  - [x] Yarn ball for cats to play with (pink, rolling animation)
  - [ ] Scratching post
  - [ ] Cat bed as nap destination
- [ ] Parallax or depth layers (optional)
- [ ] Day/night cycle (optional)

### Phase 5: Enhanced Behaviors 🔄 PARTIALLY COMPLETE
- [x] "Look at player" behavior (cats face touch position with tilt)
- [x] Nap/sleep behavior with zzz particles
- [x] Licking/grooming animation (oscillating tilt)
- [x] Play animation (bounce effect)
- [x] Drag-and-drop fusion (drag cats on top of each other)
- [x] Visual level indicator on cats (label showing level number)
- [x] Room boundary constraints (cats can't escape the room)
- [x] Struggle animation when hitting boundary (shaking like against glass)
- [x] Play with props behavior:
  - [x] Cat approaches yarn ball
  - [x] Cat gently pushes ball with paws while walking
  - [x] Ball physics (friction, bouncing, room boundaries, rolling rotation)
  - [x] Cat occasionally pauses to look at ball, then resumes pushing
  - [x] Smooth pawing animation while pushing
- [ ] Cat-to-cat interactions (optional):
  - [ ] Cats grooming each other
  - [ ] Cats playing together
- [ ] Behavior weights based on cat personality

### Phase 6: Audio ❌ NOT STARTED
- [ ] Background music (cozy, lofi style)
- [ ] Meow sounds (multiple variations per tier)
- [ ] Purring sounds
- [ ] Fusion sound effect
- [ ] Currency collect sound
- [ ] UI interaction sounds
- [ ] Ambient room sounds (optional)

### Phase 7: UI/UX Polish ❌ NOT STARTED
- [ ] Main menu screen
- [ ] Settings menu (sound, music toggles)
- [ ] Tutorial/onboarding for new players
- [ ] Cat collection/album view
- [ ] Statistics screen (total cats fused, highest level, etc.)
- [ ] Offline earnings popup on return
- [ ] Fusion confirmation UI
- [ ] Better currency display with icons
- [ ] Cat info popup (tap and hold)

### Phase 8: Monetization & Extras ❌ NOT STARTED
- [ ] Ad integration (rewarded ads for bonuses)
- [ ] IAP for currency packs (optional)
- [ ] Daily rewards system
- [ ] Achievements system
- [ ] Special/rare cat variants
- [ ] Seasonal cats (holiday specials)

### Phase 9: Performance & Polish ❌ NOT STARTED
- [ ] Object pooling for cats
- [ ] Object pooling for currency popups
- [ ] Frame rate optimization
- [ ] Memory usage profiling
- [ ] Battery usage optimization
- [ ] Android build and testing
- [ ] Multiple screen size support
- [ ] Localization support (optional)

### Phase 10: Release ❌ NOT STARTED
- [ ] Play Store assets (icons, screenshots, descriptions)
- [ ] Privacy policy
- [ ] Beta testing
- [ ] Bug fixes from testing
- [ ] Launch!

---

### Current Priority Tasks
> Update this section with immediate next steps

1. ~~**Design the full progression system**~~ ✅ DONE
2. ~~**Implement "look at player"**~~ ✅ DONE
3. ~~**Add fusion visual effect**~~ ✅ DONE (particles + pop animation)
4. ~~**Add nap/sleep with zzz particles**~~ ✅ DONE
5. ~~**Improve currency popups**~~ ✅ DONE
6. ~~**Drag-and-drop fusion**~~ ✅ DONE (drag cats to merge same levels)
7. ~~**Visual level indicator**~~ ✅ DONE (level number label on cats)
8. ~~**Room boundary constraints**~~ ✅ DONE (with struggle animation)
9. ~~**Enhanced room background**~~ ✅ DONE (window, floor, decorations)
10. ~~**Interactive ball prop**~~ ✅ DONE (cats approach and bat ball)
11. **Source or create cat sprites** - Replace colored rectangles with pixel art
12. **Add scratching post prop** - Another interactive prop for variety
13. **Implement audio** - Meow sounds, background music
14. **Cat bed as nap destination** - Cats walk to bed when napping

---

## Type System & Arrays

### ❌ Avoid Typed Arrays in @export and Resource Classes
**Problem:** Godot 4.5.1 has issues with typed arrays in certain contexts.

```gdscript
# ❌ DON'T - Can cause runtime errors
@export var behavior_set: Array[String] = ["idle", "walk"]
@export var cats_on_field: Array[Node2D] = []

# ✅ DO - Use untyped arrays instead
@export var behavior_set: Array = ["idle", "walk"]
@export var cats_on_field: Array = []
```

**When to use typed arrays:**
- Local variables: `var my_cats: Array[Cat] = []` ✅
- Function parameters when you control all calls: `func process_cats(cats: Array[Cat])` ✅
- Return types: `func get_cats() -> Array[Cat]` ✅

### ❌ Float/Int Modulo Operations
**Problem:** Modulo operator `%` requires same types.

```gdscript
# ❌ DON'T - Type mismatch error
var time_offline: float = 3661.5
var minutes = int((time_offline % 3600) / 60)  # Error!

# ✅ DO - Cast to same type first
var minutes = int((int(time_offline) % 3600) / 60)
```

## Scene Architecture

### ✅ Use Simple Scene References
**Problem:** Complex UIDs and external scene references can cause import issues.

```gdscript
# ❌ DON'T - Complex nested scene references
[ext_resource type="PackedScene" uid="uid://c0m2p3uo8exlg" path="res://scenes/ui/game_hud.tscn" id="2_h3w4t"]

# ✅ DO - Embed UI directly or use simple paths
[ext_resource type="Script" path="res://main_game.gd" id="1"]
```

### ✅ Prefer Composition Over Inheritance for UI
**Instead of creating separate scene files for simple UI components, embed them directly:**

```gdscript
# Embedded in main scene instead of separate .tscn file
[node name="GameHUD" type="Control" parent="UI"]
[node name="VBox" type="VBoxContainer" parent="UI/GameHUD"]
[node name="CurrencyLabel" type="Label" parent="UI/GameHUD/VBox"]
```

### ✅ Sprite Node Type Selection
**Problem:** Wrong sprite node type for your use case.

```gdscript
# ❌ DON'T - AnimatedSprite2D doesn't have texture property
@onready var sprite: AnimatedSprite2D = $Sprite
sprite.texture = my_texture  # ERROR!

# ✅ DO - Use Sprite2D for static textures
@onready var sprite: Sprite2D = $Sprite
sprite.texture = my_texture  # ✅

# ✅ DO - Use AnimatedSprite2D for frame animations
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
animated_sprite.sprite_frames = my_sprite_frames  # ✅
```

## Resource System

### ✅ Resource Class Best Practices

```gdscript
# ✅ Good Resource class structure
class_name CatData extends Resource

# Use untyped Arrays for @export
@export var behavior_set: Array = ["idle", "walk"]
@export var animation_frames: Array = []

# Provide helper methods for type safety
func get_behaviors() -> Array[String]:
	return behavior_set

func add_behavior(behavior: String):
	if behavior not in behavior_set:
		behavior_set.append(behavior)
```

### ✅ Save System Architecture

```gdscript
# ✅ Robust save system pattern
const SAVE_PATH = "user://game_save.tres"

func save_game():
	var save_data = GameSave.new()
	# Populate save_data...

	var error = ResourceSaver.save(save_data, SAVE_PATH)
	if error != OK:
		print("Error saving game: ", error)
		return false
	return true

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return create_new_game()

	var save_data = ResourceLoader.load(SAVE_PATH) as GameSave
	if not save_data:
		print("Error loading save, creating new game")
		return create_new_game()

	return save_data
```

## Node Initialization Order

### ✅ Handle @onready Variables Safely
**Problem:** @onready variables may be null when external code calls functions early.

```gdscript
# ❌ DON'T - Assumes nodes are ready
func setup_cat(data: CatData):
	currency_generator.setup(data.base_rate, data.level)  # May be null!

# ✅ DO - Handle initialization order properly
func setup_cat(data: CatData):
	cat_data = data
	if not currency_generator:
		call_deferred("_deferred_setup")
	else:
		_complete_setup()

func _deferred_setup():
	if cat_data:
		_complete_setup()

func _complete_setup():
	if currency_generator:
		currency_generator.setup(cat_data.base_rate, cat_data.level)
```

### ✅ AutoLoad Dependency Management

```gdscript
# ✅ Safe autoload initialization
func _ready():
	# Load config first
	load_game_config()
	# Then setup dependent systems
	setup_cat_data_library()
	# Connect to other autoloads last
	SaveManager.save_loaded.connect(_on_save_loaded)
```

## Mobile Development

### ✅ Project Settings for Mobile

```ini
# project.godot - Mobile optimized settings
[display]
window/size/viewport_width=800
window/size/viewport_height=600
window/stretch/mode="viewport"
window/stretch/aspect="keep"
window/handheld/orientation=1

[rendering]
renderer/rendering_method="mobile"
textures/canvas_textures/default_texture_filter=0

[input]
touch="InputEventScreenTouch"
```

### ✅ Touch Input Handling

```gdscript
# ✅ Proper mobile input setup
func _ready():
	if interaction_area:
		interaction_area.input_event.connect(_on_input_event)

# Note: Prefix unused params with underscore to avoid warnings
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventScreenTouch and event.pressed:
		handle_touch()
```

## Performance Considerations

### ✅ Update Distribution

```gdscript
# ✅ Distribute heavy updates across frames
class_name PerformanceManager extends Node

@export var max_updates_per_frame: int = 3
var update_queue: Array = []

func _process(_delta):
	var updates_this_frame = 0
	while update_queue.size() > 0 and updates_this_frame < max_updates_per_frame:
		var item = update_queue.pop_front()
		item.update()
		updates_this_frame += 1
```

### ✅ Object Pooling Ready Architecture

```gdscript
# ✅ Design for object pooling from the start
func remove_cat(cat: Node2D):
	if cat in cats_on_field:
		cats_on_field.erase(cat)

	# Don't destroy immediately - prepare for pooling
	cat.reset_for_pool()  # Custom reset function
	if cat.get_parent():
		cat.get_parent().remove_child(cat)

	# For now, destroy. Later: return to pool
	cat.queue_free()
```

## Project Configuration

### ✅ Autoload Setup

```ini
# project.godot
[autoload]
SaveManager="*res://scripts/autoload/save_manager.gd"
GameManager="*res://scripts/autoload/game_manager.gd"
```

### ✅ Directory Structure

```
scripts/
├── autoload/       # Singleton managers
├── data/          # Resource classes
├── systems/       # Game logic (Cat, CurrencyGenerator, etc.)
├── ui/            # UI controllers
└── utils/         # Helper utilities

scenes/
├── main.tscn      # Main game scene
├── cats/          # Cat-related scenes
└── ui/            # UI scenes (if needed)

data/
├── config/        # JSON configuration files
└── saves/         # Save files (created at runtime)
```

## Common Errors & Solutions

### "Invalid type in function" with Arrays
**Solution:** Remove typed array annotations from @export and function parameters.

### "No main scene has been defined"
**Solution:** Check project.godot has `run/main_scene="res://main.tscn"` and the scene file exists.

### "Nonexistent function 'setup'"
**Solution:** Check @onready variables are initialized before calling methods on them. Use deferred calls if needed.

### "Invalid assignment of property 'texture'"
**Solution:** Use `Sprite2D` for static textures, `AnimatedSprite2D` for frame-based animations.

### Image.create() format issues
**Solution:** Use `Image.FORMAT_RGB8` for simple colored rectangles.

### Scene import failures
**Solution:** Use simple file paths without complex UIDs. Restart Godot editor to reimport.

### "Cannot get class 'VBox'" or similar container errors
**Problem:** Godot 4 renamed many container nodes from Godot 3.
**Solution:** Use the full container names:
- `VBox` → `VBoxContainer`
- `HBox` → `HBoxContainer`
- `MarginContainer`, `GridContainer`, etc. remain the same

### Unused parameter warnings (UNUSED_PARAMETER)
**Problem:** GDScript warns about parameters that aren't used in a function.
**Solution:** Prefix unused parameters with underscore `_`:
```gdscript
# ❌ DON'T - Causes warnings
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	if event is InputEventScreenTouch:
		handle_touch()

# ✅ DO - Prefix unused params with underscore
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventScreenTouch:
		handle_touch()
```

### Shadowed variable warning (SHADOWED_VARIABLE_BASE_CLASS)
**Problem:** Parameter name shadows a property from base class (e.g., `position` in Node2D).
**Solution:** Rename the parameter to avoid collision:
```gdscript
# ❌ DON'T - 'position' shadows Node2D.position
func _on_currency_generated(amount: int, position: Vector2):

# ✅ DO - Use a different name
func _on_currency_generated(amount: int, spawn_pos: Vector2):
```

### Area2D input_event not responding to clicks
**Problem:** Area2D.input_event signal doesn't always fire reliably for mouse/touch input.
**Solution:** Use direct `_input()` function with distance-based hit detection instead:
```gdscript
# ❌ DON'T - May not respond to clicks
func _ready():
    interaction_area.input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
    if event is InputEventMouseButton and event.pressed:
        start_drag()  # May never be called!

# ✅ DO - Direct input with distance check
func _input(event: InputEvent):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            var mouse_pos = get_global_mouse_position()
            var distance = global_position.distance_to(mouse_pos)
            if distance < 40:  # Within clickable radius
                start_drag()
                get_viewport().set_input_as_handled()
```

### Tween animation continues after it should stop
**Problem:** When starting/stopping looping tweens, old ones may still be running.
**Solution:** Kill existing tweens before creating new ones:
```gdscript
var struggle_tween: Tween = null

func _start_struggle_animation():
    # Kill any existing tween first
    if struggle_tween and struggle_tween.is_valid():
        struggle_tween.kill()

    struggle_tween = create_tween()
    struggle_tween.set_loops()  # Loops until killed
    # ... animation properties

func _stop_struggle_animation():
    if struggle_tween and struggle_tween.is_valid():
        struggle_tween.kill()
    # Reset to default state
    sprite.rotation_degrees = 0
```

### CharacterBody2D nodes can't overlap for drag-and-drop
**Problem:** When dragging one CharacterBody2D onto another (e.g., for fusion), they collide and can't overlap.
**Solution:** Disable collision while dragging:
```gdscript
@onready var collision_shape: CollisionShape2D = $Collision

func start_drag():
    is_being_dragged = true
    # Disable collision so objects can overlap
    if collision_shape:
        collision_shape.disabled = true

func end_drag():
    is_being_dragged = false
    # Re-enable collision
    if collision_shape:
        collision_shape.disabled = false
    # Now check for overlapping objects for fusion
    try_fusion_with_nearby()
```

## Development Workflow Tips

### ✅ Test Early, Test Often
1. Create a minimal main scene first
2. Add one system at a time
3. Test after each major addition
4. Use print statements liberally for debugging

### ✅ Error-Driven Development
1. Run the game after each change
2. Fix errors immediately as they appear
3. Don't accumulate technical debt
4. Each error teaches you about Godot's constraints

### ✅ Mobile-First Design
1. Test touch input from the beginning
2. Design UI for finger-sized touch targets
3. Consider performance on lower-end devices
4. Use mobile renderer settings from the start

---

*This document is a living guide based on real development experience with Godot 4.5.1. Update it as you encounter new patterns and solutions.*