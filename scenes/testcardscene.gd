extends Node2D

@export var card_scene : PackedScene
@export var card_plank : Control
@export var actor_icon_scene : PackedScene
@export var dice_scene : Dice

var cards : Array[SingleCard] = []
var card_middle_gap : float = 50
var card_spacing : float = 180

var actors : Array[actor] = []

var whos_turn : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().root.size_changed.connect(on_viewport_size_changed)
	
	var num_cards : int = 5
	
	var pos_array = make_targets(num_cards)
	
	var start_pos : Vector2 = make_start_pos()
	
	add_actor(MyData.my_name)
	add_actor("Steve")
	
	for i in range(0, num_cards):
		create_card(start_pos, pos_array[i])
	

func on_viewport_size_changed():
	move_cards()

func move_cards():
	var pos_array = make_targets(cards.size())
	var i_int = 0
	for i in cards:
		i.target_pos = pos_array[i_int]
		i_int += 1
		i.move_card = true

func add_actor(actor_name: String):
	var a = actor.new()
	a.name = actor_name
	actors.append(a)
	
	if actor_name == MyData.my_name:
		MyData.my_turn_place = actors.size() - 1
	
	var actor_icon : ActorIcon = actor_icon_scene.instantiate()
	
	$"CanvasLayer/Actor Icons/Actor Icon Container".add_child(actor_icon)
	actor_icon.set_life(100)
	actor_icon.set_icon_name(actor_name)
	actor_icon.set_actor(a)

func deal_cards(delta: float):
	var wait_to_deal = 1
	var wait_counter = 0
	
	for c in cards:
		if c:
			c.move_card = true
			while wait_counter < wait_to_deal:
				wait_counter += delta
				await get_tree().process_frame

func create_card(pos: Vector2, target_pos: Vector2):
	var c : SingleCard = card_scene.instantiate()
	
	var card_rule: Dictionary = {"action on": "health", "max value": "10", "min value": "0", "action": "add"}
	
	c.set_values("BOOM!", "Fire available guns towards target", card_rule)
	c.target_pos = target_pos
	card_plank.add_child(c)
	cards.append(c)
	c.position = pos
	c.card_clicked.connect(_on_card_clicked)
	
	

func _on_card_clicked(card):
	if whos_turn == MyData.my_turn_place:
		print("Card clicked!!: ", card)
		var c : SingleCard = card
		
		remove_card(c)
		
		var target : int = 1
		
		match c.functional_rule["action on"]:
			"health":
				actors[1].health -= int(c.functional_rule["max value"])
				print("health: ", actors[1].health)
				dice_scene.shoot_dice()

func remove_card(c : SingleCard):
	var card_array_point : int = 0
	for i in cards:
		if i == c:
			cards.remove_at(card_array_point)
		else:
			card_array_point += 1
		
	c.queue_free()
	
	move_cards()

func make_start_pos() -> Vector2:
	var mid_point = card_plank.size.x / 2
	var start_height = card_plank.size.y * 2
	return Vector2(mid_point, start_height)

func make_targets(num_cards: int) -> Array[Vector2]:
	var result_points: Array[Vector2] = []
	print("Card size: ", card_plank.size)
	var mid_point = card_plank.size.x / 2
	
	var mid_height = card_plank.size.y / 2
	
	var placement_width = (num_cards - 1) * card_spacing
	
	var left_most = mid_point - (placement_width / 2)
	
	for i in range(0, num_cards):
		result_points.append(Vector2(left_most + (card_spacing * i), mid_height))
	
	return result_points

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	deal_cards(delta)


func _on_end_turn_pressed() -> void:
	whos_turn += 1
	if whos_turn >= actors.size():
		whos_turn = 0
