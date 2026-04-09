extends AudioStreamPlayer

const MENU_MUSIC_PATH = "res://res/sound/songs/main_menu_song.mp3"

func _ready():
	# Указываем шину (Bus), если она создана в микшере
	bus = "Master" 
	process_mode = PROCESS_MODE_ALWAYS # Музыка не встанет на паузу, если игра на паузе
	play_menu_music()

func play_menu_music():
	var music = load(MENU_MUSIC_PATH)
	
	# Если эта песня уже играет — ничего не делаем
	if playing and stream and stream.resource_path == MENU_MUSIC_PATH:
		return
		
	stream = music
	volume_db = 0.0
	play()

func fade_out(duration: float = 1.5):
	if not playing:
		return
		
	var tween = create_tween()
	# Плавно уводим громкость самого узла (self) в тишину
	tween.tween_property(self, "volume_db", -80.0, duration).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(stop)

func play_immediately():
	volume_db = 0.0
	play()
