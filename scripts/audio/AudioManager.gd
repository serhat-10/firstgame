extends Node
class_name AudioManager

const MIX_RATE := 22050
const TONE_DURATION := 0.07

var settings: SettingsManager
var player: AudioStreamPlayer

func setup(settings_manager: SettingsManager) -> void:
	settings = settings_manager

func _ready() -> void:
	player = AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = 0.12
	player.stream = stream
	add_child(player)

func play_event(event_name: String) -> void:
	if settings != null and not settings.sound_enabled:
		return
	if player == null:
		return

	var frequency := _frequency_for_event(event_name)
	player.stop()
	player.play()

	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	var frame_count := int(float(MIX_RATE) * TONE_DURATION)
	for index in range(frame_count):
		var t := float(index) / float(MIX_RATE)
		var envelope := 1.0 - (float(index) / float(frame_count))
		var sample := sin(t * frequency * TAU) * 0.12 * envelope
		playback.push_frame(Vector2(sample, sample))

func _frequency_for_event(event_name: String) -> float:
	match event_name:
		"territory_selected":
			return 520.0
		"units_sent":
			return 620.0
		"battle_started":
			return 360.0
		"territory_captured":
			return 760.0
		"territory_lost":
			return 240.0
		"victory":
			return 880.0
		"defeat":
			return 180.0
		"button_tap":
			return 440.0
		_:
			return 400.0

