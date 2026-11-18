extends Node

var _stack: Array[Control] = []

## Affiche `menu` au sommet de la pile (le menu précédent est masqué) puis donne le focus à son
## premier contrôle focusable, à la frame suivante. Ignore un `menu` nul.
func push(menu: Control) -> void:
	if menu == null:
		return
	if _stack.size() > 0:
		_stack.back().hide()
	_stack.append(menu)
	menu.show()
	await get_tree().process_frame
	_grab_first_focus(menu)

## Masque le menu du sommet et ré-affiche le précédent avec son focus. Sans effet si la pile est vide.
func pop() -> void:
	if _stack.size() == 0:
		return
	var top: Control = _stack.pop_back()
	top.hide()
	if _stack.size() > 0:
		var prev: Control = _stack.back()
		prev.show()
		await get_tree().process_frame
		_grab_first_focus(prev)

## Vide la pile en masquant tous les menus, sans rien ré-afficher.
func clear() -> void:
	while _stack.size() > 0:
		var top: Control = _stack.pop_back()
		top.hide()

func _grab_first_focus(root: Control) -> void:
	var node := _find_first_focusable(root)
	if node:
		node.grab_focus()

func _find_first_focusable(root: Node) -> Control:
	for c in root.get_children():
		if c is Control and c.visible and c.focus_mode != Control.FOCUS_NONE:
			return c
		var deep := _find_first_focusable(c)
		if deep:
			return deep
	return null
