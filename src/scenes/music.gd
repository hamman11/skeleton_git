extends AudioStreamPlayer


const level_music = preload("res://assets/sfx/hot_dope-halloween-one-loop-5-416586.mp3")

func _play_music(music: AudioStream, volume = -27.0):
	if stream == music:
		return
	
	stream = music
	volume_db = volume
	play()
	
func play_level_music():
	_play_music(level_music)
