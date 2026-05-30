# AscensionTree.gd — Autoload
extends Node

const SAVE_PATH = "user://ascension.save"

var unlocked: Dictionary = {}

const NODES: Array = [
	{ "id": "str_1", "name": "Músculo I",        "cost": 50,  "requires": [] },
	{ "id": "str_2", "name": "Músculo II",        "cost": 120, "requires": ["str_1"] },
	{ "id": "con_1", "name": "Piel dura I",       "cost": 50,  "requires": [] },
	{ "id": "con_2", "name": "Piel dura II",      "cost": 120, "requires": ["con_1"] },
	{ "id": "dex_1", "name": "Reflejos I",        "cost": 50,  "requires": [] },
	{ "id": "dex_2", "name": "Reflejos II",       "cost": 120, "requires": ["dex_1"] },
	{ "id": "wis_1", "name": "Claridad I",        "cost": 80,  "requires": [] },
	{ "id": "wis_2", "name": "Claridad II",       "cost": 160, "requires": ["wis_1"] },
	{ "id": "int_1", "name": "Mente abierta I",   "cost": 80,  "requires": [] },
	{ "id": "int_2", "name": "Mente abierta II",  "cost": 160, "requires": ["int_1", "wis_1"] },
]

func _ready() -> void:
	_load()

func can_unlock(id: String) -> bool:
	if unlocked.get(id, false):
		return false
	var node_def = get_def(id)
	if node_def.is_empty():
		return false
	for req in node_def["requires"]:
		if not unlocked.get(req, false):
			return false
	return true

func unlock(id: String, soul_component: SoulComponent) -> bool:
	var node_def = get_def(id)
	if node_def.is_empty() or not can_unlock(id):
		return false
	if not soul_component.spend(node_def["cost"]):
		return false
	unlocked[id] = true
	_save()
	return true

func apply_to(luis: Luis) -> void:
	if unlocked.get("str_1", false):
		luis.strength.level += 1
	if unlocked.get("str_2", false):
		luis.strength.level += 1
	if unlocked.get("con_1", false):
		luis.constitution.level += 1
	if unlocked.get("con_2", false):
		luis.constitution.level += 1
	if unlocked.get("dex_1", false):
		luis.dexterity.level += 1
	if unlocked.get("dex_2", false):
		luis.dexterity.level += 1
	if unlocked.get("wis_1", false):
		luis.wisdom.level += 1
	if unlocked.get("wis_2", false):
		luis.wisdom.level += 1
	if unlocked.get("int_1", false):
		luis.intelligence.level += 1
	if unlocked.get("int_2", false):
		luis.intelligence.level += 1

func get_def(id: String) -> Dictionary:
	for n in NODES:
		if n["id"] == id:
			return n
	return {}

func _save() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_var(unlocked)

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		unlocked = f.get_var()
