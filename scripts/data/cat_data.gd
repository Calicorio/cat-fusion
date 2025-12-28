class_name CatData extends Resource

@export var id: int
@export var level: int
@export var tier: String  # "kitten", "house", "fancy", "mystical", "legendary", "cosmic"
@export var archetype: String  # "tabby", "shorthair", "black", "persian", "calico"
@export var name: String
@export var sprite_texture: Texture2D
@export var animation_frames: Array
@export var base_currency_rate: float
@export var sprite_size: Vector2
@export var behavior_set: Array  # ["walk", "sit", "meow", "play"]
@export var unlock_cost: int
@export var particle_effect: PackedScene  # Optional for higher tiers
@export var rarity_color: Color = Color.WHITE

func get_currency_rate() -> float:
	return base_currency_rate * pow(level, 1.5)

func get_generation_interval() -> float:
	return max(1.0, 5.0 / sqrt(level))