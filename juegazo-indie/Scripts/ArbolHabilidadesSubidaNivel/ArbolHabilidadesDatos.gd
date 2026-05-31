extends Node

var mejoras: Dictionary = {}

const DEPENDENCIAS: Dictionary = {
	# Agilidad (cadena normal)
	"agilidad1":    [],
	"agilidad2":    ["agilidad1"],
	"agilidad3":    ["agilidad2"],
	"agilidad4":    ["agilidad3"],
	"agilidad5":    ["agilidad4"],
	"agilidad6":    ["agilidad5"],
	
	# Vida (cadena normal)
	"vida1":        [],
	"vida2":        ["vida1"],
	"vida3":        ["vida2"],
	"vida4":        ["vida3"],
	"vida5":        ["vida4"],
	"vida6":        ["vida5"],
	
	# Daño (cadena normal)
	"danho1":       [],
	"danho2":       ["danho1"],
	"danho3":       ["danho2"],
	"danho4":       ["danho3"],
	"danho5":       ["danho4"],
	"danho6":       ["danho5"],
	
	# Fogata: requiere agilidad nivel 2 y vida nivel 2
	"fogata":       ["agilidad2", "vida2"],
	
	# Regeneracion: requiere agilidad nivel 2 y daño nivel 2 (el nodo se llama "regen")
	"regen":        ["agilidad2", "danho2"],
	
	# Vampirismo: requiere vida nivel 4 y agilidad nivel 4
	"vampirismo":   ["vida4", "agilidad4"],
	
	# Defensa: requiere agilidad nivel 4 y vida nivel 4
	"defensa":      ["agilidad4", "vida4"],
	
	# Estrella: requiere agilidad nivel 3, daño nivel 3 y vida nivel 3
	"estrella":     ["agilidad3", "danho3", "vida3"],
}

func _ready() -> void:
	reset_all()

func reset_all() -> void:
	for nombre in DEPENDENCIAS.keys():
		mejoras[nombre] = false
	print("[ArbolHabilidadesDatos] Todas las mejoras reiniciadas a false")

func can_unlock(nombre: String, fragmentos: int, precio: int) -> bool:
	if not DEPENDENCIAS.has(nombre):
		return false
	if mejoras.get(nombre, false):
		return false
	if fragmentos < precio:
		return false
	for dep in DEPENDENCIAS[nombre]:
		if not mejoras.get(dep, false):
			return false
	return true

func unlock(nombre: String) -> void:
	if mejoras.has(nombre):
		mejoras[nombre] = true
		print("[ArbolHabilidadesDatos] Desbloqueada: ", nombre)
