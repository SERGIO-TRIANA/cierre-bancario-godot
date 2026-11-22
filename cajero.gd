extends CharacterBody2D

enum Estado { EN_PUESTO, TOMANDO_AGUA, PERSIGUIENDO, VOLVIENDO }

@export var velocidad_persecucion: float = 60.0
@export var velocidad_regreso: float = 50.0
@export var tiempo_en_puesto_min: float = 6.0
@export var tiempo_en_puesto_max: float = 12.0
@export var tiempo_persecucion_min: float = 8.0
@export var tiempo_persecucion_max: float = 14.0
# Distancia máxima para detectar que el Coordinador está en la Sala 6
@export var rango_sala: float = 280.0

var estado_actual: Estado = Estado.EN_PUESTO
var posicion_inicial: Vector2 = Vector2.ZERO

# Apoyo para rodear mostradores o sillas al perseguir y al volver
var tiempo_evasion: float = 0.0
var direccion_evasion: Vector2 = Vector2.ZERO

# Preguntas de trivia enfocadas en procesos de Cajeros / Taquilla
var dudas_cajero: Array[Dictionary] = [
	{
		"pregunta": "¡Jefe, espere! Me sobra efectivo en el arqueo de caja al cierre. ¿Qué hago?",
		"opciones": ["Guardarlo para el otro día", "Reportar y registrar el sobrante en el sistema", "Repartirlo entre las demás cajas"],
		"respuesta_correcta": 1
	},
	{
		"pregunta": "Coordinador, recibí un billete sospechoso de ser falso en taquilla. ¿Cuál es el protocolo?",
		"opciones": ["Devolverlo sin decir nada", "Retenerlo, diligenciar acta de incautación y escalar", "Pasárselo al siguiente cliente"],
		"respuesta_correcta": 1
	},
	{
		"pregunta": "Un cliente quiere retirar una suma alta en efectivo sin documento original. ¿Procedo?",
		"opciones": ["No, sin documento original válido no se entrega efectivo", "Sí, si dicta su número de cédula", "Sí, si muestra una foto del documento"],
		"respuesta_correcta": 0
	},
	{
		"pregunta": "Mi caja superó el tope máximo permitido de efectivo en ventanilla. ¿Qué debo solicitar?",
		"opciones": ["Dejar el dinero debajo del teclado", "Un traslado o descargue parcial hacia bóveda", "Cerrar la taquilla sin cuadrar"],
		"respuesta_correcta": 1
	},
	{
		"pregunta": "Al terminar el turno y antes de cerrar la taquilla, ¿qué debe quedar en cero o cuadrado?",
		"opciones": ["El saldo del efectivo físico vs. el arqueo del sistema", "Solo los billetes de alta denominación", "Únicamente las monedas"],
		"respuesta_correcta": 0
	},
	{
		"pregunta": "Un cliente pide cambiar un cheque de gerencia que presenta tachones en el valor. ¿Lo pago?",
		"opciones": ["Sí, si el cliente firma encima", "Solo si es cliente conocido", "No, un título valor con enmendaduras debe rechazarse"],
		"respuesta_correcta": 2
	}
]

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var timer_estado: Timer = $TimerEstado
@onready var timer_accion: Timer = $TimerAccion
@onready var icono_duda: Label = $IconoDuda
@onready var rotador_vision: Node2D = $RotadorVision
@onready var zona_captura: Area2D = $RotadorVision/ZonaCaptura
@onready var jugador: CharacterBody2D = get_node_or_null("/root/NivelBanco/Coordinador")
@onready var menu_trivia: Control = get_node_or_null("/root/NivelBanco/CanvasLayer/MenuTrivia")

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	posicion_inicial = global_position
	
	timer_estado.one_shot = true
	timer_accion.one_shot = true
	
	timer_estado.timeout.connect(_on_timer_estado_timeout)
	timer_accion.timeout.connect(_on_timer_accion_timeout)
	anim_player.animation_finished.connect(_on_animacion_terminada)
	zona_captura.body_entered.connect(_on_zona_captura_body_entered)
	
	entrar_en_puesto()

func _physics_process(delta: float) -> void:
	match estado_actual:
		Estado.EN_PUESTO, Estado.TOMANDO_AGUA:
			velocity = Vector2.ZERO
			
		Estado.PERSIGUIENDO:
			perseguir_coordinador(delta)
			
		Estado.VOLVIENDO:
			mover_hacia_puesto(delta)

# --- TRANSICIONES DE ESTADO ---

