extends CharacterBody2D

class_name Player
@onready var game_over_scene = preload("res://Scenes/game_over.tscn")
@onready var ending_scene = preload("res://Scenes/ending_scene.tscn")
@onready var animated_sprite_2d: AnimationController = $AnimatedSprite2D
@onready var left_collision: CollisionShape2D = $CombatSystem/WeaponHitbox/LeftCollision
@onready var right_collision: CollisionShape2D = $CombatSystem/WeaponHitbox/RightCollision
@onready var body_hitbox_collision: CollisionShape2D = $CombatSystem/BodyHitbox/CollisionShape2D
@onready var playerHealth : HealthSystem = $HealthSystem
@onready var flash_animation = $AnimatedSprite2D/FlashAnimation
@onready var freeze_manager = $"../FreezeManager"
@onready var press_f_label = $PressF
@export var projectile_node : PackedScene

#SFX
var hero_kena_dmg = ["res://Assets/Sound/SFX PLAYER-HERO/hero kena dmg no suara kesakitan.mp3",
					"res://Assets/Sound/SFX PLAYER-HERO/hero kena dmg var 1.mp3",
					"res://Assets/Sound/SFX PLAYER-HERO/hero kena dmg var 2.mp3"]
var trisula_sound = "res://Assets/Sound/SFX PLAYER-HERO/laser hero.mp3"
var dash_sound = "res://Assets/Sound/SFX PLAYER-HERO/new dash.mp3"
var game_over_sound = "res://Assets/Sound/SFX GAME/pop up menu game over.mp3"
var audio_player = AudioStreamPlayer2D.new()

var startingHealth = 5
var DEF_SPEED = 10000
var SPEED = DEF_SPEED
var direction : Vector2
var canDash = true
var dashing = false
var idle = true
var walking = false
var attacking = false
var healing = false
var playDeadAnim = false

func _physics_process(delta: float) -> void:
	if freeze_manager.check_if_frozen():
		return
	if press_f_label.visible and Input.is_action_just_pressed("goback"):
		press_f_label.visible = false
		get_tree().change_scene_to_file("res://Scenes/main.tscn")
	
	if Global.is_boss_air_defeated and Global.is_boss_batu_defeated and Global.is_boss_bayangan_defeated:
		var ending = ending_scene.instantiate()
		$SkillUI.visible = false
		$HealthSystemUI.visible = false
		for i in range(get_tree().current_scene.get_child_count()):
			if get_tree().current_scene.get_child(i).name == "CanvasLayer1":
				get_tree().current_scene.get_child(i).add_child(ending)
				
	if playerHealth.is_dead():
		if playDeadAnim == false:
			animated_sprite_2d.play_die_animation()
			playDeadAnim = true
	else:
		if not dashing:
			direction = Input.get_vector("left", "right", "up", "down").normalized()
			
		if direction: 
			velocity = direction * SPEED * delta
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED * delta)
			velocity.y = move_toward(velocity.y, 0, SPEED * delta)
		
		if not dashing and Input.is_action_just_pressed("dash") and direction != Vector2.ZERO and canDash:
			play_sound(load(dash_sound))
			dashing = true
			canDash = false
			SPEED = SPEED * 8
			animated_sprite_2d.play_dash_animation()
			$TimerDashing.start(0.1)
			$TimerCanDash.start(1)
		
		if healing:
			$HealingEffectAnimation.play("HealingEffect")
		
		if dashing:
			body_hitbox_collision.disabled = true
		else:
			body_hitbox_collision.disabled = false
			
		if velocity != Vector2.ZERO and not attacking:
			if is_on_wall() and velocity.y == 0:
				animated_sprite_2d.play_idle_animation()
			elif (is_on_ceiling() or is_on_floor()) and velocity.x == 0:
				animated_sprite_2d.play_idle_animation()	
			else:
				animated_sprite_2d.play_movement_animation(velocity)
			
		elif velocity == Vector2.ZERO and not attacking:
			animated_sprite_2d.play_idle_animation()
		move_and_slide()

