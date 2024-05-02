extends RigidBody2D

var targetPlayer:Node2D
var coins := 32
@onready var enemy = $Enemy

var Bullet = preload("res://src/element/enemy_bullet/enemy_bullet.tscn")

@onready var collideShape = $collideShape
@onready var detect_shape = $Area2D/detectShape
@onready var area_2D = $Area2D

@onready var areaS = $ringSmall/AreaS
@onready var areaL = $ringLarge/AreaL

@onready var rotPivS:Node2D = $ringSmall/rotPivSmall
@onready var rotPivL:Node2D = $ringLarge/rotPivLarge

var window:Window
var windowCamera:Camera2D

var color:Color
var radius = 60

var targetTimer := 0.0
var targetPos := Vector2.ZERO

var springVel := Vector2.ZERO

var delta := 0.0

var points:Array[Vector2] = []

@onready var sprite = $Sprite

var time := 0.0

var frequency := 0.0
var amplitude := 10.0

var prismFloat := Vector2.ZERO
var prismPos := Vector2.ZERO

var shootTimer := 2.0
var shootAngle := 0.0
var playerShootTimer := 0.0

var difficultyScale := 0.0

var cooldown := 8.0

var angle := Vector2.ZERO

var speed := 1.0
var speed2 := 1.0

var dist := 550.0

var knockbackVel := Vector2.ZERO
var knockbackTimer := 0.0
var bellowKnockback := Vector2.ZERO
var lastVel := Vector2.ZERO

var spinFactor := 1
var spinFast := false

var isTP := false

var maxHealth := 50
var healthTarget := 32

var scaleAmount := 1.0
var alphaAmount := 1.0

var blinkBuffer := true
var frozen := false

var drainSpeed := 1.0

var fractals:Array[StaticBody2D] = []
var lastAlive := false

func _ready():
	targetPlayer = Game.randomPlayer()
	
	for i in targetPlayer.get_children():
		if i.get_name() == "Melee":
			dist = 375.0
	
	var pos = Game.randomSpawnLocation(Vector2(300, 300).x, 300.0)
	position = pos
	#color = Color(1, 0.278, 0.396)
	enemy.health = maxHealth
	#maxHealth = 48 + lerp(0.0, 100.0, Stats.stats.totalBossesKilled / 6.0)
	#healthTarget = enemy.health - maxHealth/4.0
	#difficultyScale = Global.difficultyScale
	var windowSize = Vector2(125, 125)
	window = Window.new()
	Game.registerWindow(window, "prism")
	window.size = windowSize
	window.position = position - window.size / 2.0
	add_child(window)
	windowCamera = Camera2D.new()
	windowCamera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	windowCamera.position = window.position
	window.unresizable = true
	window.always_on_top = Global.options.alwaysOnTop
	window.add_child(windowCamera)
	enemy.spawn()
	spawnFractals()

func spawnFractals():
	var count = 0
	for i in rotPivS.get_children():
		fractals.append(Utils.spawn(load("res://mods-unpacked/Spaghet-prism/extensions/src/enemy/prism/prismFractal.tscn"), i.position, Global.main.game_area, {
			markedPlayer = targetPlayer,
			prism = self,
			point = i,
			colorVar = count
		}))
		count += 1
		
	for i in rotPivL.get_children():
		fractals.append(Utils.spawn(load("res://mods-unpacked/Spaghet-prism/extensions/src/enemy/prism/prismFractal.tscn"), i.position, Global.main.game_area, {
			markedPlayer = targetPlayer,
			prism = self,
			point = i,
			colorVar = count
		}))
		count += 1

func updateWindows():
	if(window.mode & Window.MODE_MINIMIZED > 0):
		window.mode &= ~Window.MODE_MINIMIZED
	Game.setWindowRect(window, Rect2(position - window.size / 2.0, window.size), true, true)
	windowCamera.position = window.position

func _physics_process(delta):
	rotPivS.rotation += delta * 0.7 * spinFactor
	rotPivL.rotation -= delta * 0.6 * spinFactor

func _integrate_forces(state):
	angle = (targetPlayer.position - position).normalized()
	
	if lastAlive:
		speed = 10.0 * min(100, position.distance_to(targetPlayer.position))
	else:
		speed = 10.0 * min(100, position.distance_to(targetPlayer.position) - dist)
	speed *= pow((min(1.0, max(0.0, 3.0 - 1.0) / 8.0)), 2.0)
	
	var vel = angle * speed
	
	linear_velocity = vel
	
	if cooldown <= 0.0:
		linear_velocity *= 10.0
		cooldown = 8.0
	
	linear_velocity *= Global.timescale
	angular_velocity *= Global.timescale
		
	lastVel = linear_velocity

func _body_entered_small(body):
	if not lastAlive:
		isTP = true

func _body_exited_small(body):
	pass
	
func _body_entered_large(body):
	spinFast = true
	
func _body_exited_large(body):
	spinFast = false

func _process(delta):
	delta *= Global.timescale
	
	time += delta * frequency
	prismFloat.y = sin(time * 2.0 + TAU/5.0) * amplitude
	prismPos.y = 0 + prismFloat.y
	
	area_2D.position = prismPos
	sprite.position = prismPos
	collideShape.position = prismPos
	
	if isTP:
		position = Game.randomSpawnLocation(400.0, 300.0)
		isTP = false
	
	if spinFast:
		spinFactor = 5.0
	else:
		spinFactor = 1.0
	
	for f in fractals:
		if is_instance_valid(f):
			break
		lastAlive = true
		
	if lastAlive:
		cooldown -= 1.0 * delta
	
	updateWindows()
	queue_redraw()
	
	#var rect = Game.screenRect.grow(-40)
	#position = position.clamp(rect.position, rect.end)

func kill(soft := false):
	for i in fractals:
		if is_instance_valid(i):
			print("not null kill me")
			i.kill(true)
	if not soft:
		Audio.play(preload("res://src/sounds/bossDie.ogg"), 0.8, 1.2)
	for i in 4:
		Utils.spawn(preload("res://src/particle/enemy_pop/enemy_pop.tscn"), position, get_parent(), {color = Color(0.1, 0.769, 1)})
	Utils.spawn(preload("res://src/element/power_token/powerToken.tscn"), global_position, Global.main.coin_area)
	Stats.stats.totalBossesKilled += 1
	Stats.metaStats.totalBossesKilled += 1
	Stats.metaStats.totalSpikersKilled += 1
	Global.main.killedBoss()
	queue_free()
	
func knockback(from:Vector2, power := 1.0, reset := false):
	var new = power*2000.0 * (position - from).normalized()
	knockbackVel = new if reset else knockbackVel + new
	enemy.flash()
