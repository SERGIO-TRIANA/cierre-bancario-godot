extends CharacterBody2D

@export var speed: float = 120.0
var ultima_direccion: String = "down"
@onready var anim_player = $AnimationPlayer

func _physics_process(delta: float) -> void:
	var direction: Vector2 = Vector2.ZERO

	# Capturar input de las teclas direccionales o WASD
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")

	# Normalizar para evitar que camine más rápido en diagonal
	if direction != Vector2.ZERO:
		direction = direction.normalized()

	# Aplicar velocidad y usar la función de físicas de Godot 4
	velocity = direction * speed
	move_and_slide()

	actualizar_animacion(direction)

func actualizar_animacion(dir: Vector2) -> void:
	# 1. Si el jugador se está moviendo, actualizamos animación y guardamos la dirección
	if dir != Vector2.ZERO:
		if dir.x > 0:
			anim_player.play("walk_right")
			ultima_direccion = "right"
		elif dir.x < 0:
			anim_player.play("walk_left")
			ultima_direccion = "left"
		elif dir.y > 0:
			anim_player.play("walk_down")
			ultima_direccion = "down"
		elif dir.y < 0:
			anim_player.play("walk_up")
			ultima_direccion = "up"
			
	# 2. Si el jugador está quieto (dir == Vector2.ZERO), reproducimos el Idle correspondiente
	else:
		if ultima_direccion == "right":
			anim_player.play("idle_right")
		elif ultima_direccion == "left":
			anim_player.play("idle_left")
		elif ultima_direccion == "down":
			anim_player.play("idle_down")
		elif ultima_direccion == "up":
			anim_player.play("idle_up")





func _on_puerta_oficina_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_puerta_espera_3_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
