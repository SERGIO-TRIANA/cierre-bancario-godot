extends CharacterBody2D

enum Estado { EN_PUESTO, TOMANDO_AGUA, DEAMBULANDO, VOLVIENDO }

@export var velocidad: float = 45.0
@export var tiempo_en_puesto_min: float = 8.0
@export var tiempo_en_puesto_max: float = 15.0
# Tiempo duplicado para que alcance a recorrer gran parte de la sala de asesoría
@export var tiempo_deambulando_min: float = 12.0
@export var tiempo_deambulando_max: float = 24.0

var estado_actual: Estado = Estado.EN_PUESTO
var posicion_inicial: Vector2 = Vector2.ZERO
var direccion_actual: Vector2 = Vector2.ZERO

# Apoyo para rodear escritorios al volver al puesto
var tiempo_evasion: float = 0.0
var direccion_evasion: Vector2 = Vector2.ZERO

# Banco de dudas propias de procesos de un Asesor Bancario
var dudas_asesor: Array[Dictionary] = [
	{
		"pregunta": "¡Jefe, una duda! ¿Qué debo exigir siempre antes de abrir una cuenta de ahorros?",
		"opciones": ["Solo el número de celular", "Cédula original y validación biométrica", "Una foto del documento en WhatsApp"],
		"respuesta_correcta": 1
	},
	{
		"pregunta": "Coordinador, un cliente trae efectivo inusual y no justifica su origen (SARLAFT). ¿Qué hago?",
		"opciones": ["Reportar la operación inusual y escalar", "Recibirlo rápido para cerrar temprano", "Dividirlo en varias consignaciones pequeñas"],
		"respuesta_correcta": 0
	},
	{
		"pregunta": "Un familiar pide los extractos bancarios de un titular que no vino. ¿Se los entrego?",
		"opciones": ["Sí, si muestra el mismo apellido", "Solo si promete entregarlos hoy", "No, lo prohíbe la reserva bancaria y Habeas Data"],
		"respuesta_correcta": 2
	},
	{
		"pregunta": "Un cliente quiere aumentar el cupo de su tarjeta justo antes del cierre. ¿Cuál es el proceso?",
		"opciones": ["Aprobarlo directo desde el escritorio", "Entregarle efectivo de caja mientras tanto", "Radicar la solicitud para estudio de crédito"],
		"respuesta_correcta": 2
	},
	{
		"pregunta": "Un cliente olvidó su cédula en mi escritorio de asesoría. ¿Qué protocolo aplico?",
		"opciones": ["Registrarla y dejarla en custodia de caja/bóveda", "Dejarla visible sobre el monitor", "Guardarla en mi bolsillo hasta mañana"],
		"respuesta_correcta": 0
	},
	{
		"pregunta": "Me reportan la pérdida de una tarjeta débito en asesoría. ¿Qué hago primero?",
		"opciones": ["Pedirle que vuelva al día siguiente", "Bloquear de inmediato el plástico en el sistema", "Cambiarle el correo electrónico"],
		"respuesta_correcta": 1
	},
	{
		"pregunta": "Al entregar una tarjeta nueva al cliente, ¿qué paso nunca debe hacer el asesor?",
		"opciones": ["Digitar o conocer la clave personal del cliente", "Validar la identidad del titular", "Activar el plástico en el sistema"],
		"respuesta_correcta": 0
	},
	{
		"pregunta": "Un cliente quiere desembolsar un crédito de libre inversión hoy, pero no ha firmado el pagaré.",
		"opciones": ["Desembolsar y que firme la otra semana", "Firmarlo por él con autorización verbal", "No desembolsar hasta tener las garantías firmadas"],
		"respuesta_correcta": 2
	},
	{
		"pregunta": "Un cliente pregunta si puede cancelar su CDT antes de la fecha de vencimiento.",
		"opciones": ["Sí, retirando en cualquier cajero", "No, un CDT no es redimible antes del plazo pactado", "Sí, pero solo si llama al gerente"],
		"respuesta_correcta": 1
	},
	{
		"pregunta": "Antes de levantarme del puesto o al cierre de oficina, ¿qué exige la política de escritorio limpio?",
		"opciones": ["Dejar las carpetas abiertas para mañana", "Bloquear la sesión del PC y guardar documentos sensibles", "Apagar solo el monitor y dejar la sesión abierta"],
		"respuesta_correcta": 1
	}
]

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var timer_estado: Timer = $TimerEstado
@onready var timer_accion: Timer = $TimerAccion
@onready var icono_duda: Label = $IconoDuda
@onready var rotador_vision: Node2D = $RotadorVision
@onready var zona_pregunta: Area2D = $RotadorVision/ZonaPregunta
@onready var menu_trivia: Control = get_node_or_null("/root/NivelBanco/CanvasLayer/MenuTrivia")

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	posicion_inicial = global_position
	
	timer_estado.one_shot = true
	timer_accion.one_shot = true
	
	timer_estado.timeout.connect(_on_timer_estado_timeout)
	timer_accion.timeout.connect(_on_timer_accion_timeout)
	anim_player.animation_finished.connect(_on_animacion_terminada)
	zona_pregunta.body_entered.connect(_on_zona_pregunta_body_entered)
	
	entrar_en_puesto()

