extends CanvasLayer

@onready var player_health_bar:  ProgressBarComponent = $TextureRect/HealtPJBar
@onready var player_stamina_bar: ProgressBarComponent = $TextureRect/EnergiaPjBar
@onready var player_action_bar:  ProgressBarComponent = $TextureRect/AccionPjBar
@onready var enemy_health_bar:   ProgressBarComponent = %HealthBar
@onready var enemy_stamina_bar:  ProgressBarComponent = $TextureRect/EnergiaEnemyBar
@onready var enemy_action_bar:   ProgressBarComponent = $TextureRect/AccionEnemyBar
@onready var enemy_sprite_slot:  Node2D               = $TextureRect/EnemySpriteSlot
@onready var result_panel:       ResultPanel          = $ResultPanel
@onready var action_buttons:     Node2D               = $TextureRect/GuardButtom

var _turn_component:    TurnComponent    = null
var _luis_ref:          Luis             = null
var _enemy_action_ref:  ActionComponent  = null
var _enemy_stamina_ref: StaminaComponent = null
var _enemy_health_ref:  Health_Component = null
var _enemy_data:        Dictionary       = {}
var _is_player_turn:    bool             = false
var _combat_over:       bool             = false

func _ready() -> void:
	add_to_group("combat_ui")
	result_panel.hide()
	action_buttons.hide()
	print("[CombatUI] Listo")

func initialize(data: Dictionary, luis: Luis) -> void:
	print("[CombatUI] Inicializando combate")
	_combat_over       = false
	_is_player_turn    = false
	_luis_ref          = luis
	_enemy_action_ref  = data.get("action_component")
	_enemy_stamina_ref = data.get("stamina_component")
	_enemy_health_ref  = data.get("health_component")
	_enemy_data        = data

	await get_tree().process_frame

	player_health_bar.setup_bars(
		player_health_bar.get_node("Background"),
		player_health_bar.get_node("TopBar"),
		player_health_bar.get_node("BottomBar")
	)
	player_stamina_bar.setup_bars(
		player_stamina_bar.get_node("Background"),
		player_stamina_bar.get_node("TopBar"),
		player_stamina_bar.get_node("BottomBar")
	)
	player_action_bar.setup_bars(
		player_action_bar.get_node("Background"),
		player_action_bar.get_node("TopBar"),
		player_action_bar.get_node("BottomBar")
	)
	enemy_health_bar.setup_bars(
		enemy_health_bar.get_node("Background"),
		enemy_health_bar.get_node("TopBar"),
		enemy_health_bar.get_node("BottomBar")
	)
	enemy_stamina_bar.setup_bars(
		enemy_stamina_bar.get_node("Background"),
		enemy_stamina_bar.get_node("TopBar"),
		enemy_stamina_bar.get_node("BottomBar")
	)
	enemy_action_bar.setup_bars(
		enemy_action_bar.get_node("Background"),
		enemy_action_bar.get_node("TopBar"),
		enemy_action_bar.get_node("BottomBar")
	)

	await get_tree().process_frame

	player_health_bar.connect_to_health(_luis_ref.health_component)

	_luis_ref.stamina_component.reset()
	_luis_ref.stamina_component.stamina_changed.connect(
		func(cur, max_val):
			player_stamina_bar.set_max(max_val)
			player_stamina_bar.set_value(cur)
	)
	player_stamina_bar.set_max(_luis_ref.stamina_component.max_stamina)
	player_stamina_bar.set_value(0.0)

	_luis_ref.action_component.reset()
	_luis_ref.action_component.action_changed.connect(
		func(cur, max_val):
			player_action_bar.set_max(max_val)
			player_action_bar.set_value(cur)
	)
	player_action_bar.set_max(100.0)
	player_action_bar.set_value(0.0)

	enemy_health_bar.connect_to_health(_enemy_health_ref)

	_enemy_stamina_ref.reset()
	_enemy_stamina_ref.stamina_changed.connect(
		func(cur, max_val):
			enemy_stamina_bar.set_max(max_val)
			enemy_stamina_bar.set_value(cur)
	)
	enemy_stamina_bar.set_max(data.get("max_stamina", 100.0))
	enemy_stamina_bar.set_value(0.0)

	_enemy_action_ref.reset()
	_enemy_action_ref.action_changed.connect(
		func(cur, max_val):
			enemy_action_bar.set_max(max_val)
			enemy_action_bar.set_value(cur)
	)
	enemy_action_bar.set_max(100.0)
	enemy_action_bar.set_value(0.0)

	var sprite_node = data.get("sprite_node", null)
	if is_instance_valid(sprite_node):
		sprite_node.get_parent().remove_child(sprite_node)
		enemy_sprite_slot.add_child(sprite_node)
		sprite_node.position = Vector2.ZERO
		print("[CombatUI] Sprite del enemigo añadido")

	_turn_component = TurnComponent.new()
	add_child(_turn_component)
	_turn_component.player_turn_started.connect(_on_player_turn)
	_turn_component.enemy_turn_started.connect(_on_enemy_turn)

	_luis_ref.action_component.action_ready.connect(_turn_component.notify_player_ready)
	_enemy_action_ref.action_ready.connect(_turn_component.notify_enemy_ready)

	_luis_ref.health_component.died.connect(_on_player_died)
	_enemy_health_ref.died.connect(_on_enemy_died)

	_luis_ref.stamina_component.start_regen()
	_enemy_stamina_ref.start_regen()
	_luis_ref.action_component.start_filling()
	_enemy_action_ref.start_filling()

	_turn_component.start_waiting()

	result_panel.rematch_requested.connect(_on_rematch_requested)
	result_panel.timeout_exit.connect(_on_timeout_exit)

	print("[CombatUI] Inicialización completa")

