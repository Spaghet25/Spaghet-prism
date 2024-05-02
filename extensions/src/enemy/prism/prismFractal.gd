extends StaticBody2D

var args := {
	markedPlayer = null,
	colorVar = 0
}

var targetPlayer:Node2D
var targetParent:Node2D

var prism:RigidBody2D

var colorName := "red"
var colorValue := Color(1, 1, 1)
var coins := 2

@onready var enemy = $Enemy
@onready var area_2D = $Area2D
@onready var detectShape = $Area2D/detectShape
@onready var collideShape = $collideShape
@onready var sprite = $Sprite

var Bullet = preload("res://src/element/enemy_bullet/enemy_bullet.tscn")

var delta := 0.0
var time := 0.0

var frequency := 1.0
var amplitude := 10

var rng := RandomNumberGenerator.new()
var fracBob := 0.0

var fracFloat := Vector2.ZERO
var fracPos := Vector2.ZERO

var points:Array[Vector2] = []

var knockbackVel := Vector2.ZERO
var bellowKnockback := Vector2.ZERO

var maxHealth:=20

var killed:bool = false

var shootTimer :float= 2.0

var frozen := false
var drainSpeed := 1.0

var window:Window
var windowCamera:Camera2D

func _ready():
	if args.markedPlayer:
		targetPlayer = args.markedPlayer
		targetParent = args.point
		prism = args.prism
	else:
		targetPlayer = Global.player
		
	match args.colorVar:
		0:
			sprite.texture = preload("res://mods-unpacked/Spaghet-prism/extensions/src/enemy/prism/prismVariants/red.png")
			colorName = "red"
			colorValue = Color(1, 0, 0)
		1:
			sprite.texture = preload("res://mods-unpacked/Spaghet-prism/extensions/src/enemy/prism/prismVariants/blue.png")
			colorName = "blue"
			colorValue = Color(0, 0.14901961386204, 1)
		2:
			sprite.texture = preload("res://mods-unpacked/Spaghet-prism/extensions/src/enemy/prism/prismVariants/green.png")
			colorName = "green"
			colorValue = Color(0.32941177487373, 1, 0)
		3:
			sprite.texture = preload("res://mods-unpacked/Spaghet-prism/extensions/src/enemy/prism/prismVariants/orange.png")
			colorName = "orange"
			colorValue = Color(1, 0.41568627953529, 0)
		4:
			sprite.texture = preload("res://mods-unpacked/Spaghet-prism/extensions/src/enemy/prism/prismVariants/pink.png")
			colorName = "pink"
			colorValue = Color(1, 0.63137257099152, 0.91764706373215)
		5:
			sprite.texture = preload("res://mods-unpacked/Spaghet-prism/extensions/src/enemy/prism/prismVariants/purple.png")
			colorName = "purple"
			colorValue = Color(0.69803923368454, 0, 1)
		6:
			sprite.texture = preload("res://mods-unpacked/Spaghet-prism/extensions/src/enemy/prism/prismVariants/cyan.png")
			colorName = "cyan"
			colorValue = Color(0, 1, 1)
		7:
			sprite.texture = preload("res://mods-unpacked/Spaghet-prism/extensions/src/enemy/prism/prismVariants/turquoise.png")
			colorName = "turquoise"
			colorValue = Color(0, 1, 0.56470590829849)
		8:
			sprite.texture = preload("res://mods-unpacked/Spaghet-prism/extensions/src/enemy/prism/prismVariants/yellow.png")
			colorName = "yellow"
			colorValue = Color(1, 0.84705883264542, 0)
	
	fracBob = rng.randf_range(0, 9)
	
	maxHealth = 20 + lerp(0.0, 100.0, Stats.stats.totalBossesKilled / 6.0)
	enemy.health = maxHealth
	
	var windowSize = Vector2(135, 150) 
	window = Window.new()
	Game.registerWindow(window, colorName)
	window.size = windowSize
	window.position = position - window.size / 2.0
	add_child(window)
	windowCamera = Camera2D.new()
	windowCamera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	windowCamera.position = window.position
	window.unresizable = true
	window.always_on_top = false
	window.add_child(windowCamera)
	
	enemy.spawn()
func _physics_process(delta):
	delta *= Global.timescale
	self.delta = delta

func _process(delta):
	delta *= Global.timescale
	updateWindows()
	
	position = targetParent.global_position
	
	time += delta * frequency
	fracFloat.y = sin(time * 2.0 + TAU * fracBob/5.0) * amplitude
	fracPos.y = 0 + fracFloat.y
	
	area_2D.position = fracPos
	sprite.position = fracPos
	collideShape.position = fracPos

func updateWindows():
	if(window.mode & Window.MODE_MINIMIZED > 0):
		window.mode &= ~Window.MODE_MINIMIZED
	Game.setWindowRect(window, Rect2(position - window.size / 2.0, window.size), true, true)
	windowCamera.position = window.position

func kill(soft := false):
	Utils.spawn(preload("res://mods-unpacked/Spaghet-prism/extensions/src/enemy/prism/bigLaser.tscn"), prism.position, Global.main.game_area, {targetPlayer = targetPlayer, colorValue = colorValue, prism = prism})
	if not soft:
		Audio.play(preload("res://src/sounds/enemyDie.ogg"), 0.8, 1.2)
	if Global.options.pEnemyPop:
		Utils.spawn(preload("res://src/particle/enemy_pop/enemy_pop2.tscn"), position, get_parent(), {color = Color("8cc63f")})
	Stats.stats.totalEnemiesKilled += 1
	Stats.metaStats.totalEnemiesKilled += 1
	if not killed:
		queue_free()
	killed = true

func knockback(from:Vector2, power := 1.0, reset := false):
	var new = power*2000.0 * (position - from).normalized()
	knockbackVel = new if reset else knockbackVel + new
	enemy.flash()
