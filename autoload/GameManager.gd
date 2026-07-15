extends Node

# ── 밸런스 설정 (tools/balance.xlsx → data/balance.json) ──
var cfg: Dictionary = {}

const BALANCE_PATH := "res://data/balance.json"

func cfg_f(sheet: String, key: String, default: float) -> float:
	if cfg.has(sheet) and cfg[sheet].has(key):
		return float(cfg[sheet][key])
	return default

func cfg_i(sheet: String, key: String, default: int) -> int:
	if cfg.has(sheet) and cfg[sheet].has(key):
		return int(cfg[sheet][key])
	return default

# ── 영구 데이터 (죽어도 유지) ─────────────────────────────
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
	_load_balance()
	load_save()

signal balance_reloaded  # 핫리로드 시 Player·Enemy에 알림

var _last_updated_at: float = 0.0
var _reload_timer:    float = 0.0
const RELOAD_INTERVAL := 1.5  # JSON 변경 체크 주기(초)

func _process(delta: float) -> void:
	_reload_timer += delta
	if _reload_timer >= RELOAD_INTERVAL:
		_reload_timer = 0.0
		_check_hot_reload()

func _check_hot_reload() -> void:
	if not FileAccess.file_exists(BALANCE_PATH): return
	var file := FileAccess.open(BALANCE_PATH, FileAccess.READ)
	if not file: return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary: return
	var ts: float = float(parsed.get("_updated_at", 0.0))
	if ts > _last_updated_at:
		_last_updated_at = ts
		cfg = parsed
		emit_signal("balance_reloaded")
		print("[GameManager] balance.json 리로드 완료")

func _load_balance() -> void:
	if not FileAccess.file_exists(BALANCE_PATH):
		push_warning("GameManager: balance.json 없음 — 기본값 사용")
		return
	var file := FileAccess.open(BALANCE_PATH, FileAccess.READ)
	if not file: return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		cfg = parsed
		_last_updated_at = float(cfg.get("_updated_at", 0.0))

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
