extends Spatial

var particles
var audio_played = false
var all_emitted = false

func _ready():
	$audio.connect("finished", self, "_on_audio_finished")
	particles = get_children()
	for p in particles:
		if p is Particles:
			p.emitting = true
			p.one_shot = true
	pass

func _physics_process(delta):
	if !$audio.playing and !audio_played:
		$audio.play()
	
	for p in particles:
		if p is Particles:
			print(p.emitting)
			if !p.emitting:
				all_emitted = true
			else:
				all_emitted = false
	
	if all_emitted:
		print("Freed")
		queue_free()

func _on_audio_finished():
	audio_played = true
