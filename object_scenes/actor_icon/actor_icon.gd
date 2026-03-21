class_name ActorIcon
extends Control

var my_actor : actor = null

@onready var name_label : Label = $NameLabel
@onready var prog_bar : ProgressBar = $LifeBar

func set_life(per_life_left: float):
	prog_bar.value = per_life_left

func set_icon_name(actor_name: String):
	name_label.text = actor_name

func set_actor(the_actor: actor):
	my_actor = the_actor
	
func _process(delta: float) -> void:
	if my_actor != null:
		set_life(my_actor.health)
