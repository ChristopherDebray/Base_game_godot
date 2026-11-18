class_name WorldItemTest
extends GdUnitTestSuite

## Tests du WorldItem (objet ramassable : taille du sprite, prompt, ramassage).
##
## On instancie la vraie scène (sprite, label et zone sont ses enfants), avec `data` fixée AVANT
## `add_child` car `_ready` la lit. L'entrée / sortie du joueur passe par les vrais signaux de
## l'Area2D (`body_entered` / `body_exited`), ce qui vérifie aussi leur câblage. Un faux `Player` (sous-classe interne) évite de charger la
## scène du joueur et permet de choisir si le ramassage réussit.

const WORLD_ITEM_SCENE_PATH := "res://scenes/items/world_item.tscn"
const DISPLAY_SIZE: float = 24.0
const WIDE_TEXTURE_SIZE := Vector2i(48, 24)
const SMALL_SQUARE_TEXTURE_SIZE := Vector2i(10, 10)
const EXPECTED_SCALE_FOR_WIDE_TEXTURE := Vector2(0.5, 0.5)
const EXPECTED_SCALE_FOR_SMALL_TEXTURE := Vector2(2.4, 2.4)
const UNTOUCHED_SCALE := Vector2.ONE
const SCALE_TOLERANCE := Vector2(0.001, 0.001)
const ACTION_INTERACT := &"interact"

## Faux joueur : pas de scène, `pickup` renvoie la valeur choisie par le test.
class PlayerSpy extends Player:
	var pickup_succeeds: bool = true
	var picked_up_data: BaseItemData = null

	func _init() -> void:
		_add_named_child(AnimatedSprite2D.new(), "AnimatedSprite2D")
		_add_named_child(CollisionShape2D.new(), "CollisionShape2D")
		_add_named_child(Node2D.new(), "Muzzle")
		_add_named_child(ObjectHolderComponent.new(), "ObjectHolderComponent")
		_add_named_child(ObjectsHolderComponent.new(), "ObjectsHolderComponent")

	func _add_named_child(child: Node, child_name: String) -> void:
		child.name = child_name
		add_child(child)

	func _ready() -> void:
		pass

	func _physics_process(_delta: float) -> void:
		pass

	func pickup(item_data: BaseItemData) -> bool:
		picked_up_data = item_data
		return pickup_succeeds


func after_test() -> void:
	Input.action_release(ACTION_INTERACT)
	# `is_action_just_pressed` compare au numéro de frame : sans nouvelle frame, l'appui du test
	# précédent serait encore vu comme « juste pressé » par le test suivant.
	await get_tree().physics_frame
	await get_tree().process_frame


func _create_texture(size: Vector2i) -> Texture2D:
	return ImageTexture.create_from_image(Image.create(size.x, size.y, false, Image.FORMAT_RGBA8))


func _create_item_data(texture: Texture2D) -> BaseItemData:
	var item_data := BaseItemData.new()
	item_data.item_texture = texture
	return item_data


## Instancie le WorldItem avec sa data et l'ajoute à l'arbre (déclenche `_ready`).
func _spawn_world_item(item_data: BaseItemData) -> WorldItem:
	var world_item: WorldItem = auto_free(load(WORLD_ITEM_SCENE_PATH).instantiate())
	world_item.display_size = DISPLAY_SIZE
	world_item.data = item_data
	add_child(world_item)
	return world_item


func _create_player() -> PlayerSpy:
	var player: PlayerSpy = auto_free(PlayerSpy.new())
	add_child(player)
	return player


# ---------- initialisation ----------

func test_ready_applies_item_texture_to_sprite() -> void:
	var texture := _create_texture(WIDE_TEXTURE_SIZE)

	var world_item := _spawn_world_item(_create_item_data(texture))

	assert_object(world_item.sprite.texture).is_same(texture)


func test_ready_scales_wide_texture_so_biggest_side_fits_display_size() -> void:
	var world_item := _spawn_world_item(_create_item_data(_create_texture(WIDE_TEXTURE_SIZE)))

	assert_vector(world_item.sprite.scale).is_equal_approx(EXPECTED_SCALE_FOR_WIDE_TEXTURE, SCALE_TOLERANCE)


func test_ready_enlarges_small_texture_up_to_display_size() -> void:
	var world_item := _spawn_world_item(_create_item_data(_create_texture(SMALL_SQUARE_TEXTURE_SIZE)))

	assert_vector(world_item.sprite.scale).is_equal_approx(EXPECTED_SCALE_FOR_SMALL_TEXTURE, SCALE_TOLERANCE)


