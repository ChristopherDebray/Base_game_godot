## Données d'une arme : capacités primaire/secondaire, munitions et cadence de tir.
class_name BaseWeaponData
extends BaseItemData

@export var primary_ability: BaseAbilityData
@export var secondary_ability: BaseAbilityData = null
@export var max_ammunitions: int
@export var fire_rate: float = 0.15
