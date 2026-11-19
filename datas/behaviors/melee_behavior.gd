## Combat au corps à corps : l'ennemi fonce jusqu'au contact puis frappe à intervalle régulier.
class_name MeleeBehavior
extends CombatBehavior

const DEFAULT_MELEE_ENGAGEMENT_RANGE: float = 28.0
const MILLISECONDS_PER_SECOND: float = 1000.0

@export var damage: float = 5.0
## Délai minimal entre deux coups, en secondes.
@export var attack_cooldown: float = 1.0

# État propre à l'instance : le `Npc` duplique la Resource pour que le cooldown ne soit pas partagé.
var _next_attack_ms: int = 0

func _init() -> void:
	engagement_range = DEFAULT_MELEE_ENGAGEMENT_RANGE

## Inflige `damage` à `target` s'il est blessable et que le cooldown est écoulé ; sinon ne fait rien.
## Démarre le cooldown à chaque coup porté.
func perform_attack(_attacker: Npc, target: Node2D) -> void:
	var damageable: Damageable = target as Damageable
	if damageable == null:
		return

	var now_ms: int = Time.get_ticks_msec()
	if now_ms < _next_attack_ms:
		return

	damageable.take_damage(damage)
	_next_attack_ms = now_ms + int(attack_cooldown * MILLISECONDS_PER_SECOND)
