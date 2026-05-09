extends Node
class_name AudioManager

const AUDIO_PATHS := {
	"title_bgm": "res://audio/title_bgm.ogg",
	"bus_loop_bgm": "res://audio/bus_loop_bgm.ogg",
	"color_choice_bgm": "res://audio/color_choice_bgm.ogg",
	"ending_bgm": "res://audio/ending_bgm.ogg",
	"rain_ambience": "res://audio/rain_ambience.ogg",
	"bus_engine_ambience": "res://audio/bus_engine_ambience.ogg",
	"bus_stop_sfx": "res://audio/bus_stop_sfx.ogg",
	"bell_sfx": "res://audio/bell_sfx.ogg",
	"phone_vibration_sfx": "res://audio/phone_vibration_sfx.ogg",
	"ui_select_sfx": "res://audio/ui_select_sfx.ogg"
}

var bgm_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer

func _ready() -> void:
	bgm_player = _create_player("BGM")
	ambience_player = _create_player("Ambience")
	sfx_player = _create_player("SFX")
	voice_player = _create_player("Voice")

func play_bgm(name: String) -> void:
	_play_on_player(bgm_player, name)

func play_ambience(name: String) -> void:
	_play_on_player(ambience_player, name)

func play_sfx(name: String) -> void:
	_play_on_player(sfx_player, name)

func set_ambience_volume(db: float) -> void:
	if ambience_player:
		ambience_player.volume_db = db

func fade_bgm(duration: float = 0.8, target_db: float = -24.0) -> void:
	if not bgm_player:
		return
	var tween := create_tween()
	tween.tween_property(bgm_player, "volume_db", target_db, duration)

func _create_player(bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	return player

func _play_on_player(player: AudioStreamPlayer, slot_name: String) -> void:
	var stream := _load_stream(slot_name)
	if stream == null:
		return
	player.stream = stream
	player.volume_db = 0.0
	player.play()

func _load_stream(slot_name: String) -> AudioStream:
	var path: String = AUDIO_PATHS.get(slot_name, "")
	if path.is_empty():
		push_warning("정의되지 않은 오디오 슬롯: %s" % slot_name)
		return null
	if not FileAccess.file_exists(path):
		push_warning("오디오 파일이 없어 재생을 건너뜁니다: %s" % path)
		return null
	var stream := load(path)
	if stream == null:
		push_warning("오디오를 로드하지 못했습니다: %s" % path)
	return stream
