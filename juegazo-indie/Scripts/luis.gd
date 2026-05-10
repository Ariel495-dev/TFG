class_name Luis extends CharacterBody2D

@onready var input_component: InputComponent = %InputComponent
@onready var movement_component: Movement_Component = %Movement_Component
@onready var health_component: Health_Component = %Health_Component
@onready var progress_bar_component: ProgressBarComponent = %ProgressBarComponent


@onready var background_bar: TextureRect = $HealthBar/Background
@onready var top_bar: TextureRect = $HealthBar/TopBar
@onready var bottom_bar: TextureRect = $HealthBar/BottomBar

func _ready() -> void:
	health_component.died.connect(_on_died)
	
	# Pasar las referencias al componente (todos TextureRect)
	progress_bar_component.setup_bars(background_bar, top_bar, bottom_bar)
	
	# Conectar la barra de vida
	progress_bar_component.connect_to_health(health_component)

func _physics_process(delta: float) -> void:
	input_component.update()
	
	movement_component.direction = input_component.move_dir
	movement_component.wants_sprint = input_component.is_running
	movement_component.tick(delta)
	
	if input_component.hurt_pressed:
		health_component.damage(10)
		
	if input_component.heal_pressed:
		health_component.heal(10)
		
func _on_died() -> void:
	print("Player died")
