extends ColorRect
## Case d'inventaire (vue) : affiche l'objet du slot `slot_index` d'un `InventoryModel` et gère
## le drag & drop vers/depuis d'autres slots. Se met à jour via `slot_changed` du modèle.
class_name InventorySlot

# pour les slots posés à la main (Head, Chest...)
@export var slot_index: int = 0

@onready var icon: TextureRect = $MarginContainer/TextureRect

var model: InventoryModel

func _ready() -> void:
	$MarginContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
## Branche le slot sur le slot `index` de `inventory_model` (débranche l'ancien modèle s'il y en a
## un) puis rafraîchit l'affichage.
func setup(inventory_model: InventoryModel, index: int) -> void:
	if model and model.slot_changed.is_connected(_on_slot_changed):
		model.slot_changed.disconnect(_on_slot_changed)
	model = inventory_model
	slot_index = index
	model.slot_changed.connect(_on_slot_changed)
	refresh()

func _on_slot_changed(index: int) -> void:
	if index == slot_index:
		refresh()

## Met à jour l'icône et le tooltip depuis l'objet courant du slot (vide si le slot l'est).
func refresh() -> void:
	var item := model.get_item(slot_index)
	if item:
		icon.texture = item.data.item_texture
		tooltip_text = "%s\n%s" % [item.data.item_name, item.data.description]
	else:
		icon.texture = null
		tooltip_text = ""

func _get_drag_data(at_position: Vector2) -> Variant:
	if model.get_item(slot_index) == null:
		return null
	set_drag_preview(_make_preview(at_position))
	return {"model": model, "index": slot_index}

func _can_drop_data(_pos: Vector2, drag_data: Variant) -> bool:
	return drag_data is Dictionary and drag_data.get("model") is InventoryModel \
		and model.can_move(drag_data["model"], drag_data["index"], slot_index)

func _drop_data(_pos: Vector2, drag_data: Variant) -> void:
	model.move(drag_data["model"], drag_data["index"], slot_index)

func _make_preview(at_position: Vector2) -> Control:
	var preview_texture := TextureRect.new()
	preview_texture.texture = icon.texture
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_texture.custom_minimum_size = size
	preview_texture.size = size
	preview_texture.modulate.a = 0.5
	preview_texture.position = -at_position
	var control := Control.new()
	control.add_child(preview_texture)
	return control
