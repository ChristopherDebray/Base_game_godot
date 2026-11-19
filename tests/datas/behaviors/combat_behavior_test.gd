class_name CombatBehaviorTest
extends GdUnitTestSuite

## Teste la décision pure de `CombatBehavior` (approcher ou attaquer selon portée et vue).
## `perform_attack` est abstraite : elle est couverte par les tests des sous-classes.

const ENGAGEMENT_RANGE: float = 100.0
const WITHIN_RANGE: float = 50.0
const OUT_OF_RANGE: float = 150.0

var _behavior: CombatBehavior

func before_test() -> void:
	_behavior = CombatBehavior.new()
	_behavior.engagement_range = ENGAGEMENT_RANGE

func test_decide_within_range_with_line_of_sight_attacks() -> void:
	var action: CombatBehavior.Action = _behavior.decide(WITHIN_RANGE, true)

	assert_int(action).is_equal(CombatBehavior.Action.ATTACK)

func test_decide_exactly_at_range_attacks() -> void:
	var action: CombatBehavior.Action = _behavior.decide(ENGAGEMENT_RANGE, true)

	assert_int(action).is_equal(CombatBehavior.Action.ATTACK)

func test_decide_out_of_range_approaches() -> void:
	var action: CombatBehavior.Action = _behavior.decide(OUT_OF_RANGE, true)

	assert_int(action).is_equal(CombatBehavior.Action.APPROACH)

func test_decide_within_range_without_line_of_sight_approaches() -> void:
	var action: CombatBehavior.Action = _behavior.decide(WITHIN_RANGE, false)

	assert_int(action).is_equal(CombatBehavior.Action.APPROACH)
