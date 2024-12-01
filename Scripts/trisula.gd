extends Skill
class_name Trisula

func _init(target):
	cooldown = 1
	animation_name = "Laser"
	texture = preload("res://Assets/Artefak dan Efek/Artefak/Trisula.png")
	
	super._init(target)
	
func cast_spell(target):
	super.cast_spell(target)
	target.multi_shot()