func entrar_en_puesto() -> void:
	estado_actual = Estado.EN_PUESTO
	velocity = Vector2.ZERO
	icono_duda.hide()
	rotador_vision.hide()
	anim_player.play("idle_down")
	
	timer_estado.start(randf_range(tiempo_en_puesto_min, tiempo_en_puesto_max))
	timer_accion.start(randf_range(2.5, 5.5))

func empezar_a_perseguir() -> void:
	estado_actual = Estado.PERSIGUIENDO
	icono_duda.show()
	rotador_vision.show()
	tiempo_evasion = 0.0
	timer_accion.stop()
	
	# Tiempo que durará siguiendo al Coordinador antes de desistir y volver al puesto
	timer_estado.start(randf_range(tiempo_persecucion_min, tiempo_persecucion_max))

func empezar_a_volver() -> void:
	estado_actual = Estado.VOLVIENDO
	icono_duda.hide()
	rotador_vision.hide()
	timer_estado.stop()
	timer_accion.stop()
	tiempo_evasion = 0.0

# --- LÓGICA DE PERSECUCIÓN Y REGRESO ---

func perseguir_coordinador(delta: float) -> void:
	if jugador == null:
		empezar_a_volver()
		return
	
	# Si el Coordinador logró salir de la Sala 6, el cajero deja de perseguirlo y vuelve a su puesto
	if global_position.distance_to(jugador.global_position) > rango_sala + 60.0:
		empezar_a_volver()
		return
	
	var dir: Vector2 = global_position.direction_to(jugador.global_position)
	mover_con_evasion(dir, velocidad_persecucion, delta)
	actualizar_rotacion_cono(dir)

func mover_hacia_puesto(delta: float) -> void:
	var distancia: float = global_position.distance_to(posicion_inicial)
	
	if distancia < 4.0:
		global_position = posicion_inicial
		entrar_en_puesto()
		return
	
	var dir: Vector2 = global_position.direction_to(posicion_inicial)
	mover_con_evasion(dir, velocidad_regreso, delta)

func mover_con_evasion(dir_objetivo: Vector2, velocidad_actual: float, delta: float) -> void:
	var dir_final: Vector2 = dir_objetivo
	
	# Si chocó con un mostrador o pared, rodea brevemente hacia un lado
	if tiempo_evasion > 0.0:
		tiempo_evasion -= delta
		dir_final = direccion_evasion
	
	velocity = dir_final * velocidad_actual
	move_and_slide()
	
	if get_slide_collision_count() > 0 and tiempo_evasion <= 0.0:
		var lado: float = 1.0 if randf() > 0.5 else -1.0
		direccion_evasion = dir_objetivo.orthogonal() * lado
		tiempo_evasion = 0.4
		
	actualizar_animacion_caminar(dir_final)

func actualizar_rotacion_cono(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		rotador_vision.rotation_degrees = 0.0 if dir.x > 0.0 else 180.0
	else:
		rotador_vision.rotation_degrees = 90.0 if dir.y > 0.0 else 270.0

func actualizar_animacion_caminar(dir: Vector2) -> void:
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
		# Solo se levanta a perseguir si el Coordinador ya entró a la Sala 6
		if jugador != null and global_position.distance_to(jugador.global_position) <= rango_sala:
			empezar_a_perseguir()
		else:
			# Si el jugador está en otra sala, vuelve a revisar en 2 segundos
			timer_estado.start(2.0)
	elif estado_actual == Estado.PERSIGUIENDO:
		empezar_a_volver()

func _on_timer_accion_timeout() -> void:
	if estado_actual == Estado.EN_PUESTO:
		if randf() < 0.5:
			estado_actual = Estado.TOMANDO_AGUA
			anim_player.play("drinking")
		else:
			timer_accion.start(randf_range(2.5, 5.5))

func _on_animacion_terminada(anim_name: StringName) -> void:
	if anim_name == "drinking" and estado_actual == Estado.TOMANDO_AGUA:
		estado_actual = Estado.EN_PUESTO
		anim_player.play("idle_down")
		timer_accion.start(randf_range(3.0, 6.0))

func _on_zona_captura_body_entered(body: Node2D) -> void:
	if body.name == "Coordinador" and estado_actual == Estado.PERSIGUIENDO:
		empezar_a_volver()
		get_tree().paused = true
		
		var duda_elegida: Dictionary = dudas_cajero.pick_random()
		if menu_trivia != null:
			menu_trivia.mostrar_pregunta(duda_elegida)
		else:
			print("ERROR: No se encontró MenuTrivia en /root/NivelBanco/CanvasLayer/MenuTrivia")
			get_tree().paused = false
