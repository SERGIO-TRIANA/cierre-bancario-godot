extends Node

@export var tiempo_limite_cierre: float = 240.0 # 4 minutos totales para cerrar la sucursal
@export var tiempo_por_tarea: float = 60.0      # 1 minuto por cada tarea
@export var clave_boveda: String = "4820"

var tareas: Array[Dictionary] = [
	{ "id": "pc_oficina", "desc": "Lee el correo en tu PC (Sala 4) para obtener la clave de bóveda." },
	{ "id": "turnos_espera", "desc": "Revisa los turnos lentos en Sala de Espera 1 (Sala 7)." },
	{ "id": "autorizar_asesor", "desc": "Da una autorización en la sala de Asesores (Sala 5)." },
	{ "id": "autorizar_cajero", "desc": "Aprueba un retiro alto en la sala de Cajeros (Sala 6)." },
	{ "id": "tomar_agua", "desc": "Te dio sed: toma agua en la Cafetería (Sala 2)." },
	{ "id": "llamada_oficina", "desc": "Atiende la llamada de gerencia en tu Oficina (Sala 4)." },
	{ "id": "revisar_filas", "desc": "Verifica la salida de los últimos clientes (Salas 8/9)." },
	{ "id": "clave_boveda", "desc": "Ve a la Bóveda (Sala 3) e ingresa la clave de cierre." }
]

var indice_actual: int = 0
var tiempo_restante_cierre: float = 0.0
var tiempo_restante_tarea: float = 0.0
var juego_activo: bool = false
var urgencia_activada: bool = false
var hud: CanvasLayer = null
var menu_trivia: Control = null

func _ready() -> void:
	# Permite que el tiempo siga corriendo aunque una trivia pause el juego
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	tiempo_restante_cierre = tiempo_limite_cierre
	hud = get_node_or_null("/root/NivelBanco/CanvasLayer/HUD")
	if hud == null:
		hud = get_node_or_null("/root/NivelBanco/HUD")
	menu_trivia = get_node_or_null("/root/NivelBanco/CanvasLayer/MenuTrivia")
	
	call_deferred("iniciar_sistema")

func iniciar_sistema() -> void:
	for zona in get_tree().get_nodes_in_group("zonas_tarea"):
		zona.tarea_tocada.connect(_on_tarea_tocada)
	
	if hud != null:
		hud.clave_boveda_correcta.connect(_on_clave_boveda_correcta)
	
	juego_activo = true
	
	urgencia_activada = false
	GestorAudio.activar_urgencia(false)
	GestorAudio.iniciar_musica()
	activar_tarea_actual()

func _process(delta: float) -> void:
	if not juego_activo:
		return
		
	tiempo_restante_cierre -= delta
	tiempo_restante_tarea -= delta
	
	if hud != null:
		hud.actualizar_tiempos(tiempo_restante_cierre, tiempo_restante_tarea)
	if tiempo_restante_cierre <= 60.0 and not urgencia_activada:
		urgencia_activada = true
		GestorAudio.activar_urgencia(true)
	
	if tiempo_restante_cierre <= 0.0:
		terminar_por_tiempo("Se acabó el tiempo límite de 4 minutos para cerrar la sucursal.")
	elif tiempo_restante_tarea <= 0.0:
		terminar_por_tiempo("Se acabó el minuto para completar la tarea actual.")

func terminar_por_tiempo(motivo: String) -> void:
	juego_activo = false
	GestorAudio.activar_modo_trivia(false)
	GestorAudio.detener_musica()
	GestorAudio.reproducir_sfx("derrota")
	if menu_trivia != null:
		menu_trivia.hide()
	if hud != null:
		hud.mostrar_pantalla_fin(false, 0.0, motivo)

func activar_tarea_actual() -> void:
	var tarea_actual: Dictionary = tareas[indice_actual]
	tiempo_restante_tarea = minf(tiempo_por_tarea, tiempo_restante_cierre)
	
	for zona in get_tree().get_nodes_in_group("zonas_tarea"):
		zona.activar(zona.id_tarea == tarea_actual["id"])
	
	if hud != null:
		hud.actualizar_tiempos(tiempo_restante_cierre, tiempo_restante_tarea)
		hud.actualizar_texto_tarea(indice_actual, tareas.size(), tarea_actual["desc"])

func _on_tarea_tocada(id: String) -> void:
	if not juego_activo:
		return
		
	if id == "pc_oficina" and hud != null:
		hud.mostrar_clave_obtenida(clave_boveda)
	
	if id == "clave_boveda" and hud != null:
		GestorAudio.reproducir_sfx("alerta")
		GestorAudio.activar_modo_trivia(true)
		hud.abrir_panel_clave()
		return
		
	GestorAudio.reproducir_sfx("tarea")
	avanzar_siguiente_tarea()

func _on_clave_boveda_correcta() -> void:
	juego_activo = false
	GestorAudio.activar_modo_trivia(false)
	GestorAudio.detener_musica()
	GestorAudio.reproducir_sfx("victoria")
	if hud != null:
		hud.mostrar_pantalla_fin(true, tiempo_restante_cierre)

func avanzar_siguiente_tarea() -> void:
	indice_actual += 1
	if indice_actual >= tareas.size():
		juego_activo = false
		if hud != null:
			hud.mostrar_pantalla_fin(true, tiempo_restante_cierre)
	else:
		activar_tarea_actual()
