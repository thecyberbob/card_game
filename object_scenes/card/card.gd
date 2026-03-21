class_name SingleCard
extends Node2D

@export var title: String
@export var rule: String

@export var functional_rule : Dictionary

@export var card_text: RichTextLabel

@export var target_pos: Vector2

@export var move_card: bool = false

@onready var click_area: Area2D = $ClickArea

signal card_clicked(card)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	click_area.input_event.connect(_on_click_area_input_event)
	print("Connected click area")
	
	redraw_card()

func set_values(card_title: String, rule_text: String, actual_rule: Dictionary):
	title = card_title
	rule = rule_text
	functional_rule = actual_rule

func redraw_card():
	card_text.text = "[i][u]" + title + "[/u][/i][br]" + rule
	
func _process(_delta: float) -> void:
	# Not sure this should be here since it deals with the movement of the card not the card itself.
	if move_card:
		#print("Moving!")
		#if self.position != target_pos:
		if !self.position.is_equal_approx(target_pos):
			self.position = lerp(self.position, target_pos, 0.1)
		else:
			move_card = false

func _on_click_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("card_clicked", self)