func _process(delta: float) -> void:
	if healing:
		$HealingEffectAnimation.visible = true
		$HealingEffectAnimation.play("HealingEffect")


func _on_timer_dashing_timeout():
	$TimerDashing.stop()
	dashing = false
	SPEED = DEF_SPEED

func _on_timer_can_dash_timeout() -> void:
	$TimerCanDash.stop()
	canDash = true
	

func take_damage(damage : int):
	if playerHealth.is_dead():
		return
	if playerHealth.invulnerable == false:
		var playSound = randi_range(0,2)
		play_sound(load(hero_kena_dmg[playSound]))
		flash_animation.play("flash")
		animated_sprite_2d.play_hurt_animation()
		freeze_manager.apply_freeze()
		if playerHealth.onShield:
			playerHealth.shield -= damage
		else:
			playerHealth.health = clamp(playerHealth.health - damage, 0, playerHealth.max_health)

func _on_left_weapon_sprite_animation_finished() -> void:
	attacking = false
	left_collision.disabled = true
	right_collision.disabled = true
	$CombatSystem/LeftWeaponSprite.visible = false

func _on_right_weapon_sprite_animation_finished() -> void:
	attacking = false
	left_collision.disabled = true
	right_collision.disabled = true
	$CombatSystem/RightWeaponSprite.visible = false

func single_shot(animation_name = "Laser", 	sound = preload("res://Assets/Sound/SFX PLAYER-HERO/laser hero.mp3")):
	var projectile = projectile_node.instantiate()
	
	projectile.play(animation_name)
	play_sound(sound)
	projectile.position = global_position
	projectile.direction = (get_global_mouse_position() - global_position).normalized()
	
	get_tree().current_scene.call_deferred("add_child", projectile)

func play_sound(sound : AudioStream):
	audio_player.stream = sound
	audio_player.attenuation = 0
	audio_player.max_distance = 10000
	get_tree().current_scene.add_child(audio_player)
	audio_player.play()

func active_shield(sound):
	play_sound(sound)
	playerHealth.add_shield()

#func area_shot(animation_name = "GroundCrack"):
	#var projectile = projectile_node.instantiate()
	#
	#projectile.play(animation_name)
	#
	#projectile.position = global_position
	#projectile.direction = (get_global_mouse_position() - global_position).normalized()
	#
	#get_tree().current_scene.call_deferred("add_child", projectile)

func multi_shot(count: int = 3, delay: float = 0.3, animation_name = "Laser", sound = preload("res://Assets/Sound/SFX PLAYER-HERO/laser hero.mp3")):
	for i in range(count):
		single_shot(animation_name, sound)
		await get_tree().create_timer(delay).timeout

func slowed():
	SPEED = DEF_SPEED / 2
	$TimerSlowed.start()
	
func _on_timer_slowed_timeout() -> void:
	SPEED = DEF_SPEED
	
#func angled_shot(angle):
	#var projectile = projectile_node.instantiate()
	#
	#projectile.play("Laser")
	#
	#projectile.position = global_position
	#projectile.direciton = Vector2(cos(angle), sin(angle))
	#
	#get_tree().current_scene.call_deferred("add_child", projectile)
	#
#func radial(count):
	#for i in range(count):
		#angled_shot((float(i) / count) * 2.0 * PI)

func _on_healing_effect_animation_animation_finished() -> void:
	healing = false
	$HealingEffectAnimation.visible = false
	
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "die":
		var game_over = game_over_scene.instantiate()
		$SkillUI.visible = false
		$HealthSystemUI.visible = false
		for i in range(get_tree().current_scene.get_child_count()):
			if get_tree().current_scene.get_child(i).name == "CanvasLayer1":
				get_tree().current_scene.get_child(i).add_child(game_over)

func _on_bgm_finished() -> void:
	$"../BGM".play()
