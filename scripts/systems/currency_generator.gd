class_name CurrencyGenerator extends Node

@export var base_rate: float = 1.0
@export var cat_level: int = 1
@export var generation_timer: float = 0.0

var generation_interval: float = 5.0
var currency_per_generation: int = 1

signal currency_generated(amount: int, position: Vector2)

func _ready():
	calculate_generation_values()

func _process(delta):
	generation_timer += delta
	if generation_timer >= generation_interval:
		generate_currency()
		generation_timer = 0.0

func setup(base_currency_rate: float, level: int):
	base_rate = base_currency_rate
	cat_level = level
	calculate_generation_values()

func calculate_generation_values():
	# Currency per generation scales with level
	currency_per_generation = max(1, int(base_rate * pow(cat_level, 1.5)))
	# Higher level cats generate faster
	generation_interval = max(1.0, 5.0 / sqrt(cat_level))

func generate_currency():
	GameManager.add_currency(currency_per_generation)

	# Emit signal for visual effects
	var world_position = Vector2.ZERO
	if get_parent():
		world_position = get_parent().global_position

	currency_generated.emit(currency_per_generation, world_position)

func get_hourly_rate() -> int:
	return int((currency_per_generation / generation_interval) * 3600)