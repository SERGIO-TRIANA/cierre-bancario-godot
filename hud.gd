extends CanvasLayer

signal clave_boveda_correcta

@onready var indicador: Control = $MapaImagen/Indicador

@onready var texto_tiempo: Label = $PanelMision/TextoTiempo
@onready var texto_tarea: Label = $PanelMision/TextoTarea
@onready var texto_clave: Label = $PanelMision/TextoClave

@onready var panel_clave: Panel = $PanelClave
@onready var campo_clave: LineEdit = $PanelClave/CampoClave
@onready var mensaje_clave: Label = $PanelClave/MensajeClave
@onready var boton_confirmar_clave: Button = $PanelClave/BotonConfirmarClave

@onready var panel_fin: Panel = $PanelFin
@onready var titulo_fin: Label = $PanelFin/TituloFin
@onready var mensaje_fin: Label = $PanelFin/MensajeFin
@onready var boton_reintentar: Button = $PanelFin/BotonReintentar
@onready var boton_menu: Button = $PanelFin/BotonMenu

# Diccionario con tus coordenadas exactas del minimapa
var posiciones_salas: Dictionary = {
	"Sala 4": Vector2(-377, -12), # Oficina Coordinador
	"Sala 7": Vector2(-377, 220), # Sala de Espera 1
	"Sala 2": Vector2(-28, -262), # Cafetería
	"Sala 3": Vector2(310, -280), # Bóveda
	"Sala 5": Vector2(-17, -18),  # Asesores
	"Sala 6": Vector2(321, -18),  # Cajeros
	"Sala 8": Vector2(-11, 220),  # Sala de Espera 2 (Centro)
	"Sala 9": Vector2(326, 219)   # Sala de Espera 3 (Derecha)
}

var clave_correcta: String = "4820"

func _ready() -> void:
	actualizar_minimapa("Sala 4")
	inicializar_ui_tareas()

func actualizar_minimapa(nombre_sala: String) -> void:
	if posiciones_salas.has(nombre_sala):
		indicador.position = posiciones_salas[nombre_sala]
	else:
		print("La sala no está registrada en el minimapa: ", nombre_sala)

func inicializar_ui_tareas() -> void:
	# Garantiza que la UI siga respondiendo cuando el juego se pausa
	panel_clave.process_mode = Node.PROCESS_MODE_ALWAYS
	panel_fin.process_mode = Node.PROCESS_MODE_ALWAYS
	
	panel_clave.hide()
	panel_fin.hide()
	texto_clave.text = ""
	
	boton_confirmar_clave.pressed.connect(_on_confirmar_clave_pressed)
	campo_clave.text_submitted.connect(func(_texto: String) -> void: _on_confirmar_clave_pressed())
	boton_reintentar.pressed.connect(_on_reintentar_pressed)
	boton_menu.pressed.connect(_on_menu_pressed)

func actualizar_tiempos(tiempo_cierre: float, tiempo_tarea: float) -> void:
	var c_tot: int = maxi(int(ceil(tiempo_cierre)), 0)
	var t_tot: int = maxi(int(ceil(tiempo_tarea)), 0)
	
	var c_min: int = floori(c_tot / 60.0)
	var c_seg: int = c_tot % 60
	var t_min: int = floori(t_tot / 60.0)
	var t_seg: int = t_tot % 60
	
	texto_tiempo.text = "Cierre: %02d:%02d | Tarea: %02d:%02d" % [c_min, c_seg, t_min, t_seg]

func actualizar_texto_tarea(indice: int, total: int, descripcion: String) -> void:
	texto_tarea.text = "Tarea %d/%d: %s" % [indice + 1, total, descripcion]

func mostrar_clave_obtenida(clave: String) -> void:
	clave_correcta = clave
	texto_clave.text = "Clave Bóveda: " + clave

func abrir_panel_clave() -> void:
	get_tree().paused = true
	campo_clave.text = ""
	mensaje_clave.text = ""
	panel_clave.show()
	campo_clave.grab_focus()

func mostrar_pantalla_fin(gano: bool, tiempo_restante: float, motivo_derrota: String = "") -> void:
	get_tree().paused = true
	panel_clave.hide()
	if gano:
		titulo_fin.text = "¡SUCURSAL CERRADA!"
		mensaje_fin.text = "Completaste todas las tareas con %d segundos de sobra." % int(tiempo_restante)
	else:
		titulo_fin.text = "¡SE ACABÓ EL TIEMPO!"
		if motivo_derrota != "":
			mensaje_fin.text = motivo_derrota
		else:
			mensaje_fin.text = "No lograste cerrar la bóveda antes del límite."
	panel_fin.show()

func _on_confirmar_clave_pressed() -> void:
	if campo_clave.text.strip_edges() == clave_correcta:
		panel_clave.hide()
		clave_boveda_correcta.emit()
	else:
		mensaje_clave.text = "Clave incorrecta. Revisa la nota de tu correo."

func _on_reintentar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu_inicio.tscn")
