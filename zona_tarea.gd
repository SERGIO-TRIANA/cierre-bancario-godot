extends Area2D

# Escribe aquí el id exacto desde el Inspector (ej: "pc_oficina", "tomar_agua", "clave_boveda")
@export var id_tarea: String = ""

signal tarea_tocada(id: String)

var esta_activa: bool = false

func _ready() -> void:
	if id_tarea == "":
		id_tarea = name
	add_to_group("zonas_tarea")
	body_entered.connect(_on_body_entered)
	activar(false)

func activar(estado: bool) -> void:
	esta_activa = estado
	visible = estado
	set_deferred("monitoring", estado)

func _on_body_entered(body: Node2D) -> void:
	if esta_activa and body.name == "Coordinador":
		tarea_tocada.emit(id_tarea)
