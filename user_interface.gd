extends Control

@export_file("*.tscn") var escena_nivel: String = "res://nivel_banco.tscn"

@onready var panel_principal: Control = $PanelPrincipal
@onready var panel_instrucciones: Control = $PanelInstrucciones
@onready var boton_jugar: Button = $PanelPrincipal/BotonJugar
@onready var boton_instrucciones: Button = $PanelPrincipal/BotonInstrucciones
@onready var boton_volver: Button = $PanelInstrucciones/BotonVolver

func _ready() -> void:
	# Aseguramos que el juego no arranque pausado si venimos de reiniciar
	get_tree().paused = false
	
	panel_principal.show()
	panel_instrucciones.hide()
	
	boton_jugar.pressed.connect(_on_boton_jugar_pressed)
	boton_instrucciones.pressed.connect(_on_boton_instrucciones_pressed)
	boton_volver.pressed.connect(_on_boton_volver_pressed)

func _on_boton_jugar_pressed() -> void:
	get_tree().change_scene_to_file(escena_nivel)

func _on_boton_instrucciones_pressed() -> void:
	panel_principal.hide()
	panel_instrucciones.show()

func _on_boton_volver_pressed() -> void:
	panel_instrucciones.hide()
	panel_principal.show()
