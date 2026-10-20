extends TextureRect
class_name InventoryItem

var data: BaseWeaponData
var type: BaseItemData.ITEM_TYPE

func _ready():
	if data:
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		display_data(data)

func init(d: BaseItemData) -> void:
	data = d

func display_data(data: BaseWeaponData):
	texture = data.item_texture
	tooltip_text = "%s\n%s" % [data.item_name, data.description]

func _get_drag_data(at_position: Vector2) -> Variant:
	set_drag_preview(make_drag_preview(at_position))
	return self

func make_drag_preview(at_position: Vector2) -> Control:
	var t := TextureRect.new()
	t.texture = texture
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = size
	t.modulate.a = 0.5
	t.position = Vector2(-at_position)
	
	var c := Control.new()
	c.add_child(t)
	
	return c

func get_slot() -> InventorySlot:
	return get_parent() as InventorySlot
