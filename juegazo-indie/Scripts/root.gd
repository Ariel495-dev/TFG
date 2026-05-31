extends Node

# ============ ESCENAS ============
const MUNDO_SCENE = preload("res://escenas/mundo.tscn")
const ARBOL_SCENE = preload("res://escenas/ArbolHabilidades.tscn")

# ============ NODOS DE MENÚ (show/hide) ============
@onready var menus_layer: Node                  = $Menus
@onready var menu_cargar_partida: CanvasLayer   = $Menus/cargar_partida
@onready var menu_crear_sesion: CanvasLayer     = $Menus/crear_sesion
@onready var menu_iniciar_sesion: CanvasLayer   = $Menus/iniciar_sesion
@onready var menu_main_menu: CanvasLayer        = $Menus/main_menu
@onready var menu_opciones: CanvasLayer         = $Menus/opciones
@onready var transicion: CanvasLayer            = $Menus/escena_intermedia_menus

# ============ NODOS DE JUEGO ============
@onready var input_component: InputComponent    = $InputComponent
@onready var audio_player: AudioStreamPlayer    = $AudioStreamPlayer2D
@onready var deny_player: AudioStreamPlayer     = $AudioStreamPlayerDeny

# ============ ESTADO DEL JUEGO ============
var world: Node2D = null
var luis: Luis = null
var _arbol_ui: Node = null
var mejoras: Dictionary = {}

# ============ ESTADO DE MENÚS ============
var _session_token: String = ""
var _current_slot: int = 0
var _transitioning: bool = false

# ============ CONFIGURACIÓN ============
var _config: Dictionary = {
	"volumen": 80,
	"musica": true,
	"efectos": true
}


func _ready() -> void:
	print("[Root] Inicializando")
	process_mode = Node.PROCESS_MODE_ALWAYS
	input_component.process_mode = Node.PROCESS_MODE_ALWAYS

	# Conectar inputs de combate/arbol (siempre activos)
	input_component.attack_pressed.connect(_on_attack_pressed)
	input_component.rematch_pressed.connect(_on_rematch_pressed)
	input_component.volver_pressed.connect(_on_volver_pressed)
	input_component.ver_arbol_pressed.connect(_on_ver_arbol_pressed)

	# Conectar señales de combate
	SceneCombat.combat_started.connect(_on_combat_started)
	SceneCombat.combat_ended.connect(_on_combat_ended)

	# Audio
	if audio_player == null:
		audio_player = AudioStreamPlayer.new()
		audio_player.name = "AudioStreamPlayer2D"
		add_child(audio_player)
	if deny_player == null:
		deny_player = AudioStreamPlayer.new()
		deny_player.name = "AudioStreamPlayerDeny"
		add_child(deny_player)

	# Menús
	_cargar_configuracion()
	_cargar_token()
	_ocultar_todos()
	_conectar_botones()
	_ir_a_inicio()

	print("[Root] Listo")


func _process(_delta: float) -> void:
	input_component.update()


# ============ SISTEMA DE TRANSICIÓN ============

func _ocultar_todos() -> void:
	menu_cargar_partida.hide()
	menu_crear_sesion.hide()
	menu_iniciar_sesion.hide()
	menu_main_menu.hide()
	menu_opciones.hide()
	transicion.hide()


func _mostrar_transicion() -> void:
	transicion.show()
	var anim := transicion.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim:
		anim.play("default")
	await get_tree().create_timer(1.0).timeout
	transicion.hide()


func _cambiar_menu(mostrar: CanvasLayer) -> void:
	if _transitioning:
		return
	_transitioning = true
	_ocultar_todos()
	await _mostrar_transicion()
	mostrar.show()
	_transitioning = false


# ============ CONECTAR BOTONES DE MENÚ ============

