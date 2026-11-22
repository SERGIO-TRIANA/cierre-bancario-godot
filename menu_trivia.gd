extends Control

@onready var texto_pregunta = $Panel/TextoPregunta
@onready var boton1 = $Panel/VBoxContainer/Boton1
@onready var boton2 = $Panel/VBoxContainer/Boton2
@onready var boton3 = $Panel/VBoxContainer/Boton3

var respuesta_correcta_actual = -1

func _ready():
	# Nos aseguramos de que este menú ignore la pausa del juego para poder hacer clic
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Conectamos los botones por código
	boton1.pressed.connect(_on_boton_presionado.bind(0))
	boton2.pressed.connect(_on_boton_presionado.bind(1))
	boton3.pressed.connect(_on_boton_presionado.bind(2))
	
	# Escondemos el menú al iniciar
	hide()

# Esta función la llamará el Cliente Preguntón cuando te atrape
func mostrar_pregunta(datos_pregunta: Dictionary):
	texto_pregunta.text = datos_pregunta["pregunta"]
	boton1.text = datos_pregunta["opciones"][0]
	boton2.text = datos_pregunta["opciones"][1]
	boton3.text = datos_pregunta["opciones"][2]
	respuesta_correcta_actual = datos_pregunta["respuesta_correcta"]
	GestorAudio.reproducir_sfx("alerta")
	GestorAudio.activar_modo_trivia(true)
	show()
	

func _on_boton_presionado(indice_boton: int):
	if indice_boton == respuesta_correcta_actual:
		print("¡Correcto! Puedes seguir trabajando.")
		# Aquí despausaremos el juego y esconderemos el menú
		GestorAudio.reproducir_sfx("acierto")
		GestorAudio.activar_modo_trivia(false)
		get_tree().paused = false
		hide()
	else:
		print("¡Incorrecto! El cliente se quejó y te mandaron al inicio.")
		# Aquí implementaremos el castigo (volver al inicio del nivel)
		# Por ahora, solo despausamos y escondemos
		get_tree().paused = false
		GestorAudio.reproducir_sfx("error")
		hide()
