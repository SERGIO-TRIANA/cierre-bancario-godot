extends CharacterBody2D

@export var velocidad: float = 40.0
var direccion_actual: Vector2 = Vector2.ZERO

@onready var animacion = $AnimationPlayer
@onready var timer_cambio = $Timer
@onready var rotador_vision = $RotadorVision # <--- Referencia a nuestro nuevo nodo
@onready var menu_trivia = get_node("/root/NivelBanco/CanvasLayer/MenuTrivia")

var base_de_preguntas = [
	{
		"pregunta": "¡Oiga, joven! ¿A qué hora se cierran las puertas del banco al público?",
		"opciones": ["A las 3:00 PM", "A las 4:00 PM", "Cuando salga el último"],
		"respuesta_correcta": 1 
	},
	{
		"pregunta": "Una dudita rápida... ¿Qué documento es obligatorio para retirar efectivo en ventanilla?",
		"opciones": ["Fotocopia de la cédula", "Cédula original", "Licencia de conducir"],
		"respuesta_correcta": 1 
	},
	{
		"pregunta": "¿Ustedes me pueden recibir el pago de la tarjeta de crédito de OTRO banco aquí?",
		"opciones": ["Sí, claro", "No, debe ir a ese banco", "Solo si trae cheque"],
		"respuesta_correcta": 1 
	}
]

func _ready() -> void:
	timer_cambio.timeout.connect(_on_timer_timeout)
	elegir_nueva_direccion()

func _physics_process(_delta: float) -> void:
	velocity = direccion_actual * velocidad
	move_and_slide()
	if is_on_wall():
		elegir_nueva_direccion()
	actualizar_animacion()

func elegir_nueva_direccion() -> void:
	var direcciones = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var nueva_dir = direcciones.pick_random()
	while nueva_dir == direccion_actual:
		nueva_dir = direcciones.pick_random()
	direccion_actual = nueva_dir
	timer_cambio.start()
	
	# --- NUEVO: ROTAR EL CONO DE VISIÓN ---
	actualizar_rotacion_cono()

func actualizar_rotacion_cono() -> void:
	# Rotamos el nodo 'RotadorVision' dependiendo de la dirección
	# Asumimos que dibujaste el cono original mirando hacia la DERECHA (0 grados)
	if direccion_actual == Vector2.RIGHT:
		rotador_vision.rotation_degrees = 0
	elif direccion_actual == Vector2.DOWN:
		rotador_vision.rotation_degrees = 90
	elif direccion_actual == Vector2.LEFT:
		rotador_vision.rotation_degrees = 180
	elif direccion_actual == Vector2.UP:
		rotador_vision.rotation_degrees = 270

func actualizar_animacion() -> void:
	if direccion_actual == Vector2.RIGHT:
		animacion.play("walk_right")
	elif direccion_actual == Vector2.LEFT:
		animacion.play("walk_left")
	elif direccion_actual == Vector2.DOWN:
		animacion.play("walk_down")
	elif direccion_actual == Vector2.UP:
		animacion.play("walk_up")

func _on_timer_timeout() -> void:
	elegir_nueva_direccion()

func _on_zona_captura_body_entered(body: Node2D) -> void:
	if body.name == "Coordinador":
		get_tree().paused = true

		# Elegimos una pregunta aleatoria
		var pregunta_elegida = base_de_preguntas.pick_random()

		# Llamamos a la función del menú y le pasamos la pregunta
		if menu_trivia != null:
			menu_trivia.mostrar_pregunta(pregunta_elegida)
		else:
			print("ERROR: No se encontró el nodo MenuTrivia en la ruta especificada.")
