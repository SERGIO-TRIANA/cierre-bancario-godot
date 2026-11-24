extends Control

@onready var texto_pregunta: Label = $Panel/TextoPregunta
@onready var boton1: Button = $Panel/VBoxContainer/Boton1
@onready var boton2: Button = $Panel/VBoxContainer/Boton2
@onready var boton3: Button = $Panel/VBoxContainer/Boton3

var jugador: CharacterBody2D = null
var camara: Camera2D = null
var hud: CanvasLayer = null

var posicion_oficina_jugador: Vector2 = Vector2.ZERO
var posicion_oficina_camara: Vector2 = Vector2.ZERO
var procesando_castigo: bool = false
var respuesta_correcta_actual: int = -1

func _ready() -> void:
	# Nos aseguramos de que este menú ignore la pausa del juego para poder hacer clic
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("guardar_referencias_oficina")
	
	# Conectamos los botones por código
	boton1.pressed.connect(_on_boton_presionado.bind(0))
	boton2.pressed.connect(_on_boton_presionado.bind(1))
	boton3.pressed.connect(_on_boton_presionado.bind(2))
	
	# Escondemos el menú al iniciar
	hide()

func guardar_referencias_oficina() -> void:
	jugador = get_node_or_null("/root/NivelBanco/Coordinador")
	camara = get_viewport().get_camera_2d()
	if camara == null:
		camara = get_node_or_null("/root/NivelBanco/Camera2D")
	
	# Busca el HUD sin importar si quedó directo en NivelBanco o dentro de CanvasLayer
	hud = get_node_or_null("/root/NivelBanco/CanvasLayer/HUD")
	if hud == null:
		hud = get_node_or_null("/root/NivelBanco/HUD")
	
	if jugador != null:
		posicion_oficina_jugador = jugador.global_position
	if camara != null:
		posicion_oficina_camara = camara.global_position

# Esta función la llaman los NPCs cuando te atrapan
func mostrar_pregunta(datos_pregunta: Dictionary) -> void:
	procesando_castigo = false
	_establecer_botones_activos(true)
	
	texto_pregunta.text = datos_pregunta["pregunta"]
	boton1.text = datos_pregunta["opciones"][0]
	boton2.text = datos_pregunta["opciones"][1]
	boton3.text = datos_pregunta["opciones"][2]
	respuesta_correcta_actual = datos_pregunta["respuesta_correcta"]
	
	GestorAudio.reproducir_sfx("alerta")
	GestorAudio.activar_modo_trivia(true)
	show()

func _on_boton_presionado(indice_boton: int) -> void:
	if procesando_castigo:
		return
		
	if indice_boton == respuesta_correcta_actual:
		GestorAudio.reproducir_sfx("acierto")
		GestorAudio.activar_modo_trivia(false)
		get_tree().paused = false
		hide()
	else:
		procesando_castigo = true
		_establecer_botones_activos(false)
		GestorAudio.reproducir_sfx("error")
		texto_pregunta.text = "¡Respuesta incorrecta! De vuelta a la oficina del Coordinador..."
		
		# El segundo parámetro 'true' hace que el temporizador funcione aunque el juego esté pausado
		await get_tree().create_timer(0.8, true).timeout
		
		# Si el tiempo global se agotó mientras esperaba y GestorTareas ocultó la trivia, no despausamos
		if not visible:
			procesando_castigo = false
			return
			
		_teletransportar_a_oficina()

func _teletransportar_a_oficina() -> void:
	if jugador != null:
		jugador.velocity = Vector2.ZERO
		jugador.global_position = posicion_oficina_jugador
		
	if camara != null:
		camara.global_position = posicion_oficina_camara
		
	if hud != null:
		hud.actualizar_minimapa("Sala 4")
		
	GestorAudio.reproducir_sfx("puerta")
	GestorAudio.activar_modo_trivia(false)
	hide()
	get_tree().paused = false
	procesando_castigo = false

func _establecer_botones_activos(activo: bool) -> void:
	boton1.disabled = not activo
	boton2.disabled = not activo
	boton3.disabled = not activo
