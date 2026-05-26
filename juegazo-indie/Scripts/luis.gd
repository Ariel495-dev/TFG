# Luis.gd
class_name Luis extends CharacterBody2D

@onready var movement_component: Movement_Component    = %Movement_Component
@onready var health_component: Health_Component        = %Health_Component
@onready var progress_bar_component: ProgressBarComponent = %ProgressBarComponent
@onready var background_bar: TextureRect = $HealthBar/Background
@onready var top_bar: TextureRect        = $HealthBar/TopBar
@onready var bottom_bar: TextureRect     = $HealthBar/BottomBar

func _ready() -> void:
	health_component.died.connect(_on_died)
	progress_bar_component.setup_bars(background_bar, top_bar, bottom_bar)
	progress_bar_component.connect_to_health(health_component)

func _physics_process(delta: float) -> void:
	movement_component.tick(delta)

func on_move_input(direction: Vector2) -> void:
	movement_component.direction = direction

func on_sprint_input(is_running: bool) -> void:
	movement_component.wants_sprint = is_running

func on_hurt_input() -> void:
	health_component.damage(10)

func on_heal_input() -> void:
	health_component.heal(10)

func _on_died() -> void:
	print("Player died")
