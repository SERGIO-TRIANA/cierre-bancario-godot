extends CharacterBody2D

enum Estado { EN_PUESTO, TOMANDO_CAFE, RONDA_NORMAL, RONDA_PREGUNTA, VOLVIENDO }

@export var velocidad: float = 42.0
@export var tiempo_en_puesto_min: float = 6.0
@export var tiempo_en_puesto_max: float = 12.0
@export var tiempo_ronda_normal_min: float = 5.0
@export var tiempo_ronda_normal_max: float = 10.0
@export var tiempo_pregunta_min: float = 10.0
@export var tiempo_pregunta_max: float = 16.0
@export_range(0.0, 1.0) var probabilidad_pregunta: float = 0.85

var estado_actual: Estado = Estado.EN_PUESTO
var posicion_inicial: Vector2 = Vector2.ZERO
var direccion_actual: Vector2 = Vector2.ZERO

# Apoyo para rodear mesas o sillas al volver a su puesto
var tiempo_evasion: float = 0.0
var direccion_evasion: Vector2 = Vector2.ZERO

# Banco de preguntas propias de la Aseadora (aseo, café, gaseosas e insumos)
var dudas_aseadora: Array[Dictionary] = [
	{
		"pregunta": "¡Jefe! Ya trapeé el pasillo hacia asesoría. ¿Qué debo poner para evitar caídas?",
		"opciones": ["Una silla volteada", "Señalización de piso húmedo visible", "Nada, se seca rápido"],
		"respuesta_correcta": 1
	},
	{
		"pregunta": "Coordinador, antes de cerrar la sucursal, ¿cómo debe quedar la greca de café en la cocina?",
		"opciones": ["Apagada, desconectada y limpia", "Encendida para mañana temprano", "Solo con el agua a la mitad"],
		"respuesta_correcta": 0
	},
	{
		"pregunta": "Se acabaron las gaseosas y el café para clientes y empleados. ¿Cómo pido reposición?",
		"opciones": ["Sacando plata de una taquilla", "Registrando el faltante en la solicitud de insumos", "Dejando un papel pegado en la nevera"],
		"respuesta_correcta": 1
	},
	{
		"pregunta": "Encontré papeles con datos de clientes en la papelera de una oficina. ¿Dónde van?",
		"opciones": ["En la basura común de la cocina", "En reciclaje abierto sin romper", "En destrucción segura / trituradora por confidencialidad"],
		"respuesta_correcta": 2
	},
	{
		"pregunta": "¿Dónde debo guardar el cloro y los implementos químicos de aseo al terminar mi ronda?",
		"opciones": ["En el cuarto de aseo rotulados y lejos de alimentos", "Al lado de las gaseosas en la nevera", "Debajo del escritorio de asesoría"],
		"respuesta_correcta": 0
	},
	{
		"pregunta": "Hay residuos orgánicos del almuerzo y botellas plásticas de gaseosa. ¿Cómo los separo?",
		"opciones": ["Todo en una sola bolsa negra", "Aprovechables limpios aparte de residuos orgánicos", "Dejarlos sobre el mesón hasta mañana"],
		"respuesta_correcta": 1
	},
	{
		"pregunta": "Al limpiar los escritorios y teclados de la sucursal, ¿qué precaución debo tener?",
		"opciones": ["Echar agua abundante directo al teclado", "Usar paño ligeramente humedecido sin mojar equipos", "Apagar los servidores de la bóveda"],
		"respuesta_correcta": 1
	},
	{
		"pregunta": "Quedaron pocillos sucios y vasos en la cafetería al cierre. ¿Cuál es el orden correcto?",
		"opciones": ["Dejarlos en el lavaplatos hasta el lunes", "Lavarlos, secarlos y dejar la cocina ordenada", "Guardarlos sucios dentro de una gaveta"],
		"respuesta_correcta": 1
	}
]

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var timer_estado: Timer = $TimerEstado
@onready var timer_accion: Timer = $TimerAccion
@onready var icono_duda: Label = $IconoDuda
@onready var zona_pregunta: Area2D = $ZonaPregunta
@onready var colision_pregunta: CollisionShape2D = $ZonaPregunta/CollisionShape2D
@onready var dibujo_circulo: Polygon2D = $ZonaPregunta/DibujoCirculo
@onready var menu_trivia: Control = get_node_or_null("/root/NivelBanco/CanvasLayer/MenuTrivia")

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	posicion_inicial = global_position
	
	# Dibuja automáticamente el círculo visual con el radio exacto del CircleShape2D
	if colision_pregunta.shape is CircleShape2D:
		generar_circulo_visual(colision_pregunta.shape.radius)
	
	timer_estado.one_shot = true
	timer_accion.one_shot = true
	
	timer_estado.timeout.connect(_on_timer_estado_timeout)
	timer_accion.timeout.connect(_on_timer_accion_timeout)
	anim_player.animation_finished.connect(_on_animacion_terminada)
	zona_pregunta.body_entered.connect(_on_zona_pregunta_body_entered)
	
	entrar_en_puesto()

