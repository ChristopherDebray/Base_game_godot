extends ColorRect
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

func _can_drop_data(_pos: Vector2, d: Variant) -> bool:
	return d is Dictionary and d.get("model") is InventoryModel \
		and model.can_move(d["model"], d["index"], slot_index)

func _drop_data(_pos: Vector2, d: Variant) -> void:
	model.move(d["model"], d["index"], slot_index)

func _make_preview(at_position: Vector2) -> Control:
	var t := TextureRect.new()
	t.texture = icon.texture
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = size
	t.size = size
	t.modulate.a = 0.5
	t.position = -at_position
	var control := Control.new()
	control.add_child(t)
	return control
