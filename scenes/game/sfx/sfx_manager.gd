extends Node


const INITIAL_PLAYER_COUNT: int = 5
const INVALID_PLAYBACK_ID: int = -1


var _permanent_players: Array[AudioStreamPlayer] = []

var _active_players: Dictionary = {}
var _active_unique_sfx: Dictionary = {}

var _next_playback_id: int = 0


var _sounds: Dictionary = {
	Enums.Sfx.FOOTSTEP: preload("uid://bxefle5xo7qkc"),
	Enums.Sfx.BUTTON_CLICK: preload("uid://cha8sjdmyqyhs"),
	Enums.Sfx.NEWSPAPER_OPEN:preload("uid://u56hatn3416e")
}


func _ready() -> void:
	for i in INITIAL_PLAYER_COUNT:
		_create_permanent_player()


func play(sfx: Enums.Sfx, unique: bool = false) -> int: #jei unique =true tai tik vienas toks sfx gali gyvuot zaidime tol kol jo nesustabdys ar jis pats uzsibaigs
	_cleanup_inactive_players()

	if sfx == Enums.Sfx.NONE:
		return INVALID_PLAYBACK_ID

	var stream: AudioStream = _sounds.get(sfx)

	if stream == null:
		push_warning(
			"SFX not registered: %s"
			% Enums.Sfx.keys()[sfx]
		)
		return INVALID_PLAYBACK_ID

	if unique:
		return _play_unique(sfx, stream)

	return _play_normal(sfx, stream)


func stop(playback_id: int) -> void:
	_cleanup_inactive_players()

	if not _active_players.has(playback_id):
		return

	var player: AudioStreamPlayer = _active_players[playback_id]

	player.stop()
	_release_player(player)


func is_playing(playback_id: int) -> bool:
	_cleanup_inactive_players()

	if not _active_players.has(playback_id):
		return false

	var player: AudioStreamPlayer = _active_players[playback_id]

	return player.playing


func _play_unique(sfx: Enums.Sfx,stream: AudioStream) -> int:
	if _active_unique_sfx.has(sfx):
		var playback_id: int = _active_unique_sfx[sfx]

		if _active_players.has(playback_id):
			var existing_player: AudioStreamPlayer = \
				_active_players[playback_id]

			if existing_player.playing:
				return playback_id

		_active_unique_sfx.erase(sfx)

	var player := _create_temporary_player()
	var playback_id := _create_playback_id()

	_prepare_player(
		player,
		playback_id,
		sfx,
		true,
		stream
	)

	_active_unique_sfx[sfx] = playback_id

	player.play()

	return playback_id


func _play_normal(
	sfx: Enums.Sfx,
	stream: AudioStream
) -> int:
	var player := _get_available_permanent_player()

	# Visi 5 permanent užimti.
	if player == null:
		player = _create_temporary_player()

	var playback_id := _create_playback_id()

	_prepare_player(
		player,
		playback_id,
		sfx,
		false,
		stream
	)

	player.play()

	return playback_id


func _prepare_player(
	player: AudioStreamPlayer,
	playback_id: int,
	sfx: Enums.Sfx,
	unique: bool,
	stream: AudioStream
) -> void:
	player.stream = stream

	player.set_meta("playback_id", playback_id)
	player.set_meta("sfx", sfx)
	player.set_meta("unique", unique)

	_active_players[playback_id] = player


func _get_available_permanent_player() -> AudioStreamPlayer:
	for player in _permanent_players:
		if not player.playing:
			return player

	return null


func _create_permanent_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()

	player.bus = "SFX"
	player.set_meta("temporary", false)
	player.set_meta("playback_id", INVALID_PLAYBACK_ID)

	player.finished.connect(
		_on_player_finished.bind(player)
	)

	add_child(player)

	_permanent_players.append(player)

	return player


func _create_temporary_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()

	player.bus = "SFX"
	player.set_meta("temporary", true)
	player.set_meta("playback_id", INVALID_PLAYBACK_ID)

	player.finished.connect(
		_on_player_finished.bind(player)
	)

	add_child(player)

	return player


func _on_player_finished(player: AudioStreamPlayer) -> void:
	_release_player(player)


func _release_player(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		return

	var playback_id: int = player.get_meta(
		"playback_id",
		INVALID_PLAYBACK_ID
	)

	var sfx: Enums.Sfx = player.get_meta(
		"sfx",
		Enums.Sfx.NONE
	)

	var unique: bool = player.get_meta(
		"unique",
		false
	)

	if playback_id != INVALID_PLAYBACK_ID:
		_active_players.erase(playback_id)

	if unique:
		if _active_unique_sfx.get(
			sfx,
			INVALID_PLAYBACK_ID
		) == playback_id:
			_active_unique_sfx.erase(sfx)

	player.set_meta(
		"playback_id",
		INVALID_PLAYBACK_ID
	)

	player.set_meta(
		"sfx",
		Enums.Sfx.NONE
	)

	player.set_meta(
		"unique",
		false
	)

	player.stream = null

	if player.get_meta("temporary", false):
		player.queue_free()


func _cleanup_inactive_players() -> void:
	var playback_ids := _active_players.keys()

	for playback_id in playback_ids:
		if not _active_players.has(playback_id):
			continue

		var player: AudioStreamPlayer = \
			_active_players[playback_id]

		if not is_instance_valid(player):
			_active_players.erase(playback_id)
			_cleanup_unique_id(playback_id)
			continue

		if player.playing:
			continue

		_release_player(player)


func _cleanup_unique_id(playback_id: int) -> void:
	var unique_sfx := _active_unique_sfx.keys()

	for sfx in unique_sfx:
		if _active_unique_sfx[sfx] == playback_id:
			_active_unique_sfx.erase(sfx)


func _create_playback_id() -> int:
	_next_playback_id += 1

	return _next_playback_id