func _physics_process(delta: float) -> void:
	match estado_actual:
		Estado.EN_PUESTO, Estado.TOMANDO_AGUA:
			velocity = Vector2.ZERO
			
		Estado.DEAMBULANDO:
			velocity = direccion_actual * velocidad
			move_and_slide()
			
			if get_slide_collision_count() > 0:
				elegir_direccion_aleatoria()
				
			actualizar_animacion_caminar(direccion_actual)
			
		Estado.VOLVIENDO:
			mover_hacia_puesto(delta)

# --- TRANSICIONES DE ESTADO ---

func entrar_en_puesto() -> void:
	estado_actual = Estado.EN_PUESTO
	velocity = Vector2.ZERO
	icono_duda.hide()
	rotador_vision.hide() # Oculta el cono rojizo mientras trabaja normal en su puesto
	anim_player.play("Idle_down")
	
	timer_estado.start(randf_range(tiempo_en_puesto_min, tiempo_en_puesto_max))
	timer_accion.start(randf_range(2.5, 5.0))

func empezar_a_deambular() -> void:
	estado_actual = Estado.DEAMBULANDO
	icono_duda.show()
	rotador_vision.show() # Muestra el cono rojizo al salir con dudas
	elegir_direccion_aleatoria()
	timer_estado.start(randf_range(tiempo_deambulando_min, tiempo_deambulando_max))

func empezar_a_volver() -> void:
	estado_actual = Estado.VOLVIENDO
	icono_duda.hide()
	rotador_vision.hide() # Apaga el cono rojizo mientras regresa a su escritorio
	timer_estado.stop()
	timer_accion.stop()
	tiempo_evasion = 0.0

# --- LÓGICA DE MOVIMIENTO Y VISIÓN ---

func elegir_direccion_aleatoria() -> void:
	var direcciones: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var nueva_dir: Vector2 = direcciones.pick_random()
	while nueva_dir == direccion_actual:
		nueva_dir = direcciones.pick_random()
		
	direccion_actual = nueva_dir
	actualizar_rotacion_cono(direccion_actual)
	timer_accion.start(randf_range(1.5, 3.0))

func actualizar_rotacion_cono(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		rotador_vision.rotation_degrees = 0.0 if dir.x > 0.0 else 180.0
	else:
		rotador_vision.rotation_degrees = 90.0 if dir.y > 0.0 else 270.0

func mover_hacia_puesto(delta: float) -> void:
	var distancia: float = global_position.distance_to(posicion_inicial)
	
	if distancia < 4.0:
		global_position = posicion_inicial
		entrar_en_puesto()
		return
	
	var dir: Vector2 = global_position.direction_to(posicion_inicial)
	
	if tiempo_evasion > 0.0:
		tiempo_evasion -= delta
		dir = direccion_evasion
	
	velocity = dir * velocidad
	move_and_slide()
	
	if get_slide_collision_count() > 0 and tiempo_evasion <= 0.0:
		var lado: float = 1.0 if randf() > 0.5 else -1.0
		direccion_evasion = dir.orthogonal() * lado
		tiempo_evasion = 0.45
		
	actualizar_animacion_caminar(dir)

func actualizar_animacion_caminar(dir: Vector2) -> void:
	# Revisa que estos nombres coincidan en mayúsculas/minúsculas con tu AnimationPlayer
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0.0:
			anim_player.play("walk_right")
		else:
			anim_player.play("walk_left")
	else:
		if dir.y > 0.0:
			anim_player.play("walk_down")
		else:
			anim_player.play("walk_up")

# --- SEÑALES ---

func _on_timer_estado_timeout() -> void:
	if estado_actual == Estado.EN_PUESTO or estado_actual == Estado.TOMANDO_AGUA:
		empezar_a_deambular()
	elif estado_actual == Estado.DEAMBULANDO:
		empezar_a_volver()

func _on_timer_accion_timeout() -> void:
	if estado_actual == Estado.EN_PUESTO:
		if randf() < 0.5:
			estado_actual = Estado.TOMANDO_AGUA
			anim_player.play("Drinking")
		else:
			timer_accion.start(randf_range(2.5, 5.0))
	elif estado_actual == Estado.DEAMBULANDO:
		elegir_direccion_aleatoria()

func _on_animacion_terminada(anim_name: StringName) -> void:
	if anim_name == "Drinking" and estado_actual == Estado.TOMANDO_AGUA:
		estado_actual = Estado.EN_PUESTO
		anim_player.play("Idle_down")
		timer_accion.start(randf_range(3.0, 6.0))

func _on_zona_pregunta_body_entered(body: Node2D) -> void:
	if body.name == "Coordinador" and estado_actual == Estado.DEAMBULANDO:
		empezar_a_volver()
		get_tree().paused = true
		
		var duda_elegida: Dictionary = dudas_asesor.pick_random()
		if menu_trivia != null:
			menu_trivia.mostrar_pregunta(duda_elegida)
		else:
			print("ERROR: No se encontró MenuTrivia en /root/NivelBanco/CanvasLayer/MenuTrivia")
			get_tree().paused = false
