class_name EnemyScene extends CharacterBody2D

@export var enemy_name:    String       = "Goblin"
@export var max_hp:        float        = 20
@export var max_stamina:   float        = 100.0
@export var stamina_regen: float        = 80.0
@export var action_regen:  float        = 300.0
@export var attack:        float        = 3.0
@export var defense:       float        = 0
@export var xp_reward:     float        = 30.0
@export var soul_reward:   int          = 10
@export var respawn_time:  float        = 3.0
@export var sprite_frames: SpriteFrames = null

@onready var health_component:         Health_Component       = %Health_Component
@onready var stamina_component:        StaminaComponent       = %StaminaComponent
@onready var action_component:         ActionComponent        = %ActionComponent
@onready var soul_reward_component:    SoulRewardComponent    = %SoulRewardComponent
@onready var combat_trigger_component: CombatTriggerComponent = %CombatTriggerComponent
@onready var animated_sprite_2d:       AnimatedSprite2D       = $AnimatedSprite2D

func _ready() -> void:
	health_component.initialize(max_hp)
	stamina_component.initialize(max_stamina, stamina_regen)
	action_component.initialize(action_regen)
	soul_reward_component.soul_amount = soul_reward
	if sprite_frames != null:
		animated_sprite_2d.sprite_frames = sprite_frames
	health_component.died.connect(_on_died)
	combat_trigger_component.combat_requested.connect(_on_combat_requested)
	combat_trigger_component.rematch_ready.connect(_on_rematch_ready)

func _on_combat_requested(data: Dictionary) -> void:
	data["sprite_node"]       = animated_sprite_2d
	data["health_component"]  = health_component
	data["stamina_component"] = stamina_component
	data["action_component"]  = action_component
	data["max_stamina"]       = max_stamina
	SceneCombat.start(data, self)

func _on_died() -> void:
	var luis: Luis = get_tree().get_first_node_in_group("player")
	if is_instance_valid(luis):
		luis.add_xp(xp_reward)
		luis.add_fragmentos(soul_reward)
	combat_trigger_component.mark_defeated()
	visible = false
	await get_tree().create_timer(respawn_time).timeout
	_respawn()

func _respawn() -> void:
	health_component.initialize(max_hp)
	stamina_component.reset()
	action_component.reset()
	combat_trigger_component.reset_defeated()
	visible = true
	print("[EnemyScene] ", enemy_name, " ha revivido")

func _on_rematch_ready() -> void:
	health_component.current_health = max_hp
	health_component._emit()
	stamina_component.reset()
	action_component.reset()
	var data = _build_data()
	data["sprite_node"]       = animated_sprite_2d
	data["health_component"]  = health_component
	data["stamina_component"] = stamina_component
	data["action_component"]  = action_component
	data["max_stamina"]       = max_stamina
	SceneCombat.start(data, self)

func _build_data() -> Dictionary:
	return {
		"name":          enemy_name,
		"max_hp":        max_hp,
		"max_stamina":   max_stamina,
		"attack":        attack,
		"defense":       defense,
		"xp_reward":     xp_reward,
		"soul_reward":   soul_reward,
		"sprite_frames": sprite_frames,
	}
