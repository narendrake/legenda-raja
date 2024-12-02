extends CharacterBody2D
class_name Boss_Bayangan

# What state the turret is in
enum BossState {
	Tangan,
	Walking,
	Dead,
	Tongkat
}
@onready var animated_sprite_2d: BossAnimationController = $AnimatedSprite2D
@onready var player : Player = get_node("../Player")
@onready var bossHealth : BossHealthSystem = $HealthSystem
@onready var flash_animation = $AnimatedSprite2D/FlashAnimation
@onready var freeze_manager = $"../FreezeManager"
@onready var crack_scene = preload("res://Boss/Bayangan/crack.tscn")
@onready var punch_scene = preload("res://Boss/Bayangan/punch_ground.tscn")
@onready var tangan_scene = preload("res://Boss/Bayangan/tangan.tscn")
@onready var healthbar: ProgressBar = $CanvasLayer/Healthbar

var audio_player = AudioStreamPlayer2D.new()
var kena_hit_sound = "res://Assets/Sound/MONSTER BAYANG/boss kena hit var.mp3"
var proyektil_tangan_sound = "res://Assets/Sound/MONSTER BAYANG/proyektil tangan bayang.mp3"
var dead_sound = "res://Assets/Sound/MONSTER BAYANG/revisi boss bayang mati.mp3"
var tangan_langit_sound = "res://Assets/Sound/MONSTER BAYANG/tangan gede dari langit ke tanah var 1.mp3"

var isDead: bool = false
var canTongkat: bool = false
var canTangan:bool = false

var current_state: BossState = BossState.Walking
var state_change_timer: float = 0.0
var SPEED = 12000
var startingHealth = 45
var direction = Vector2()
var random_move_time = 1 # Time in seconds to pick a new random direction
var move_timer = 0.0

func _ready() -> void:
	healthbar.init_health(startingHealth)

func change_state(new_state: BossState) -> void:
	current_state = new_state
	
# Count down the timers and transition states when appropriate
func _physics_process(delta: float) -> void:
	if freeze_manager.check_if_frozen():
		return
	
	if bossHealth.is_dead():
		change_state(BossState.Dead)
	
	if is_on_wall():
		move_timer = 0.0
	move_timer -= delta
	
	if move_timer <= 0.0:
		var dir_to_player = global_position - player.global_position  # Direction from enemy to player
		var random_angle = randf_range(0, 2 * PI)  # Pick a random angle
		direction = dir_to_player.rotated(random_angle).normalized()  # Move away from player with random variation
		move_timer = random_move_time
	print(current_state)
	velocity = direction * SPEED * delta
	if velocity.x > 0 and isDead == false:
		animated_sprite_2d.flip_h = false
	elif velocity.x < 0 and isDead == false:
		animated_sprite_2d.flip_h = true
	match current_state:
		BossState.Walking:
			animated_sprite_2d.play('idle')
			if canTongkat:
				change_state(BossState.Tongkat)
			elif canTangan:
				change_state(BossState.Tangan)
		BossState.Dead:
			if not Global.is_boss_bayangan_defeated:
				Global.is_boss_bayangan_defeated = true
			
			if isDead == false:
				isDead = true
				animated_sprite_2d.play("dead")
				f_visible_on()
				play_sound(load(dead_sound))
				velocity = Vector2.ZERO
		BossState.Tongkat:
			velocity = Vector2.ZERO
			if canTongkat:
				animated_sprite_2d.play("tongkat")
		BossState.Tangan:
			velocity = Vector2.ZERO
			if canTangan:
				spawn_tangan()
				$TimerTangan.start()
				$TimerCanTangan.start()
				canTangan = false
		
	if isDead == false:   
		move_and_slide()
		
func take_damage(damage : int):
	flash_animation.play("flash")
	play_sound(load(kena_hit_sound))
	bossHealth.health = clamp(bossHealth.health - damage, 0, bossHealth.max_health)
	if bossHealth.health > 0:
		healthbar.health = bossHealth.health
	print("Health = " + str(bossHealth.health))		

func f_visible_on():
	player.press_f_label.visible = true

func crack_ground():
	var crack = crack_scene.instantiate()
	play_sound(load("res://Assets/Sound/SFX PLAYER-HERO/newesrt ground stomp.mp3"))
	get_parent().add_child(crack)
	crack.position = position
	crack.animation_player.play("crack")

func punch_ground():
	var punch = punch_scene.instantiate()
	play_sound(load(tangan_langit_sound))
	get_parent().add_child(punch)
	punch.position.x = player.position.x
	punch.position.y = player.position.y + -70
	punch.animation_player.play("punchground")

func spawn_tangan():
	var tangan = tangan_scene.instantiate()  
	play_sound(load(proyektil_tangan_sound))
	get_parent().add_child(tangan)
	if animated_sprite_2d.flip_h == true:
		tangan.animation_player.flip_h = true
		tangan.position.x = position.x + 40
	else:
		tangan.position.x = position.x - 20
	tangan.position.y = position.y - 30
	tangan.animation_player.play("tangan")
	var dir_to_player = player.position - position 
	tangan.direction = dir_to_player.normalized()

func play_sound(sound : AudioStream):
	audio_player.stream = sound
	audio_player.max_distance = 10000
	audio_player.attenuation = 0
	get_tree().current_scene.add_child(audio_player)
	audio_player.play()

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "tongkat":
		canTongkat = false
		$TimerCanTongkat.start()
		if position.distance_to(player.position) > 200:
			punch_ground()
		else:
			crack_ground()
			
		change_state(BossState.Walking)
		
	if animated_sprite_2d.animation == "dead":
		queue_free()
func _on_timer_can_tongkat_timeout() -> void:
	canTongkat = true

func _on_timer_can_tangan_timeout() -> void:
	canTangan = true

func _on_timer_tangan_timeout() -> void:
	change_state(BossState.Walking)