func _conectar_botones() -> void:
	var sc_iniciar := menu_iniciar_sesion as iniciar_sesion
	if sc_iniciar:
		sc_iniciar.iniciar.pressed.connect(_on_iniciar_sesion)
		sc_iniciar.volver.pressed.connect(_ir_a_inicio)

	var sc_crear := menu_crear_sesion as crear_sesion
	if sc_crear:
		sc_crear.enviar.pressed.connect(_on_crear_sesion)
		sc_crear.volver.pressed.connect(_ir_a_inicio)

	var sc_main := menu_main_menu as main_menu
	if sc_main:
		sc_main.jugar.pressed.connect(_ir_a_cargar_partida)
		sc_main.operaciones.pressed.connect(_ir_a_opciones)
		sc_main.salir_del_juego.pressed.connect(_on_salir_juego)

	var sc_opciones := menu_opciones as opciones
	if sc_opciones:
		sc_opciones.guadar.pressed.connect(_guardar_opciones)
		sc_opciones.salir.pressed.connect(_ir_a_main_menu)
		sc_opciones.volumen_general.value = _config["volumen"]
		sc_opciones.volumen_general.value_changed.connect(_on_volumen_cambiado)
		sc_opciones.check_button_musica.button_pressed = _config["musica"]
		sc_opciones.check_button_musica.toggled.connect(_on_musica_toggled)
		sc_opciones.check_button_efectos_sonido.button_pressed = _config["efectos"]
		sc_opciones.check_button_efectos_sonido.toggled.connect(_on_efectos_toggled)

	var sc_cargar := menu_cargar_partida as cargar_partida
	if sc_cargar:
		sc_cargar.partida_1.pressed.connect(func(): _cargar_ranura(1))
		sc_cargar.partida_2.pressed.connect(func(): _cargar_ranura(2))
		sc_cargar.partida_3.pressed.connect(func(): _cargar_ranura(3))
		sc_cargar.volver.pressed.connect(_ir_a_main_menu)


# ============ NAVEGACIÓN ============

func _ir_a_inicio() -> void:
	if _session_token != "":
		await _cambiar_menu(menu_main_menu)
	else:
		await _cambiar_menu(menu_iniciar_sesion)


func _ir_a_iniciar_sesion() -> void:
	await _cambiar_menu(menu_iniciar_sesion)


func _ir_a_crear_sesion() -> void:
	await _cambiar_menu(menu_crear_sesion)


func _ir_a_main_menu() -> void:
	await _cambiar_menu(menu_main_menu)


func _ir_a_opciones() -> void:
	await _cambiar_menu(menu_opciones)


func _ir_a_cargar_partida() -> void:
	await _cambiar_menu(menu_cargar_partida)
	_cargar_info_ranuras()


func _cargar_ranura(slot: int) -> void:
	_current_slot = slot
	_cambiar_a_juego()


# ============ MUNDO / JUEGO ============

func _cambiar_a_juego() -> void:
	if _transitioning:
		return
	_transitioning = true

	_ocultar_todos()
	await _mostrar_transicion()

	if world:
		world.queue_free()
		world = null
		await get_tree().process_frame

	world = MUNDO_SCENE.instantiate()
	world.name = "Node2D"
	add_child(world)
	await get_tree().process_frame

	_conectar_luis()
	_transitioning = false


func _conectar_luis() -> void:
	luis = world.get_node_or_null("Luis") as Luis
	if luis == null:
		print("[Root] ERROR: Luis no encontrado en el mundo")
		return

	# Desconectar primero por si acaso
	if input_component.moved.is_connected(luis.on_move_input):
		input_component.moved.disconnect(luis.on_move_input)
	if input_component.sprint_changed.is_connected(luis.on_sprint_input):
		input_component.sprint_changed.disconnect(luis.on_sprint_input)

	input_component.moved.connect(luis.on_move_input)
	input_component.sprint_changed.connect(luis.on_sprint_input)
	luis.health_component.died.connect(_on_luis_died)

	print("[Root] Luis conectado")


