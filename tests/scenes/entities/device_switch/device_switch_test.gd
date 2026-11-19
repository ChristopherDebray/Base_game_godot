class_name DeviceSwitchTest
extends GdUnitTestSuite

## Tests du DeviceSwitch (interrupteur qui allume ou éteint les appareils liés).
##
## On appelle `use()` directement : la lecture de l'input `interact` et la détection du joueur
## dépendent du moteur et sont à vérifier à la main dans le niveau.

var _switch: DeviceSwitch
var _first_device: ElectronicDeviceComponent
var _second_device: ElectronicDeviceComponent


func before_test() -> void:
	_first_device = auto_free(ElectronicDeviceComponent.new())
	_second_device = auto_free(ElectronicDeviceComponent.new())
	_switch = auto_free(DeviceSwitch.new())
	_switch.devices = [_first_device, _second_device]


func test_use_turns_off_all_active_devices() -> void:
	_switch.use()

	assert_bool(_first_device.is_active()).is_false()
	assert_bool(_second_device.is_active()).is_false()


func test_use_turns_on_all_devices_when_all_are_off() -> void:
	_first_device.turn_off()
	_second_device.turn_off()

	_switch.use()

	assert_bool(_first_device.is_active()).is_true()
	assert_bool(_second_device.is_active()).is_true()


func test_use_with_mixed_states_turns_all_off() -> void:
	_first_device.turn_off()

	_switch.use()

	assert_bool(_first_device.is_active()).is_false()
	assert_bool(_second_device.is_active()).is_false()


func test_use_leaves_broken_device_broken() -> void:
	_first_device.break_device()
	_second_device.turn_off()

	_switch.use()

	assert_int(_first_device.state).is_equal(ElectronicDeviceComponent.DeviceState.BROKEN)
	assert_bool(_second_device.is_active()).is_true()


func test_use_ignores_freed_device() -> void:
	var freed_device := ElectronicDeviceComponent.new()
	_switch.devices = [freed_device, _second_device]
	freed_device.free()

	_switch.use()

	assert_bool(_second_device.is_active()).is_false()


func test_use_without_devices_does_nothing() -> void:
	_switch.devices = []

	_switch.use()

	assert_array(_switch.devices).is_empty()


func test_scene_has_prompt_label() -> void:
	var scene: PackedScene = load("res://scenes/entities/device_switch/device_switch.tscn")
	var scene_switch: DeviceSwitch = auto_free(scene.instantiate())
	add_child(scene_switch)

	assert_object(scene_switch.prompt_label).is_not_null()
	assert_bool(scene_switch.prompt_label.visible).is_false()
