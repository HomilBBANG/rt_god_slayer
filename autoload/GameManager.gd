extends Node

# 영구 데이터 (죽어도 유지)
var total_exp: int = 0
var deaths: int = 0
var upgrades := {
	"max_hp": 0, "atk": 0, "max_sp": 0, "max_mp": 0, "spd": 0, "crit": 0
}

# 런 데이터 (죽으면 초기화)
var run_gold: int = 0
var run_exp: int = 0
var run_kills: int = 0
var perks: Array[String] = []

const SAVE_PATH := "user://save.json"

func _ready() -> void:
	load_save()

func start_run() -> void:
	run_gold = 0
	run_exp = 0
	run_kills = 0
	perks.clear()

func on_player_died() -> void:
	deaths += 1
	total_exp += run_exp
	run_exp = 0
	run_gold = 0
	save_game()

func add_exp(amount: int) -> void:
	run_exp += amount

func add_gold(amount: int) -> void:
	run_gold += amount

func has_perk(perk: String) -> bool:
	return perk in perks

func get_upgrade_bonus(stat: String) -> float:
	var level: int = upgrades.get(stat, 0)
	match stat:
		"max_hp": return level * 0.10
		"atk":    return level * 0.05
		"max_sp": return level * 0.10
		"max_mp": return level * 0.10
		"spd":    return level * 0.05
		"crit":   return level * 0.02
	return 0.0

func save_game() -> void:
	var data := {
		"total_exp": total_exp,
		"deaths": deaths,
		"upgrades": upgrades
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var result = JSON.parse_string(file.get_as_text())
	if result is Dictionary:
		total_exp = result.get("total_exp", 0)
		deaths = result.get("deaths", 0)
		var saved_upgrades = result.get("upgrades", {})
		for k in saved_upgrades:
			upgrades[k] = saved_upgrades[k]
