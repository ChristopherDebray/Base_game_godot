class_name ElectronicDeviceComponentTest
extends GdUnitTestSuite

## Tests de l'ElectronicDeviceComponent (état allumé / éteint / cassé d'un appareil).
##
## Le composant est instancié seul : aucune dépendance au SceneTree n'est nécessaire.

var _device: ElectronicDeviceComponent


func before_test() -> void:
	_device = auto_free(ElectronicDeviceComponent.new())


func test_device_is_on_by_default() -> void:
	assert_int(_device.state).is_equal(ElectronicDeviceComponent.DeviceState.ON)
	assert_bool(_device.is_active()).is_true()


func test_turn_off_deactivates_device() -> void:
	_device.turn_off()

	assert_int(_device.state).is_equal(ElectronicDeviceComponent.DeviceState.OFF)
	assert_bool(_device.is_active()).is_false()


func test_turn_on_reactivates_device() -> void:
	_device.turn_off()

	_device.turn_on()

	assert_bool(_device.is_active()).is_true()


func test_toggle_switches_between_on_and_off() -> void:
	_device.toggle()
	assert_bool(_device.is_active()).is_false()

	_device.toggle()
	assert_bool(_device.is_active()).is_true()


func test_break_device_sets_broken_state() -> void:
	_device.break_device()

	assert_int(_device.state).is_equal(ElectronicDeviceComponent.DeviceState.BROKEN)
	assert_bool(_device.is_active()).is_false()


func test_broken_device_cannot_be_turned_on() -> void:
	_device.break_device()

	_device.turn_on()

	assert_int(_device.state).is_equal(ElectronicDeviceComponent.DeviceState.BROKEN)


func test_broken_device_ignores_toggle_and_turn_off() -> void:
	_device.break_device()

	_device.toggle()
	_device.turn_off()

	assert_int(_device.state).is_equal(ElectronicDeviceComponent.DeviceState.BROKEN)


func test_state_change_emits_signal_with_new_state() -> void:
	var monitor := monitor_signals(_device)

	_device.turn_off()

	await assert_signal(monitor).is_emitted("state_changed", [ElectronicDeviceComponent.DeviceState.OFF])


func test_unchanged_state_does_not_emit_signal() -> void:
	var monitor := monitor_signals(_device)

	_device.turn_on()

	await assert_signal(monitor).is_not_emitted("state_changed")


func test_ignored_command_on_broken_device_does_not_emit_signal() -> void:
	_device.break_device()
	var monitor := monitor_signals(_device)

	_device.turn_on()

	await assert_signal(monitor).is_not_emitted("state_changed")
