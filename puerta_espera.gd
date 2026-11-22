extends Area2D

@onready var hud = get_node("/root/NivelBanco/HUD")

@export var camara: Camera2D 
@export var nueva_posicion_camara: Vector2 
@export var empuje_jugador: Vector2 = Vector2(0, 32)
# ¡NUEVA VARIABLE! Nos permite decirle a cada puerta a qué sala va desde el Inspector
@export var sala_destino: String = "Sala 7" 

func _on_puerta_espera_body_entered(body: Node2D) -> void:
	if body.name == "Coordinador":
		get_tree().paused = true
		
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		
		tween.tween_property(camara, "global_position", nueva_posicion_camara, 1.0).set_trans(Tween.TRANS_SINE)
		
		body.process_mode = Node.PROCESS_MODE_ALWAYS
		tween.parallel().tween_property(body, "global_position", body.global_position + empuje_jugador, 1.0)
		
		tween.tween_callback(despausar_juego.bind(body))
		
		# Ahora el HUD usa la variable en lugar de un texto fijo
		if hud != null:
			hud.actualizar_minimapa(sala_destino)
	
func despausar_juego(body: Node2D):
	body.process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().paused = false