func test_ready_without_texture_leaves_sprite_scale_untouched() -> void:
	var world_item := _spawn_world_item(_create_item_data(null))

	assert_vector(world_item.sprite.scale).is_equal(UNTOUCHED_SCALE)


func test_ready_hides_the_prompt() -> void:
	var world_item := _spawn_world_item(_create_item_data(null))

	assert_bool(world_item.prompt_label.visible).is_false()


func test_ready_disables_physics_process_until_a_player_is_in_range() -> void:
	var world_item := _spawn_world_item(_create_item_data(null))

	assert_bool(world_item.is_physics_processing()).is_false()


func test_ready_without_data_removes_the_item() -> void:
	var world_item := _spawn_world_item(null)

	assert_bool(world_item.is_queued_for_deletion()).is_true()


# ---------- portée du joueur ----------

func test_non_player_body_entering_does_not_show_the_prompt() -> void:
	var world_item := _spawn_world_item(_create_item_data(null))
	var other_body: Node2D = auto_free(Node2D.new())
	add_child(other_body)

	world_item.body_entered.emit(other_body)

	assert_bool(world_item.prompt_label.visible).is_false()


func test_player_entering_shows_the_prompt() -> void:
	var world_item := _spawn_world_item(_create_item_data(null))

	world_item.body_entered.emit(_create_player())

	assert_bool(world_item.prompt_label.visible).is_true()


func test_player_entering_enables_physics_process() -> void:
	var world_item := _spawn_world_item(_create_item_data(null))

	world_item.body_entered.emit(_create_player())

	assert_bool(world_item.is_physics_processing()).is_true()


func test_player_leaving_hides_the_prompt() -> void:
	var world_item := _spawn_world_item(_create_item_data(null))
	var player := _create_player()
	world_item.body_entered.emit(player)

	world_item.body_exited.emit(player)

	assert_bool(world_item.prompt_label.visible).is_false()


func test_player_leaving_disables_physics_process() -> void:
	var world_item := _spawn_world_item(_create_item_data(null))
	var player := _create_player()
	world_item.body_entered.emit(player)

	world_item.body_exited.emit(player)

	assert_bool(world_item.is_physics_processing()).is_false()


func test_other_body_leaving_keeps_the_prompt_for_the_player_in_range() -> void:
	var world_item := _spawn_world_item(_create_item_data(null))
	world_item.body_entered.emit(_create_player())
	var other_body: Node2D = auto_free(Node2D.new())
	add_child(other_body)

	world_item.body_exited.emit(other_body)

	assert_bool(world_item.prompt_label.visible).is_true()


# ---------- ramassage ----------

# `_physics_process` est appelé à la main (déterministe) : `is_action_just_pressed` dépend du numéro
# de frame, d'où l'attente de frames dans `after_test`.
func test_interact_gives_item_data_to_the_player() -> void:
	var item_data := _create_item_data(null)
	var world_item := _spawn_world_item(item_data)
	var player := _create_player()
	world_item.body_entered.emit(player)
	Input.action_press(ACTION_INTERACT)

	world_item._physics_process(0.0)

	assert_object(player.picked_up_data).is_same(item_data)


func test_interact_removes_the_item_when_pickup_succeeds() -> void:
	var world_item := _spawn_world_item(_create_item_data(null))
	world_item.body_entered.emit(_create_player())
	Input.action_press(ACTION_INTERACT)

	world_item._physics_process(0.0)

	assert_bool(world_item.is_queued_for_deletion()).is_true()


func test_interact_keeps_the_item_on_the_ground_when_inventory_is_full() -> void:
	var world_item := _spawn_world_item(_create_item_data(null))
	var player := _create_player()
	player.pickup_succeeds = false
	world_item.body_entered.emit(player)
	Input.action_press(ACTION_INTERACT)

	world_item._physics_process(0.0)

	assert_object(player.picked_up_data).is_not_null()
	assert_bool(world_item.is_queued_for_deletion()).is_false()


func test_no_interact_input_does_not_pick_anything_up() -> void:
	var world_item := _spawn_world_item(_create_item_data(null))
	var player := _create_player()
	world_item.body_entered.emit(player)

	world_item._physics_process(0.0)

	assert_object(player.picked_up_data).is_null()