func _on_player_turn() -> void:
	if _combat_over:
		return
	print("[CombatUI] Turno del jugador")
	_is_player_turn = true
	_luis_ref.action_component.pause_filling()
	_enemy_action_ref.pause_filling()
	_luis_ref.stamina_component.pause_regen()
	_enemy_stamina_ref.pause_regen()
	action_buttons.show()

func on_attack_pressed() -> void:
	if not _is_player_turn or _combat_over:
		return
	print("[CombatUI] Jugador ataca")
	_is_player_turn = false
	action_buttons.hide()

	var stats:        Dictionary = _luis_ref.stats_component.get_stats()
	var damage:       float      = stats["damage"]
	var enemy_armor:  float      = _enemy_data.get("defense", 0.0)
	var final_damage: float      = max(1.0, damage - enemy_armor)

	_luis_ref.stamina_component.spend(20.0)
	_enemy_health_ref.damage(final_damage)
	print("[CombatUI] Daño aplicado: %.1f (base %.1f - armor %.1f) | Enemigo HP: %.1f" % [
		final_damage, damage, enemy_armor, _enemy_health_ref.current_health
	])

	var vampirismo: float = stats["vampirismo"]
	if vampirismo > 0.0:
		_luis_ref.health_component.heal(vampirismo)
		print("[CombatUI] Vampirismo: +%.1f HP a Luis" % vampirismo)

	if _combat_over:
		return
	_end_player_turn()

func _end_player_turn() -> void:
	_luis_ref.action_component.consume()
	_luis_ref.stamina_component.resume_regen()
	_enemy_stamina_ref.resume_regen()
	_turn_component.resume_after_player()
	await get_tree().process_frame
	await get_tree().process_frame
	if not _combat_over:
		_luis_ref.action_component.resume_filling()
		_enemy_action_ref.resume_filling()

func _on_enemy_turn() -> void:
	if _combat_over:
		return
	print("[CombatUI] Turno del enemigo")
	_luis_ref.action_component.pause_filling()
	_enemy_action_ref.pause_filling()
	_luis_ref.stamina_component.pause_regen()
	_enemy_stamina_ref.pause_regen()
	action_buttons.hide()

	var enemy_attack: float = _enemy_data.get("attack", 10.0)
	var luis_armor:   float = _luis_ref.stats_component.armor
	var final_damage: float = max(1.0, enemy_attack - luis_armor)

	_enemy_stamina_ref.spend(20.0)
	_luis_ref.health_component.damage(final_damage)
	print("[CombatUI] Enemigo ataca: %.1f (base %.1f - armor %.1f) | Luis HP: %.1f" % [
		final_damage, enemy_attack, luis_armor, _luis_ref.health_component.current_health
	])

	if _combat_over:
		return
	_end_enemy_turn()

func _end_enemy_turn() -> void:
	_enemy_action_ref.consume()
	_luis_ref.stamina_component.resume_regen()
	_enemy_stamina_ref.resume_regen()
	_turn_component.resume_after_enemy()
	await get_tree().process_frame
	await get_tree().process_frame
	if not _combat_over:
		_luis_ref.action_component.resume_filling()
		_enemy_action_ref.resume_filling()

func _on_player_died() -> void:
	if _combat_over:
		return
	_combat_over = true
	print("[CombatUI] Luis ha muerto → derrota")
	_stop_all()
	action_buttons.hide()
	result_panel.show_result("defeat")

func _on_enemy_died() -> void:
	if _combat_over:
		return
	_combat_over = true
	print("[CombatUI] Enemigo ha muerto → victoria")
	_stop_all()
	action_buttons.hide()
	result_panel.show_result("victory")

func _stop_all() -> void:
	_luis_ref.action_component.stop_filling()
	_enemy_action_ref.stop_filling()
	_luis_ref.stamina_component.stop_regen()
	_enemy_stamina_ref.stop_regen()

func _on_rematch_requested() -> void:
	print("[CombatUI] Revancha solicitada")
	SceneCombat.resolve("rematch")
	SceneCombat.rematch()

func _on_timeout_exit() -> void:
	print("[CombatUI] Tiempo agotado, saliendo")
	SceneCombat.resolve("escape")
	if is_instance_valid(SceneCombat._enemy_ref):
		SceneCombat._enemy_ref.queue_free()

func return_sprite_to_enemy() -> void:
	if enemy_sprite_slot.get_child_count() == 0:
		return
	var sprite_node = enemy_sprite_slot.get_child(0)
	enemy_sprite_slot.remove_child(sprite_node)
	if is_instance_valid(SceneCombat._enemy_ref):
		SceneCombat._enemy_ref.add_child(sprite_node)
		sprite_node.position = Vector2.ZERO
		print("[CombatUI] Sprite devuelto al enemigo")
