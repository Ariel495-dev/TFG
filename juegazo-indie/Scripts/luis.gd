class_name Luis extends CharacterBody2D

# Añadir esta señal al principio del script
signal estrella_changed(value: int)

# ... resto de tus variables ...

@onready var movement_component:     Movement_Component   = %Movement_Component
@onready var health_component:       Health_Component     = %Health_Component
@onready var stamina_component:      StaminaComponent     = %StaminaComponent
@onready var action_component:       ActionComponent      = %ActionComponent
@onready var progress_bar_component: ProgressBarComponent = %ProgressBarComponent
@onready var soul_component:         SoulComponent        = %SoulComponent
@onready var experience_component:   ExperienceComponent  = %ExperienceComponent
@onready var background_bar:         TextureRect          = $HealthBar/Background
@onready var top_bar:                TextureRect          = $HealthBar/TopBar
@onready var bottom_bar:             TextureRect          = $HealthBar/BottomBar

@export var player_max_health:    float   = 100.0
@export var player_max_stamina:   float   = 100.0
@export var player_stamina_regen: float   = 80.0
@export var player_action_regen:  float   = 300.0
@export var spawn_position:       Vector2 = Vector2.ZERO

var estrellas: int = 0

func _ready() -> void:
	print("[Luis] Inicializando")
	add_to_group("player")
	health_component.initialize(player_max_health)
	stamina_component.initialize(player_max_stamina, player_stamina_regen)
	action_component.initialize(player_action_regen)
	health_component.died.connect(_on_died)
	progress_bar_component.setup_bars(background_bar, top_bar, bottom_bar)
	progress_bar_component.connect_to_health(health_component)
	spawn_position = global_position
	print("[Luis] Inicializacion completa")

func _physics_process(delta: float) -> void:
	movement_component.tick(delta)

func on_move_input(direction: Vector2) -> void:
	movement_component.direction = direction

func on_sprint_input(is_running: bool) -> void:
	movement_component.wants_sprint = is_running

func add_fragmentos(amount: int) -> void:
	soul_component.add(amount)

func spend_fragmentos(amount: int) -> bool:
	return soul_component.spend(amount)

func get_fragmentos() -> int:
	return soul_component.get_souls()

func add_xp(amount: float) -> void:
	experience_component.grant(amount)

func add_estrella() -> void:
	estrellas += 1
	estrella_changed.emit(estrellas)  # Añadir esta línea
	print("[Luis] Estrellas: ", estrellas)

func _on_died() -> void:
	print("[Luis] Player died")
	experience_component.reset()
	soul_component.set_souls(10)  # Al morir, reinicia a 10 fragmentos
	global_position = spawn_position
	health_component.initialize(player_max_health)
