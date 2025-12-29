class_name CatBehaviorController extends Node

@export var behavior_set: Array = ["idle", "walk", "sit", "meow", "play"]
@export var current_behavior: String = "idle"
@export var behavior_timer: float = 0.0

var cat_owner: Node2D
var behavior_durations = {
	"idle": [2.0, 5.0],
	"walk": [1.0, 3.0],
	"sit": [3.0, 6.0],
	"meow": [0.5, 1.0],
	"play": [6.0, 12.0],  # Longer duration to reach and play with ball
	"nap": [4.0, 8.0],
	"groom": [2.0, 4.0]
}

signal behavior_changed(new_behavior: String)

# Meow cooldown to prevent too frequent meowing
var meow_cooldown: float = 0.0
const MEOW_COOLDOWN_MIN: float = 15.0  # Minimum seconds between meows
const MEOW_COOLDOWN_MAX: float = 45.0  # Maximum seconds between meows

func _ready():
	if get_parent():
		cat_owner = get_parent()
	# Random initial delay so cats don't sync up
	behavior_timer = randf_range(0.5, 3.0)
	# Start with a random non-meow behavior
	current_behavior = "idle"

func _process(delta):
	behavior_timer -= delta
	if meow_cooldown > 0:
		meow_cooldown -= delta

	if behavior_timer <= 0:
		start_new_behavior()

func setup(new_behavior_set: Array):
	behavior_set = new_behavior_set

func start_new_behavior():
	if behavior_set.is_empty():
		behavior_set = ["idle"]

	# Pick a random behavior, but skip meow if on cooldown
	var available_behaviors = behavior_set.duplicate()
	if meow_cooldown > 0 and "meow" in available_behaviors:
		available_behaviors.erase("meow")

	if available_behaviors.is_empty():
		available_behaviors = ["idle"]

	var new_behavior = available_behaviors[randi() % available_behaviors.size()]
	change_behavior(new_behavior)

func change_behavior(new_behavior: String):
	current_behavior = new_behavior

	# Set random duration for this behavior
	var duration_range = behavior_durations.get(current_behavior, [2.0, 4.0])
	behavior_timer = randf_range(duration_range[0], duration_range[1])

	behavior_changed.emit(current_behavior)

	# Execute behavior
	execute_behavior()

func execute_behavior():
	if not cat_owner:
		return

	match current_behavior:
		"idle":
			execute_idle()
		"walk":
			execute_walk()
		"sit":
			execute_sit()
		"meow":
			execute_meow()
		"play":
			execute_play()
		"nap":
			execute_nap()
		"groom":
			execute_groom()

func execute_idle():
	if cat_owner.has_method("play_animation"):
		cat_owner.play_animation("idle")

func execute_walk():
	if cat_owner.has_method("start_walking"):
		cat_owner.start_walking()

func execute_sit():
	if cat_owner.has_method("play_animation"):
		cat_owner.play_animation("sit")

func execute_meow():
	if cat_owner.has_method("play_animation"):
		cat_owner.play_animation("meow")
	# Set cooldown so this cat doesn't meow again too soon
	meow_cooldown = randf_range(MEOW_COOLDOWN_MIN, MEOW_COOLDOWN_MAX)

func execute_play():
	# Try to play with the ball if it exists
	print("BehaviorController: execute_play called, room_ball=%s" % GameManager.room_ball)
	if GameManager.room_ball and cat_owner.has_method("start_playing_with_ball"):
		cat_owner.start_playing_with_ball(GameManager.room_ball)
	elif cat_owner.has_method("play_animation"):
		print("BehaviorController: No ball, just playing animation")
		cat_owner.play_animation("play")

func execute_nap():
	if cat_owner.has_method("start_napping"):
		cat_owner.start_napping()
	elif cat_owner.has_method("play_animation"):
		cat_owner.play_animation("nap")

func execute_groom():
	if cat_owner.has_method("play_animation"):
		cat_owner.play_animation("groom")

func play_meow_sound():
	# TODO: Play random meow sound
	pass

func play_reaction(reaction: String):
	# Interrupt current behavior for a reaction
	change_behavior(reaction)