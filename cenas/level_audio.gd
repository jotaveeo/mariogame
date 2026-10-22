class_name LevelAudio
extends Node

signal sound_played(sound: StringName)
signal jingle_finished

const JINGLES = [&"death", &"game_over", &"warning", &"stage_clear", &"world_clear"]

@export_range(-40.0, 0.0) var effects_volume_db: float = 0.0
@export_range(-40.0, 0.0) var jingles_volume_db: float = -3.0

var streams: Dictionary[StringName, AudioStream] = {}
var effect_players: Dictionary[StringName, AudioStreamPlayer] = {}

@onready var jingle: AudioStreamPlayer = $Jingles/death

func _ready() -> void:
	for channel: AudioStreamPlayer in $Effects.get_children():
		var sound = StringName(channel.name)
		channel.volume_db = effects_volume_db
		streams[sound] = channel.stream
		effect_players[sound] = channel
	for channel: AudioStreamPlayer in $Jingles.get_children():
		channel.volume_db = jingles_volume_db
		streams[StringName(channel.name)] = channel.stream
		channel.finished.connect(jingle_finished.emit)
	if DisplayServer.get_name() != "headless":
		print("Áudio do jogo: driver %s, saída %s" % [AudioServer.get_driver_name(), AudioServer.output_device])
		if AudioServer.get_driver_name() == "Dummy":
			push_warning("O Godot está usando o driver Dummy, sem saída de som. Verifique o dispositivo de áudio do sistema.")

func play(sound: StringName) -> bool:
	if not streams.has(sound):
		return false
	if sound in JINGLES:
		if sound != &"warning":
			for channel in effect_players.values():
				channel.stop()
		jingle.stop()
		jingle = get_node("Jingles/" + String(sound))
		jingle.play()
	else:
		effect_players[sound].play()
	sound_played.emit(sound)
	return true

func is_jingle_playing() -> bool:
	return jingle.playing

func stop_all() -> void:
	for group in [$Effects, $Jingles]:
		for channel: AudioStreamPlayer in group.get_children():
			channel.stop()

func _exit_tree() -> void:
	stop_all()
