extends CanvasLayer

class_name escena_intermedia_menus

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Asegurar que la animación se reproduzca
	animated_sprite_2d.play("default")
	
