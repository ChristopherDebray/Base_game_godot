## Combat à distance : l'ennemi s'arrête loin de sa cible et tire avec l'arme qu'il tient.
class_name RangedBehavior
extends CombatBehavior

const DEFAULT_RANGED_ENGAGEMENT_RANGE: float = 300.0

func _init() -> void:
	engagement_range = DEFAULT_RANGED_ENGAGEMENT_RANGE