func _on_luis_died() -> void:
	print("[Root] Luis murio, recargando mundo")

	if is_instance_valid(_arbol_ui):
		_arbol_ui.queue_free()
		_arbol_ui = null

	var fragmentos_guardados := luis.get_fragmentos()
	var estrellas_guardadas := luis.estrellas

	world.queue_free()
	await get_tree().process_frame

	world = MUNDO_SCENE.instantiate()
	world.name = "Node2D"
	add_child(world)
	await get_tree().process_frame

	_conectar_luis()

	luis.soul_component.current_souls = fragmentos_guardados
	luis.soul_component.souls_changed.emit(fragmentos_guardados)
	luis.estrellas = estrellas_guardadas


func _volver_a_menus() -> void:
	if _transitioning:
		return
	_transitioning = true

	await _mostrar_transicion()

	if world:
		world.queue_free()
		world = null

	if is_instance_valid(_arbol_ui):
		_arbol_ui.queue_free()
		_arbol_ui = null

	luis = null
	await get_tree().process_frame
	menu_main_menu.show()
	_transitioning = false


# ============ COMBATE ============

func _on_combat_started(_data: Dictionary) -> void:
	if world:
		world.hide()


func _on_combat_ended(_result: String) -> void:
	if world:
		world.show()


func _on_attack_pressed() -> void:
	var combat_ui = get_tree().get_first_node_in_group("combat_ui")
	if is_instance_valid(combat_ui):
		combat_ui.on_attack_pressed()


func _on_rematch_pressed() -> void:
	var combat_ui = get_tree().get_first_node_in_group("combat_ui")
	if is_instance_valid(combat_ui) and combat_ui.visible:
		var result_panel = combat_ui.get_node_or_null("ResultPanel")
		if is_instance_valid(result_panel) and result_panel.visible:
			result_panel.rematch_requested.emit()


# ============ ÁRBOL DE HABILIDADES ============

func _on_ver_arbol_pressed() -> void:
	if SceneCombat._combat_active:
		return
	if is_instance_valid(_arbol_ui):
		return
	if world == null:
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
		if world:
			world.show()


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

	print("[Root] Mejoras conectadas: ", count)


func _on_upgrade_requested(node_name: String, precio: int) -> void:
	if luis == null:
		return
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


func _on_upgrade_completed(node_name: String, _cantidad: int, precio: int) -> void:
	if luis == null:
		return
	mejoras[node_name] = true

	if not luis.spend_fragmentos(precio):
		return

	ArbolHabilidadesDatos.unlock(node_name)

	if node_name == "estrella":
		luis.add_estrella()


# ============ AUDIO ============

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


# ============ GESTIÓN DE TOKEN ============

func _cargar_token() -> void:
	var path = "user://session.token"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		_session_token = file.get_line().strip_edges()
		file.close()
		print("[Root] Token cargado")


func _guardar_token(token: String) -> void:
	var file = FileAccess.open("user://session.token", FileAccess.WRITE)
	file.store_line(token)
	file.close()
	print("[Root] Token guardado")


# ============ CONFIGURACIÓN ============

func _cargar_configuracion() -> void:
	var path = "user://config.cfg"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		_config = file.get_var()
		file.close()
		_on_volumen_cambiado(_config["volumen"])
		_on_musica_toggled(_config["musica"])
		_on_efectos_toggled(_config["efectos"])
		print("[Root] Configuración cargada")


func _guardar_configuracion() -> void:
	var file = FileAccess.open("user://config.cfg", FileAccess.WRITE)
	file.store_var(_config)
	file.close()
	print("[Root] Configuración guardada")


func _on_volumen_cambiado(value: float) -> void:
	_config["volumen"] = value
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value / 100.0)


func _on_musica_toggled(button_pressed: bool) -> void:
	_config["musica"] = button_pressed
	var bus = AudioServer.get_bus_index("Musica")
	if bus != -1:
		AudioServer.set_bus_mute(bus, not button_pressed)


