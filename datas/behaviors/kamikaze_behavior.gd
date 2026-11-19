## Combat kamikaze : l'ennemi fonce jusqu'à courte portée puis déclenche son arme explosive
## (voir `ExplosiveWeapon`).
class_name KamikazeBehavior
extends CombatBehavior

const DEFAULT_KAMIKAZE_ENGAGEMENT_RANGE: float = 48.0

func _init() -> void:
	engagement_range = DEFAULT_KAMIKAZE_ENGAGEMENT_RANGE
