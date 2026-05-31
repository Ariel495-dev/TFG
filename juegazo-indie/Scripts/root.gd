extends Node

const ARBOL_SCENE = preload("res://escenas/ArbolHabilidades.tscn")
const MUNDO_SCENE = preload("res://escenas/mundo.tscn")

@onready var world: Node2D = $Node2D
@onready var luis: Luis = $Node2D/Luis
@onready var input_component: InputComponent = $InputComponent
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer2D
@onready var deny_player: AudioStreamPlayer = $AudioStreamPlayerDeny

var mejoras: Dictionary = {}
var _arbol_ui: Node = null


func _ready() -> void:
	print("[Root] Inicializando")
	process_mode = Node.PROCESS_MODE_ALWAYS
	input_component.process_mode = Node.PROCESS_MODE_ALWAYS

	input_component.attack_pressed.connect(_on_attack_pressed)
	input_component.rematch_pressed.connect(_on_rematch_pressed)
	input_component.volver_pressed.connect(_on_volver_pressed)
	input_component.ver_arbol_pressed.connect(_on_ver_arbol_pressed)
	input_component.moved.connect(luis.on_move_input)
	input_component.sprint_changed.connect(luis.on_sprint_input)

	SceneCombat.combat_started.connect(_on_combat_started)
	SceneCombat.combat_ended.connect(_on_combat_ended)
	luis.health_component.died.connect(_on_luis_died)

	# Configurar audio
	if audio_player == null:
		audio_player = AudioStreamPlayer.new()
		audio_player.name = "AudioStreamPlayer"
		add_child(audio_player)
	
	if deny_player == null:
		deny_player = AudioStreamPlayer.new()
		deny_player.name = "DenyAudioStreamPlayer"
		add_child(deny_player)

	print("[Root] Listo")


func _process(_delta: float) -> void:
	input_component.update()


func _conectar_mejoras() -> void:
	var count := 0
	for mejora in get_tree().get_nodes_in_group("mejora"):
		var comp: UpgradeComponent = null
		
		if mejora is UpgradeComponent:
			comp = mejora
		else:
			for hijo in mejora.get_children():
				if hijo is UpgradeComponent:
					comp = hijo
					break
		
		if comp == null:
			continue
		
		if comp.upgrade_requested.is_connected(_on_upgrade_requested):
			comp.upgrade_requested.disconnect(_on_upgrade_requested)
		if comp.upgrade_completed.is_connected(_on_upgrade_completed):
			comp.upgrade_completed.disconnect(_on_upgrade_completed)
		
		comp.upgrade_requested.connect(_on_upgrade_requested)
		comp.upgrade_completed.connect(_on_upgrade_completed)
		
		comp.reset_visual()
		count += 1
	
	print("[Root] Mejoras conectadas:", count)


func _on_combat_started(_data: Dictionary) -> void:
	world.hide()


func _on_combat_ended(_result: String) -> void:
	world.show()


func _on_luis_died() -> void:
	print("[Root] Luis murio, recargando mundo")
	if is_instance_valid(_arbol_ui):
		_arbol_ui.queue_free()
		_arbol_ui = null
	
	var fragmentos_guardados := luis.get_fragmentos()
	var estrellas_guardadas := luis.estrellas
	
	world.queue_free()
	await get_tree().process_frame
	
	var nuevo_mundo = MUNDO_SCENE.instantiate()
	nuevo_mundo.name = "Node2D"
	add_child(nuevo_mundo)
	world = nuevo_mundo
	
	await get_tree().process_frame
	luis = world.get_node("Luis")
	
	input_component.moved.connect(luis.on_move_input)
	input_component.sprint_changed.connect(luis.on_sprint_input)
	luis.health_component.died.connect(_on_luis_died)
	
	luis.soul_component.current_souls = fragmentos_guardados
	luis.soul_component.souls_changed.emit(fragmentos_guardados)
	luis.estrellas = estrellas_guardadas


func _on_attack_pressed() -> void:
	var combat_ui = get_tree().get_first_node_in_group("combat_ui")
	if is_instance_valid(combat_ui):
		combat_ui.on_attack_pressed()


func _on_rematch_pressed() -> void:
	var combat_ui = get_tree().get_first_node_in_group("combat_ui")
	if is_instance_valid(combat_ui) and combat_ui.visible:
		var result_panel = combat_ui.get_node("ResultPanel")
		if is_instance_valid(result_panel) and result_panel.visible:
			result_panel.rematch_requested.emit()


func _on_ver_arbol_pressed() -> void:
	if SceneCombat._combat_active:
		return
	if is_instance_valid(_arbol_ui):
		return
	
	world.hide()
	_arbol_ui = ARBOL_SCENE.instantiate()
	_arbol_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_arbol_ui)
	
	await get_tree().process_frame
	await get_tree().process_frame
	_conectar_mejoras()


func _on_volver_pressed() -> void:
	if is_instance_valid(_arbol_ui):
		_arbol_ui.queue_free()
		_arbol_ui = null
		world.show()


func _on_upgrade_requested(node_name: String, precio: int) -> void:
	var puede: bool = ArbolHabilidadesDatos.can_unlock(node_name, luis.get_fragmentos(), precio)
	
	var comp: UpgradeComponent = null
	for mejora in get_tree().get_nodes_in_group("mejora"):
		var test_comp: UpgradeComponent = null
		if mejora is UpgradeComponent:
			test_comp = mejora
		else:
			for hijo in mejora.get_children():
				if hijo is UpgradeComponent:
					test_comp = hijo
					break
		
		if test_comp != null and test_comp.mejora_id == node_name:
			comp = test_comp
			break
	
	if comp == null:
		return
	
	if puede:
		comp.allow_unlock()
	else:
		comp.deny_unlock()


func _on_upgrade_completed(node_name: String, cantidad: int, precio: int) -> void:
	mejoras[node_name] = true
	
	if not luis.spend_fragmentos(precio):
		return
	
	ArbolHabilidadesDatos.unlock(node_name)
	
	if node_name == "estrella":
		luis.add_estrella()


# Funciones de audio llamadas desde ArbolUI
func _on_upgrade_audio_play() -> void:
	if audio_player != null and audio_player.stream != null:
		audio_player.stop()
		audio_player.play()


func _on_upgrade_audio_stop() -> void:
	if audio_player != null:
		audio_player.stop()


func _on_upgrade_audio_deny() -> void:
	if deny_player != null and deny_player.stream != null:
		deny_player.stop()
		deny_player.play()
	elif audio_player != null and audio_player.stream != null:
		audio_player.stop()
		audio_player.play()
