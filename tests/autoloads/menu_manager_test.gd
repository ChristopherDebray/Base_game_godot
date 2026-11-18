class_name MenuManagerTest
extends GdUnitTestSuite

## Tests du MenuManager (pile de menus push/pop/clear + focus manette/clavier).
##
## Le manager est instancié à part (pas l'autoload) pour ne partager aucun état. Il doit être
## dans l'arbre : `push` et `pop` attendent `process_frame` via `get_tree()`. Les menus sont des
## `Control` simples avec un bouton, seul élément focusable.

const MENU_MANAGER_SCRIPT := "res://autoloads/menu_manager.gd"

var _manager: Node


func before_test() -> void:
	_manager = auto_free(load(MENU_MANAGER_SCRIPT).new())
	add_child(_manager)


## Crée un menu visible contenant un bouton focusable, ajouté à l'arbre (le focus l'exige).
func _create_menu() -> Control:
	var menu := Control.new()
	menu.add_child(Button.new())
	add_child(auto_free(menu))
	return menu


func _button_of(menu: Control) -> Button:
	return menu.get_child(0)


func test_push_shows_menu() -> void:
	var menu := _create_menu()
	menu.hide()

	await _manager.push(menu)

	assert_bool(menu.visible).is_true()


func test_push_hides_previous_menu() -> void:
	var previous_menu := _create_menu()
	await _manager.push(previous_menu)

	await _manager.push(_create_menu())

	assert_bool(previous_menu.visible).is_false()


func test_push_gives_focus_to_first_focusable_control() -> void:
	var menu := _create_menu()

	await _manager.push(menu)

	assert_bool(_button_of(menu).has_focus()).is_true()


func test_push_null_does_not_alter_the_stack() -> void:
	var menu := _create_menu()
	await _manager.push(menu)
	await _manager.push(null)

	# Si null avait été empilé, ce pop retirerait null et laisserait le menu visible.
	await _manager.pop()

	assert_bool(menu.visible).is_false()


func test_pop_hides_top_menu() -> void:
	var menu := _create_menu()
	await _manager.push(menu)

	await _manager.pop()

	assert_bool(menu.visible).is_false()


func test_pop_shows_previous_menu() -> void:
	var previous_menu := _create_menu()
	await _manager.push(previous_menu)
	await _manager.push(_create_menu())

	await _manager.pop()

	assert_bool(previous_menu.visible).is_true()


func test_pop_restores_focus_on_previous_menu() -> void:
	var previous_menu := _create_menu()
	await _manager.push(previous_menu)
	await _manager.push(_create_menu())

	await _manager.pop()

	assert_bool(_button_of(previous_menu).has_focus()).is_true()


func test_pop_on_empty_stack_does_nothing() -> void:
	var untouched_menu := _create_menu()

	await _manager.pop()

	assert_bool(untouched_menu.visible).is_true()


func test_pop_on_exhausted_stack_keeps_menu_hidden() -> void:
	var menu := _create_menu()
	await _manager.push(menu)
	await _manager.pop()

	await _manager.pop()

	assert_bool(menu.visible).is_false()


func test_clear_hides_every_menu() -> void:
	var bottom_menu := _create_menu()
	var top_menu := _create_menu()
	await _manager.push(bottom_menu)
	await _manager.push(top_menu)

	_manager.clear()

	assert_bool(bottom_menu.visible).is_false()
	assert_bool(top_menu.visible).is_false()


func test_push_after_clear_shows_menu_again() -> void:
	var menu := _create_menu()
	await _manager.push(menu)
	_manager.clear()

	await _manager.push(menu)

	assert_bool(menu.visible).is_true()


func test_push_menu_without_focusable_control_does_not_crash() -> void:
	var menu: Control = auto_free(Control.new())
	add_child(menu)

	await _manager.push(menu)

	assert_bool(menu.visible).is_true()


func test_push_ignores_control_with_focus_disabled() -> void:
	var menu := _create_menu()
	var unfocusable_button := Button.new()
	unfocusable_button.focus_mode = Control.FOCUS_NONE
	menu.add_child(unfocusable_button)
	menu.move_child(unfocusable_button, 0)

	await _manager.push(menu)

	assert_bool(unfocusable_button.has_focus()).is_false()
	assert_bool(menu.get_child(1).has_focus()).is_true()


func test_push_finds_focusable_control_nested_in_container() -> void:
	var menu := Control.new()
	var container := VBoxContainer.new()
	var nested_button := Button.new()
	container.add_child(nested_button)
	menu.add_child(container)
	add_child(auto_free(menu))

	await _manager.push(menu)

	assert_bool(nested_button.has_focus()).is_true()


func test_pop_after_clear_does_not_show_cleared_menu() -> void:
	var menu := _create_menu()
	await _manager.push(menu)
	_manager.clear()

	await _manager.pop()

	assert_bool(menu.visible).is_false()
