extends Node

# Si guardas tu propia música en res://Audio/ con alguno de estos nombres, la usará automáticamente.
# Si no existe todavía, usará la melodía 8-bit retro integrada como respaldo.
const RUTAS_MUSICA: Array[String] = [
	"res://Audio/musica_banco.ogg",
	"res://Audio/musica_banco.mp3",
	"res://Audio/musica_banco.wav"
]

const VOLUMEN_MUSICA_NORMAL: float = -10.0
const VOLUMEN_MUSICA_TRIVIA: float = -19.0
const MIX_RATE: int = 22050

var reproductor_musica: AudioStreamPlayer
var pool_sfx: Array[AudioStreamPlayer] = []
var indice_pool: int = 0
var libreria_sfx: Dictionary = {}

var silenciado: bool = false
var musica_activa: bool = false
var tween_volumen: Tween = null

func _ready() -> void:
	# Clave: sigue sonando aunque las puertas o la trivia pausen el árbol del juego
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Reproductor principal de música
	reproductor_musica = AudioStreamPlayer.new()
	reproductor_musica.bus = "Master"
	reproductor_musica.volume_db = VOLUMEN_MUSICA_NORMAL
	reproductor_musica.finished.connect(_on_musica_terminada)
	add_child(reproductor_musica)
	
	# Pool de 4 reproductores para que varios efectos puedan sonar a la vez sin cortarse
	for i in range(4):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = -6.0
		add_child(p)
		pool_sfx.append(p)
	
	_cargar_musica_de_fondo()
	_generar_efectos_8bit()

func _cargar_musica_de_fondo() -> void:
	for ruta in RUTAS_MUSICA:
		if ResourceLoader.exists(ruta):
			var pista: AudioStream = load(ruta)
			if pista is AudioStreamOggVorbis:
				pista.loop = true
			elif pista is AudioStreamMP3:
				pista.loop = true
			reproductor_musica.stream = pista
			return
	
	# Tema instrumental 8-bit de 2 canales (melodía + bajo) estilo aventura retro
	var melodia: Array[float] = [
		440.0, 0.0, 523.25, 659.25, 587.33, 523.25, 493.88, 523.25,
		698.46, 0.0, 659.25, 587.33, 523.25, 493.88, 440.0, 392.0,
		440.0, 523.25, 659.25, 783.99, 880.0, 783.99, 659.25, 523.25,
		587.33, 659.25, 698.46, 587.33, 659.25, 587.33, 493.88, 415.30
	]
	var bajo: Array[float] = [
		110.0, 220.0, 110.0, 220.0, 110.0, 220.0, 110.0, 220.0,
		87.31, 174.61, 87.31, 174.61, 98.0, 196.0, 98.0, 196.0,
		110.0, 220.0, 110.0, 220.0, 130.81, 261.63, 130.81, 261.63,
		146.83, 293.66, 146.83, 293.66, 164.81, 329.63, 164.81, 123.47
	]
	reproductor_musica.stream = _crear_tema_retro_2_canales(melodia, bajo, 0.18)
	
func _crear_tema_retro_2_canales(melodia: Array[float], bajo: Array[float], duracion_paso: float) -> AudioStreamWAV:
	var muestras_paso: int = int(duracion_paso * MIX_RATE)
	var total_muestras: int = melodia.size() * muestras_paso
	var bytes := PackedByteArray()
	bytes.resize(total_muestras * 2)
	
	var cursor: int = 0
	for paso in range(melodia.size()):
		var f_mel: float = melodia[paso]
		var f_baj: float = bajo[paso]
		for i in range(muestras_paso):
			var t: float = float(i) / float(MIX_RATE)
			var progreso: float = float(i) / float(maxi(muestras_paso, 1))
			var env: float = 1.0
			if progreso < 0.05:
				env = progreso / 0.05
			elif progreso > 0.85:
				env = (1.0 - progreso) / 0.15
			
			var mezcla: float = 0.0
			# Canal 1: onda cuadrada 25% (melodía clásica de 8 bits)
			if f_mel > 0.0:
				var fase_m: float = fmod(t * f_mel, 1.0)
				mezcla += (1.0 if fase_m < 0.25 else -1.0) * 0.14 * env
			# Canal 2: onda triangular (bajo retro suave)
			if f_baj > 0.0:
				var fase_b: float = fmod(t * f_baj, 1.0)
				mezcla += (4.0 * absf(fase_b - 0.5) - 1.0) * 0.16 * env
			
			bytes.encode_s16(cursor * 2, clampi(int(mezcla * 32767.0), -32768, 32767))
			cursor += 1
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = total_muestras
	return wav
