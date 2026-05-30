# CombatUI.gd
extends CanvasLayer

@onready var player_health_bar:  ProgressBarComponent = $TextureRect/HealtPJBar
@onready var player_stamina_bar: ProgressBarComponent = $TextureRect/EnergiaPjBar
@onready var player_action_bar:  ProgressBarComponent = $TextureRect/AccionPjBar
@onready var enemy_health_bar:   ProgressBarComponent = %HealthBar
@onready var enemy_stamina_bar:  ProgressBarComponent = $TextureRect/EnergiaEnemyBar
@onready var enemy_action_bar:   ProgressBarComponent = $TextureRect/AccionEnemyBar
@onready var enemy_sprite_slot:  Node2D               = $TextureRect/EnemySpriteSlot
@onready var result_panel:       Control               = $ResultPanel
@onready var action_buttons:     Node2D                = $TextureRect/GuardButtom

var _turn_component:    TurnComponent    = null
var _luis_ref:          Luis             = null
var _enemy_action_ref:  ActionComponent  = null
var _enemy_stamina_ref: StaminaComponent = null
var _enemy_data:        Dictionary       = {}

func _ready() -> void:
	add_to_group("combat_ui")
	result_panel.hide()
	action_buttons.hide()

func initialize(data: Dictionary, luis: Luis) -> void:
	_luis_ref          = luis
	_enemy_action_ref  = data.get("action_component")
	_enemy_stamina_ref = data.get("stamina_component")
	_enemy_data        = data

	# ── Salud del jugador ──────────────────────────────────────
	player_health_bar.connect_to_health(luis.health_component)

	# ── Energía del jugador: empieza en cero ───────────────────
	luis.stamina_component.reset()
	luis.stamina_component.stamina_changed.connect(
		func(cur, max):
			player_stamina_bar.set_max(max)
			player_stamina_bar.set_value(cur)
	)
	player_stamina_bar.set_max(luis.stamina_component.max_stamina)
	player_stamina_bar.set_value(0.0)

	# ── Acción del jugador: empieza en cero ────────────────────
	luis.action_component.reset()
	luis.action_component.action_changed.connect(
		func(cur, _max):
			player_action_bar.set_value(cur)
	)
	player_action_bar.set_max(100.0)
	player_action_bar.set_value(0.0)

	# ── Salud del enemigo ──────────────────────────────────────
	enemy_health_bar.connect_to_health(data.get("health_component"))

	# ── Energía del enemigo: empieza en cero ───────────────────
	_enemy_stamina_ref.reset()
	_enemy_stamina_ref.stamina_changed.connect(
		func(cur, max):
			enemy_stamina_bar.set_max(max)
			enemy_stamina_bar.set_value(cur)
	)
	enemy_stamina_bar.set_max(data.get("max_stamina", 100.0))
	enemy_stamina_bar.set_value(0.0)

	# ── Acción del enemigo: empieza en cero ────────────────────
	_enemy_action_ref.reset()
	_enemy_action_ref.action_changed.connect(
		func(cur, _max):
			enemy_action_bar.set_value(cur)
	)
	enemy_action_bar.set_max(100.0)
	enemy_action_bar.set_value(0.0)

	# ── Sprite del enemigo ─────────────────────────────────────
	var sprite_node = data.get("sprite_node", null)
	if is_instance_valid(sprite_node):
		sprite_node.get_parent().remove_child(sprite_node)
		enemy_sprite_slot.add_child(sprite_node)
		sprite_node.position = Vector2.ZERO

	# ── TurnComponent ──────────────────────────────────────────
	_turn_component = TurnComponent.new()
	add_child(_turn_component)
	_turn_component.player_turn_started.connect(_on_player_turn)
	_turn_component.enemy_turn_started.connect(_on_enemy_turn)

	luis.action_component.action_ready.connect(_turn_component.notify_player_ready)
	_enemy_action_ref.action_ready.connect(_turn_component.notify_enemy_ready)

	# Arranca todo
	luis.stamina_component.start_regen()
	_enemy_stamina_ref.start_regen()
	luis.action_component.start_filling()
	_enemy_action_ref.start_filling()

	result_panel.rematch_requested.connect(_on_rematch_requested)

func _on_player_turn() -> void:
	_luis_ref.action_component.stop_filling()
	_enemy_action_ref.stop_filling()
	_luis_ref.stamina_component.stop_regen()
	_enemy_stamina_ref.stop_regen()
	action_buttons.show()

func _on_attack_input() -> void:
	var enemy_health: Health_Component = _enemy_data.get("health_component")
	if is_instance_valid(enemy_health):
		enemy_health.damage(10.0)
	_end_player_turn()

func _end_player_turn() -> void:
	action_buttons.hide()
	_luis_ref.action_component.consume()
	_turn_component.resume_after_player()
	_luis_ref.stamina_component.start_regen()
	_enemy_stamina_ref.start_regen()
	_luis_ref.action_component.start_filling()
	_enemy_action_ref.start_filling()

func _on_enemy_turn() -> void:
	action_buttons.hide()
	_luis_ref.health_component.damage(10.0)
	_enemy_action_ref.consume()
	await get_tree().create_timer(1.2).timeout
	_turn_component.resume_after_enemy()
	_luis_ref.stamina_component.start_regen()
	_enemy_stamina_ref.start_regen()
	_luis_ref.action_component.start_filling()
	_enemy_action_ref.start_filling()

func _on_rematch_requested() -> void:
	SceneCombat.rematch()

func return_sprite_to_enemy() -> void:
	if enemy_sprite_slot.get_child_count() == 0:
		return
	var sprite_node = enemy_sprite_slot.get_child(0)
	enemy_sprite_slot.remove_child(sprite_node)
	if is_instance_valid(SceneCombat._enemy_ref):
		SceneCombat._enemy_ref.add_child(sprite_node)
		sprite_node.position = Vector2.ZERO
