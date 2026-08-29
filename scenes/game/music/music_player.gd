class_name MusicManager
extends Node


@onready var music_player: AudioStreamPlayer = $MusicPlayer

@export var menu_music: AudioStream
@export var gameplay_music: AudioStream


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.finished.connect(_on_music_finished)


func play_music_for_state(game_state: Enums.GameState) -> void:
	var track: Enums.MusicTrack = _get_track_for_state(game_state)

	play_track(track)


func play_track(track: Enums.MusicTrack) -> void:
	var music: AudioStream = _get_music(track)

	if music == null:
		stop_music()
		return

	if music_player.stream == music and music_player.playing:
		return

	music_player.stream = music
	music_player.play()


func stop_music() -> void:
	if music_player.playing:
		music_player.stop()

	music_player.stream = null


func _get_track_for_state(game_state: Enums.GameState) -> Enums.MusicTrack:
	match game_state:
		Enums.GameState.START:
			return Enums.MusicTrack.MENU

		Enums.GameState.NEWSPAPER:
			return Enums.MusicTrack.GAMEPLAY

		Enums.GameState.SHOP:
			return Enums.MusicTrack.GAMEPLAY

		Enums.GameState.CONSTRUCTION:
			return Enums.MusicTrack.GAMEPLAY

		Enums.GameState.ENDGAME:
			return Enums.MusicTrack.MENU

		_:
			return Enums.MusicTrack.NONE


func _get_music(track: Enums.MusicTrack) -> AudioStream:
	match track:
		Enums.MusicTrack.MENU:
			return menu_music

		Enums.MusicTrack.GAMEPLAY:
			return gameplay_music

		_:
			return null


func _on_music_finished() -> void:
	if music_player.stream == null:
		return

	music_player.play()
