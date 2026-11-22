extends Area2D

@onready var hud = get_node("/root/NivelBanco/HUD")

@export var camara: Camera2D 
@export var nueva_posicion_camara: Vector2 

# Lo dejamos fijo en -32 para que empuje hacia arriba al jugador
var empuje_jugador: Vector2 = Vector2(0, -50) 

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Coordinador":
		get_tree().paused = true
		
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		
		tween.tween_property(camara, "global_position", nueva_posicion_camara, 1.0).set_trans(Tween.TRANS_SINE)
		
		body.process_mode = Node.PROCESS_MODE_ALWAYS
		tween.parallel().tween_property(body, "global_position", body.global_position + empuje_jugador, 1.0)
		
		tween.tween_callback(despausar_juego.bind(body))
		
		# Forzamos directamente a que vaya a la Sala 4
		if hud != null:
			hud.actualizar_minimapa("Sala 3")
	
func despausar_juego(body: Node2D):
	body.process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().paused = false
