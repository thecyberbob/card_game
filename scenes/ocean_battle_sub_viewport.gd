extends SubViewport


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().root.size_changed.connect(on_viewport_size_changed)

func on_viewport_size_changed():
	self.size = get_tree().root.size
