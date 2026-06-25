extends Node


enum SoundEffects{
	BLOOP_HIGH, 
	BLOOP, 
	DIRT_1, 
	DIRT_2, 
	DIRT_3, 
	DIRT_4, 
	DOUBLE_CLICK, 
	POP, 
	POSITIVE_NOTIFICATION, 
	SINGLE_CLICK_1, 
	SINGLE_CLICK_2, 
	LINE_BREAK, 
	PERK, 
	DEATHLINE, 
	BLOCK_DESTROY, 
	TRANSITION, 
	RADIOACTIVE, 
	DYNAMITE, 
	DICE, 
	COLONY, 
	EATING, 
	MAGIC_SPELL, 
	PIANO, 
	ELECTRIC_GUITAR, 
	ACOUSTIC_GUITAR, 
	SINGLE_CLICK_3, 
	OWO_LOW, 
	OWO_HIGH, 
	BONE_CRACK, 
	FIRE_BALL, 
	STRING, 
	CANNON, 
	QUICK_BLOOD, 
	COIN
}

enum Music{
	MUSIC_0, 
	MUSIC_1
}

var _audio_cache: Dictionary[SoundEffects, AudioStreamOggVorbis] = {
	SoundEffects.BLOOP_HIGH: preload("res://sounds/bloop_high.ogg"), 
	SoundEffects.BLOOP: preload("res://sounds/bloop.ogg"), 
	SoundEffects.DIRT_1: preload("res://sounds/dirt_1.ogg"), 
	SoundEffects.DIRT_2: preload("res://sounds/dirt_2.ogg"), 
	SoundEffects.DIRT_3: preload("res://sounds/dirt_3.ogg"), 
	SoundEffects.DIRT_4: preload("res://sounds/dirt_4.ogg"), 
	SoundEffects.DOUBLE_CLICK: preload("res://sounds/double_click.ogg"), 
	SoundEffects.POP: preload("res://sounds/pop.ogg"), 
	SoundEffects.POSITIVE_NOTIFICATION: preload("res://sounds/positive_notification.ogg"), 
	SoundEffects.SINGLE_CLICK_1: preload("res://sounds/single_click_1.ogg"), 
	SoundEffects.SINGLE_CLICK_2: preload("res://sounds/single_click_2.ogg"), 
	SoundEffects.SINGLE_CLICK_3: preload("res://sounds/click_3.ogg"), 
	SoundEffects.LINE_BREAK: preload("res://sounds/line_break.ogg"), 
	SoundEffects.PERK: preload("res://sounds/perk.ogg"), 
	SoundEffects.DEATHLINE: preload("res://sounds/deathline.ogg"), 
	SoundEffects.BLOCK_DESTROY: preload("res://sounds/block.ogg"), 
	SoundEffects.TRANSITION: preload("res://sounds/transition.ogg"), 
	SoundEffects.RADIOACTIVE: preload("res://sounds/radioactive.ogg"), 
	SoundEffects.DYNAMITE: preload("res://sounds/dynamite.ogg"), 
	SoundEffects.DICE: preload("res://sounds/dice.ogg"), 
	SoundEffects.COLONY: preload("res://sounds/colony.ogg"), 
	SoundEffects.EATING: preload("res://sounds/eating.ogg"), 
	SoundEffects.MAGIC_SPELL: preload("res://sounds/magic_spell.ogg"), 
	SoundEffects.PIANO: preload("res://sounds/piano.ogg"), 
	SoundEffects.ELECTRIC_GUITAR: preload("res://sounds/electric_guitar.ogg"), 
	SoundEffects.ACOUSTIC_GUITAR: preload("res://sounds/acoustic_guitar.ogg"), 
	SoundEffects.OWO_LOW: preload("res://sounds/owo_low.ogg"), 
	SoundEffects.OWO_HIGH: preload("res://sounds/owo_high.ogg"), 
	SoundEffects.BONE_CRACK: preload("res://sounds/bone_crack.ogg"), 
	SoundEffects.FIRE_BALL: preload("res://sounds/fireball.ogg"), 
	SoundEffects.STRING: preload("res://sounds/string.ogg"), 
	SoundEffects.CANNON: preload("res://sounds/cannon.ogg"), 
	SoundEffects.QUICK_BLOOD: preload("res://sounds/quick_blood.ogg"), 
	SoundEffects.COIN: preload("res://sounds/coin.ogg")
}

var _music_cache: Dictionary[Music, AudioStreamOggVorbis] = {
	Music.MUSIC_0: preload("res://musics/music_0.ogg"), 
	Music.MUSIC_1: preload("res://musics/music_1.ogg"), 
}

var _playlist: Array[Music] = [Music.MUSIC_0, Music.MUSIC_1]
var _current_music_index: int = 0
var _music_player: AudioStreamPlayer

var playing: Dictionary[SoundEffects, AudioStreamPlayer] = {}


func _ready() -> void :
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_playlist.shuffle()

	add_child(_music_player)

	_music_player.finished.connect( func():
		_current_music_index = (_current_music_index + 1) % _playlist.size()
		_play_current_music()
	)

	if _playlist.size() > 0:
		_play_current_music()


func _play_current_music() -> void :
	if _current_music_index < _playlist.size():
		var music_key = _playlist[_current_music_index]
		if _music_cache.has(music_key):
			_music_player.stream = _music_cache[music_key]
			_music_player.play()


func set_music_filter_enabled(enabled: bool) -> void :
	var music_bus_index = AudioServer.get_bus_index("Music")
	if music_bus_index != -1:
		var filter_effect_index = 1
		if AudioServer.get_bus_effect_count(music_bus_index) > filter_effect_index:
			AudioServer.set_bus_effect_enabled(music_bus_index, filter_effect_index, enabled)


func play(index: SoundEffects, pitch: float = 1.0) -> void :
	if not _audio_cache.has(index):
		return

	if playing.has(index):
		playing[index].stop()
		playing[index].queue_free()
		playing.erase(index)


	var audio_stream_player: = AudioStreamPlayer.new()

	audio_stream_player.bus = "Effects"
	audio_stream_player.stream = _audio_cache[index]
	audio_stream_player.pitch_scale = pitch

	add_child(audio_stream_player)

	playing[index] = audio_stream_player

	audio_stream_player.play()
	audio_stream_player.finished.connect( func():
		audio_stream_player.queue_free()
		playing.erase(index)
	)


func is_playing(index: SoundEffects) -> bool:
	return playing.has(index) and playing[index].playing


func stop(index: SoundEffects) -> void :
	if playing.has(index):
		playing[index].stop()
		playing[index].queue_free()
		playing.erase(index)
