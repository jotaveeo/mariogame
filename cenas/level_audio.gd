class_name LevelAudio
extends Node

signal sound_played(sound: StringName)
signal jingle_finished

const FILES = {
	&"jump_small": "smb_jump-small.wav",
	&"jump_super": "smb_jump-super.wav",
	&"coin": "smb_coin.wav",
	&"kick": "smb_kick.wav",
	&"stomp": "smb_stomp.wav",
	&"bump": "smb_bump.wav",
	&"brick_break": "smb_breakblock.wav",
	&"power_down": "smb_pipe.wav",
	&"fireball": "smb_fireball.wav",
	&"death": "smb_mariodie.wav",
	&"game_over": "smb_gameover.wav",
	&"warning": "smb_warning.wav",
	&"stage_clear": "smb_stage_clear.wav",
	&"world_clear": "smb_world_clear.wav",
	&"power_up": "smb_powerup.wav",
	&"power_up_appears": "smb_powerup_appears.wav",
}
const JINGLES = [&"death", &"game_over", &"warning", &"stage_clear", &"world_clear"]

@export_range(-40.0, 0.0) var effects_volume_db: float = -8.0
@export_range(-40.0, 0.0) var jingles_volume_db: float = -8.0

var streams: Dictionary[StringName, AudioStream] = {}
var effect_players: Dictionary[StringName, AudioStreamPlayer] = {}

@onready var jingle: AudioStreamPlayer = $Jingle

func _ready() -> void:
	jingle.volume_db = jingles_volume_db
	jingle.finished.connect(jingle_finished.emit)
	for sound in FILES:
		var path = "res://audio/" + FILES[sound]
		if not ResourceLoader.exists(path):
			continue
		streams[sound] = load(path)
		if sound in JINGLES:
			continue
		var channel = AudioStreamPlayer.new()
		channel.name = String(sound)
		channel.stream = streams[sound]
		channel.volume_db = effects_volume_db
		add_child(channel)
		effect_players[sound] = channel

func play(sound: StringName) -> bool:
	if not streams.has(sound):
		return false
	if sound in JINGLES:
		if sound != &"warning":
			for channel in effect_players.values():
				channel.stop()
		jingle.stop()
		jingle.stream = streams[sound]
		jingle.play()
	else:
		effect_players[sound].play()
	sound_played.emit(sound)
	return true

func is_jingle_playing() -> bool:
	return jingle.playing

func stop_all() -> void:
	jingle.stop()
	for channel in effect_players.values():
		channel.stop()

func _exit_tree() -> void:
	stop_all()
