class_name GameHUD extends Control

@onready var currency_label: Label = $VBox/CurrencyLabel
@onready var spawn_progress: ProgressBar = $VBox/SpawnProgress
@onready var spawn_timer_label: Label = $VBox/SpawnTimerLabel
@onready var info_label: Label = $VBox/InfoLabel

func _ready():
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.spawn_timer_updated.connect(_on_spawn_timer_updated)
	GameManager.fusion_completed.connect(_on_fusion_completed)

func _on_currency_changed(new_amount: int):
	if currency_label:
		currency_label.text = "Tunca Cans: %d" % new_amount

func _on_spawn_timer_updated(current_time: float, max_time: float):
	if spawn_progress:
		var progress = 1.0 - (current_time / max_time)
		spawn_progress.value = progress * 100

	if spawn_timer_label:
		spawn_timer_label.text = "Next Cat: %.1fs" % max(0, current_time)

func _on_fusion_completed(result_cat: Node2D, level: int):
	if info_label:
		info_label.text = "Fused to Level %d!" % level
		# Hide the message after 2 seconds
		create_tween().tween_callback(clear_info_message).set_delay(2.0)

func clear_info_message():
	if info_label:
		info_label.text = ""

func show_message(message: String):
	if info_label:
		info_label.text = message