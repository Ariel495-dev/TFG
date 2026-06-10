# Luis.gd
class_name Luis extends CharacterBody2D

signal estrella_changed(value: int)

@onready var movement_component:     Movement_Component   = %Movement_Component
@onready var health_component:       Health_Component     = %Health_Component
@onready var stamina_component:      StaminaComponent     = %StaminaComponent
@onready var action_component:       ActionComponent      = %ActionComponent
@onready var progress_bar_component: ProgressBarComponent = %ProgressBarComponent
@onready var soul_component:         SoulComponent        = %SoulComponent
@onready var experience_component:   ExperienceComponent  = %ExperienceComponent
@onready var stats_component:        StatsComponent       = %StatsComponent  # NUEVO

@onready var background_bar: TextureRect = $HealthBar/Background
@onready var top_bar:        TextureRect = $HealthBar/TopBar
@onready var bottom_bar:     TextureRect = $HealthBar/BottomBar

# Estos exports ya no definen los valores base de stats —
# los lleva StatsComponent. Se mantienen solo los de stamina/acción
# porque no forman parte del árbol de habilidades.
@export var player_max_stamina:   float   = 100.0
@export var player_stamina_regen: float   = 80.0
@export var spawn_position:       Vector2 = Vector2.ZERO

var estrellas: int = 0


func _ready() -> void:
	print("[Luis] Inicializando")
	add_to_group("player")

	# Conectar stats_changed ANTES de inicializar componentes
	stats_component.stats_changed.connect(_on_stats_changed)

	# Inicializar con los valores base que da StatsComponent
	var stats := stats_component.get_stats()
	health_component.initialize(stats["max_health"])
	stamina_component.initialize(player_max_stamina, player_stamina_regen)
	action_component.initialize(stats["agility"])

	health_component.died.connect(_on_died)
	progress_bar_component.setup_bars(background_bar, top_bar, bottom_bar)
	progress_bar_component.connect_to_health(health_component)

	spawn_position = global_position
	print("[Luis] Inicialización completa")


func _physics_process(delta: float) -> void:
	movement_component.tick(delta)


# ============ INPUT ============

func on_move_input(direction: Vector2) -> void:
	movement_component.direction = direction


func on_sprint_input(is_running: bool) -> void:
	movement_component.wants_sprint = is_running


# ============ STATS ============

func _on_stats_changed(stats: Dictionary) -> void:
	# Actualizar vida máxima — conservar la vida actual proporcionalmente
	var prev_max: float = health_component.max_health
	var prev_cur: float = health_component.current_health
	var new_max:  float = stats["max_health"]

	health_component.max_health    = new_max
	health_component.current_health = clamp(prev_cur + (new_max - prev_max), 0.0, new_max)
	health_component._emit()

	# Actualizar agilidad (regen rate de acción)
	action_component.set_regen(stats["agility"] as float)

	print("[Luis] Stats actualizadas → vida_max=%.0f daño=%.0f agilidad=%.0f armor=%.0f vamp=%.0f regen=%.1f" % [
		stats["max_health"], stats["damage"], stats["agility"],
		stats["armor"], stats["vampirismo"], stats["regen_vida"]
	])


func apply_upgrade(upgrade_id: String) -> void:
	stats_component.apply_upgrade(upgrade_id)


func apply_upgrades_bulk(upgrade_ids: Array) -> void:
	stats_component.apply_upgrades_bulk(upgrade_ids)


# ============ ALMAS / FRAGMENTOS ============

func add_fragmentos(amount: int) -> void:
	soul_component.add(amount)


func spend_fragmentos(amount: int) -> bool:
	return soul_component.spend(amount)


func get_fragmentos() -> int:
	return soul_component.get_souls()


# ============ XP ============

func add_xp(amount: float) -> void:
	experience_component.grant(amount)


# ============ ESTRELLAS ============

func add_estrella() -> void:
	estrellas += 1
	estrella_changed.emit(estrellas)
	print("[Luis] Estrellas: ", estrellas)


# ============ MUERTE ============

func _on_died() -> void:
	print("[Luis] Player died")
	experience_component.reset()
	soul_component.set_souls(10)
	global_position = spawn_position
	# Al morir reseteamos stats y volvemos a aplicar las mejoras
	# que root.gd reaplique con apply_upgrades_bulk tras recrear el mundo
	health_component.initialize(stats_component.max_health)