func _on_efectos_toggled(button_pressed: bool) -> void:
	_config["efectos"] = button_pressed
	var bus = AudioServer.get_bus_index("Efectos")
	if bus != -1:
		AudioServer.set_bus_mute(bus, not button_pressed)


func _guardar_opciones() -> void:
	_guardar_configuracion()
	_ir_a_main_menu()


# ============ PETICIONES HTTP ============

const BASE_URL = "http://localhost:8000/api"

func _get_auth_headers() -> PackedStringArray:
	return PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + _session_token
	])


func _on_iniciar_sesion() -> void:
	var scene := menu_iniciar_sesion as iniciar_sesion
	if scene == null:
		return
	var nombre = scene.nombre.text
	var contrasena = scene.contrasenha.text

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_login_response.bind(http))
	var body = JSON.stringify({"username": nombre, "password": contrasena})
	http.request(BASE_URL + "/login/", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)


func _on_login_response(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		_session_token = data["session_token"]
		_guardar_token(_session_token)
		_ir_a_main_menu()
	else:
		print("[Root] Error de login: ", response_code, " | ", body.get_string_from_utf8())
	http.queue_free()


func _on_crear_sesion() -> void:
	var scene := menu_crear_sesion as crear_sesion
	if scene == null:
		return
	var nombre = scene.nombre.text
	var contrasena = scene.contrasenha.text
	var confirmar = scene.confirmar_contrasenha.text

	if contrasena != confirmar:
		print("[Root] Las contraseñas no coinciden")
		return

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_register_response.bind(http))
	var body = JSON.stringify({
		"username": nombre,
		"password": contrasena,
		"password_confirm": confirmar
	})
	http.request(BASE_URL + "/register/", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)


func _on_register_response(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	if response_code == 201:
		var data = JSON.parse_string(body.get_string_from_utf8())
		_session_token = data["session_token"]
		_guardar_token(_session_token)
		_ir_a_main_menu()
	else:
		print("[Root] Error de registro: ", response_code, " | ", body.get_string_from_utf8())
	http.queue_free()


func _cargar_info_ranuras() -> void:
	if _session_token == "":
		return
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_slots_response.bind(http))
	http.request(BASE_URL + "/saves/", _get_auth_headers(), HTTPClient.METHOD_GET)


func _on_slots_response(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		_actualizar_ui_ranuras(data["slots"])
	else:
		print("[Root] Error al cargar ranuras: ", response_code)
	http.queue_free()


func _actualizar_ui_ranuras(slots: Array) -> void:
	var scene := menu_cargar_partida as cargar_partida
	if scene == null:
		return

	var botones = [scene.partida_1, scene.partida_2, scene.partida_3]
	for i in range(3):
		var slot_num = i + 1
		var slot_data = null
		for s in slots:
			if s["slot_number"] == slot_num:
				slot_data = s
				break

		var btn: Button = botones[i]
		if slot_data:
			btn.text = "Partida " + str(slot_num) + "\nNivel: " + str(slot_data["level_up_count"]) + "\nEstrellas: " + str(slot_data["stars"])
		else:
			btn.text = "Partida " + str(slot_num) + "\n[NUEVA PARTIDA]"


func _guardar_progreso(datos: Dictionary) -> void:
	if _session_token == "" or _current_slot == 0:
		return
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_save_response.bind(http))
	var url = BASE_URL + "/saves/" + str(_current_slot) + "/update/?partial=true"
	http.request(url, _get_auth_headers(), HTTPClient.METHOD_PUT, JSON.stringify(datos))


func _on_save_response(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray, http: HTTPRequest) -> void:
	if response_code == 200:
		print("[Root] Progreso guardado correctamente")
	else:
		print("[Root] Error al guardar: ", response_code)
	http.queue_free()


# ============ SALIR ============

func _on_salir_juego() -> void:
	get_tree().quit()