func _physics_process(delta: float) -> void:
	match estado_actual:
		Estado.EN_PUESTO, Estado.TOMANDO_CAFE:
			velocity = Vector2.ZERO
			
		Estado.RONDA_NORMAL, Estado.RONDA_PREGUNTA:
			# Deambula por la sala sin perseguir al Coordinador
			velocity = direccion_actual * velocidad
			move_and_slide()
			
			if get_slide_collision_count() > 0:
				elegir_direccion_aleatoria()
				
			actualizar_animacion_caminar(direccion_actual)
			
		Estado.VOLVIENDO:
			mover_hacia_puesto(delta)

# --- CÍRCULO DE INTERACCIÓN ---

func generar_circulo_visual(radio: float, segmentos: int = 32) -> void:
	var puntos: PackedVector2Array = PackedVector2Array()
	for i in range(segmentos):
		var angulo: float = (TAU * i) / float(segmentos)
		puntos.append(Vector2(cos(angulo), sin(angulo)) * radio)
	dibujo_circulo.polygon = puntos

func activar_circulo_pregunta(activo: bool) -> void:
	icono_duda.visible = activo
	dibujo_circulo.visible = activo
	colision_pregunta.set_deferred("disabled", not activo)

# --- TRANSICIONES DE ESTADO ---

func entrar_en_puesto() -> void:
	estado_actual = Estado.EN_PUESTO
	velocity = Vector2.ZERO
	activar_circulo_pregunta(false)
	anim_player.play("Idle")
	
	timer_estado.start(randf_range(tiempo_en_puesto_min, tiempo_en_puesto_max))
	timer_accion.start(randf_range(2.5, 5.5))

func empezar_ronda_normal() -> void:
	estado_actual = Estado.RONDA_NORMAL
	activar_circulo_pregunta(false)
	elegir_direccion_aleatoria()
	timer_estado.start(randf_range(tiempo_ronda_normal_min, tiempo_ronda_normal_max))

func activar_modo_pregunta() -> void:
	estado_actual = Estado.RONDA_PREGUNTA
	activar_circulo_pregunta(true)
	timer_estado.start(randf_range(tiempo_pregunta_min, tiempo_pregunta_max))

func empezar_a_volver() -> void:
	estado_actual = Estado.VOLVIENDO
	activar_circulo_pregunta(false)
	timer_estado.stop()
	timer_accion.stop()
	tiempo_evasion = 0.0

# --- MOVIMIENTO ---

func elegir_direccion_aleatoria() -> void:
	var direcciones: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var nueva_dir: Vector2 = direcciones.pick_random()
	while nueva_dir == direccion_actual:
		nueva_dir = direcciones.pick_random()
		
	direccion_actual = nueva_dir
	timer_accion.start(randf_range(1.5, 3.0))

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
	match estado_actual:
		Estado.EN_PUESTO, Estado.TOMANDO_CAFE:
			empezar_ronda_normal()
		Estado.RONDA_NORMAL:
			# De repente durante la ronda activa el estado de pregunta
			if randf() < probabilidad_pregunta:
				activar_modo_pregunta()
			else:
				empezar_a_volver()
		Estado.RONDA_PREGUNTA:
			empezar_a_volver()

func _on_timer_accion_timeout() -> void:
	if estado_actual == Estado.EN_PUESTO:
		if randf() < 0.5:
			estado_actual = Estado.TOMANDO_CAFE
			anim_player.play("drinking")
		else:
			timer_accion.start(randf_range(2.5, 5.5))
	elif estado_actual == Estado.RONDA_NORMAL or estado_actual == Estado.RONDA_PREGUNTA:
		elegir_direccion_aleatoria()

func _on_animacion_terminada(anim_name: StringName) -> void:
	if anim_name == "drinking" and estado_actual == Estado.TOMANDO_CAFE:
		estado_actual = Estado.EN_PUESTO
		anim_player.play("Idle")
		timer_accion.start(randf_range(3.0, 6.0))

func _on_zona_pregunta_body_entered(body: Node2D) -> void:
	if body.name == "Coordinador" and estado_actual == Estado.RONDA_PREGUNTA:
		empezar_a_volver()
		get_tree().paused = true
		
		var duda_elegida: Dictionary = dudas_aseadora.pick_random()
		if menu_trivia != null:
			menu_trivia.mostrar_pregunta(duda_elegida)
		else:
			print("ERROR: No se encontró MenuTrivia en /root/NivelBanco/CanvasLayer/MenuTrivia")
			get_tree().paused = false
