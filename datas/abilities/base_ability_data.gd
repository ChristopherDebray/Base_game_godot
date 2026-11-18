## Données d'une capacité d'arme (dégâts, portée, cadence, sons). Resource partagée :
## ne pas y stocker d'état propre à une instance.
class_name BaseAbilityData
extends Resource

@export var damage: float;
@export var speed: float;
@export var range: float;
#cooldown in sec
@export var cooldown: float;
@export var sound: AudioStream;
@export var reload_sound: AudioStream;
