extends CanvasLayer

func _ready() -> void:
	add_to_group("arbol_ui")
	await get_tree().process_frame
	_conectar_audio()


func _conectar_audio() -> void:
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
			print("[ArbolUI] SIN UpgradeComponent en: ", mejora.name)
			continue
		
		if not comp.audio_play.is_connected(_on_audio_play):
			comp.audio_play.connect(_on_audio_play)
		if not comp.audio_stop.is_connected(_on_audio_stop):
			comp.audio_stop.connect(_on_audio_stop)
		if not comp.audio_deny.is_connected(_on_audio_deny):
			comp.audio_deny.connect(_on_audio_deny)
		
		print("[ArbolUI] Audio conectado para: ", mejora.name)


func _on_audio_play() -> void:
	# Reenviar la señal a root
	var root = get_tree().root.get_node_or_null("Root")
	if root and root.has_method("_on_upgrade_audio_play"):
		root._on_upgrade_audio_play()


func _on_audio_stop() -> void:
	# Reenviar la señal a root
	var root = get_tree().root.get_node_or_null("Root")
	if root and root.has_method("_on_upgrade_audio_stop"):
		root._on_upgrade_audio_stop()


func _on_audio_deny() -> void:
	# Reenviar la señal a root
	var root = get_tree().root.get_node_or_null("Root")
	if root and root.has_method("_on_upgrade_audio_deny"):
		root._on_upgrade_audio_deny()