func _generar_efectos_8bit() -> void:
	libreria_sfx["boton"] = _crear_wav_chiptune([[660.0, 0.045]], 0.28)
	libreria_sfx["puerta"] = _crear_wav_chiptune([[330.0, 0.05], [440.0, 0.06]], 0.22)
	libreria_sfx["alerta"] = _crear_wav_chiptune([[880.0, 0.07], [1174.66, 0.14]], 0.32)
	libreria_sfx["acierto"] = _crear_wav_chiptune([[523.25, 0.07], [659.25, 0.07], [783.99, 0.14]], 0.30)
	libreria_sfx["error"] = _crear_wav_chiptune([[220.0, 0.12], [164.81, 0.22]], 0.32)
	libreria_sfx["tarea"] = _crear_wav_chiptune([[523.25, 0.08], [659.25, 0.08], [783.99, 0.08], [1046.5, 0.22]], 0.32)
	libreria_sfx["victoria"] = _crear_wav_chiptune([[523.25, 0.10], [659.25, 0.10], [783.99, 0.10], [1046.5, 0.18], [783.99, 0.10], [1046.5, 0.35]], 0.34)
	libreria_sfx["derrota"] = _crear_wav_chiptune([[392.0, 0.18], [369.99, 0.18], [349.23, 0.18], [329.63, 0.42]], 0.32)

# --- FUNCIONES PÚBLICAS PARA LLAMAR DESDE TUS SCRIPTS ---

func iniciar_musica() -> void:
	musica_activa = true
	reproductor_musica.pitch_scale = 1.0
	reproductor_musica.volume_db = VOLUMEN_MUSICA_NORMAL
	if not reproductor_musica.playing and reproductor_musica.stream != null:
		reproductor_musica.play()

func detener_musica() -> void:
	musica_activa = false
	reproductor_musica.stop()

func reproducir_sfx(nombre: String) -> void:
	if not libreria_sfx.has(nombre):
		return
	var reproductor: AudioStreamPlayer = pool_sfx[indice_pool]
	indice_pool = (indice_pool + 1) % pool_sfx.size()
	reproductor.stream = libreria_sfx[nombre]
	reproductor.play()

func activar_modo_trivia(en_trivia: bool) -> void:
	var destino_db: float = VOLUMEN_MUSICA_TRIVIA if en_trivia else VOLUMEN_MUSICA_NORMAL
	if tween_volumen != null and tween_volumen.is_running():
		tween_volumen.kill()
	tween_volumen = create_tween()
	tween_volumen.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_volumen.tween_property(reproductor_musica, "volume_db", destino_db, 0.25)

func activar_urgencia(urgente: bool) -> void:
	reproductor_musica.pitch_scale = 1.15 if urgente else 1.0

func alternar_silencio() -> bool:
	silenciado = not silenciado
	AudioServer.set_bus_mute(0, silenciado)
	return silenciado

func _on_musica_terminada() -> void:
	if musica_activa:
		reproductor_musica.play()

# --- SINTETIZADOR RETRO 8-BIT (COMPATIBLE 100% CON WEB / VERCEL) ---

func _crear_wav_chiptune(notas: Array, amplitud: float = 0.28, ancho_pulso: float = 0.5, bucle: bool = false) -> AudioStreamWAV:
	var total_muestras: int = 0
	for nota in notas:
		total_muestras += int(float(nota[1]) * MIX_RATE)
	
	var bytes := PackedByteArray()
	bytes.resize(total_muestras * 2)
	
	var cursor: int = 0
	for nota in notas:
		var freq: float = float(nota[0])
		var duracion: float = float(nota[1])
		var cant_muestras: int = int(duracion * MIX_RATE)
		
		for i in range(cant_muestras):
			var muestra: int = 0
			if freq > 0.0:
				var t: float = float(i) / float(MIX_RATE)
				var fase: float = fmod(t * freq, 1.0)
				var onda: float = 1.0 if fase < ancho_pulso else -1.0
				
				# Suavizado corto al inicio y final de cada nota para evitar chasquidos
				var progreso: float = float(i) / float(maxi(cant_muestras, 1))
				var envolvente: float = 1.0
				if progreso < 0.04:
					envolvente = progreso / 0.04
				elif progreso > 0.82:
					envolvente = (1.0 - progreso) / 0.18
				
				muestra = clampi(int(onda * envolvente * amplitud * 32767.0), -32768, 32767)
			
			bytes.encode_s16(cursor * 2, muestra)
			cursor += 1
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	if bucle:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = total_muestras
	return wav
