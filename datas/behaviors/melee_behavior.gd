## Combat au corps à corps : l'ennemi fonce jusqu'au contact puis frappe avec son arme de mêlée
## (voir `MeleeWeapon`).
class_name MeleeBehavior
extends CombatBehavior

const DEFAULT_MELEE_ENGAGEMENT_RANGE: float = 28.0

func _init() -> void:
	engagement_range = DEFAULT_MELEE_ENGAGEMENT_RANGE
