class_name player
extends actor

enum ORIENTATION {
	BOW,
	PORT,
	STARBOARD,
	STERN
}
@export var ship_pic: Sprite2D
@export var graphics: Array[CompressedTexture2D] = []

@export var ship_shows : ORIENTATION = ORIENTATION.STARBOARD
var ship_shows_flip : Array[bool] = [false, true, false, true]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_ship_graphic():
	match ship_shows:
		ORIENTATION.BOW:
			pass
		ORIENTATION.PORT:
			pass
		ORIENTATION.STARBOARD:
			pass
		ORIENTATION.STERN:
			pass
