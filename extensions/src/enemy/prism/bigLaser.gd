extends StaticBody2D

var args := {
	targetPlayer:Node2D,
	colorValue:Color.WHITE,
	prism:Node2D
}

@onready var laser_body = self
@onready var laser_shape = $laserShape

var laserTimer := -1.0
var laserStage := 0
var laserAngle := Vector2.ZERO
var laserCollisionTimer := 0.0

var blinkBuffer := true

var difficultyScale := 0.0

var targetPlayer:Node2D
var colorValue = Color.WHITE
var prism:Node2D

func _ready():
	targetPlayer = args.targetPlayer
	colorValue = args.colorValue
	prism = args.prism
	
	difficultyScale = Global.difficultyScale
	
	laserAngle = (targetPlayer.global_position - global_position).normalized()

func _process(delta):
	delta *= Global.timescale
	queue_redraw()
	
	if is_instance_valid(prism):
		position = prism.position
	else:
		queue_free()
	
	difficultyScale += 0.04 * delta
	
	laserTimer += 2 * delta
	if laserStage == 0:
		if laserTimer > 0.0:
			laserStage = 1
			blinkBuffer = true
	elif laserStage == 1:
		if laserTimer > 0.0:
			laserTimer = 0.0
			laserStage = 2
			targetPlayer = Game.randomPlayer()
	elif laserStage == 2:
		if laserTimer > 2.0:
			laserTimer = 0.0
			laserStage = 3
				
			laser_shape.shape.size = Vector2(3000.0, 250.0)
			laser_shape.rotation = laserAngle.angle()
			var dist = 3000.0/2.0
			laser_shape.position = dist * laserAngle
			laserCollisionTimer = 0.1
			Audio.play(preload("res://src/sounds/laser.ogg"), 0.8, 1.2)
	elif laserStage == 3:
		if laserTimer > 0.5:
			laserTimer = 0.0
			laserStage = 0
			
	if laserCollisionTimer > 0.0:
		laserCollisionTimer -= 0.4 * delta
		if laserCollisionTimer <= 0.0:
			laser_shape.shape.size = Vector2(2.0, 2.0)
			laser_shape.position = Vector2.ZERO
			queue_free()

func _draw():
	if laserStage == 2:
		var amount = pow(min(1, laserTimer / 0.5), 3.0)
		if laserTimer > 1.4 and int(laserTimer * 20.0) % 2 == 0:
			if blinkBuffer:
				blinkBuffer = false
				Audio.play(preload("res://src/sounds/laserBlink.ogg"))
			pass
		else:
			blinkBuffer = true
			draw_dashed_line(64.0 * laserAngle, 3000.0 * laserAngle, Color(1, 0.278, 0.396, amount * 0.5), 8.0, 8.0)
	elif laserStage == 3:
		var amount = pow(min(1, laserTimer / 0.3), 3.0)
		var iAmount = 1.0 - amount
		
		draw_circle(64.0 * laserAngle, 0.5 * iAmount * 250.0, colorValue)
		draw_line(64.0 * laserAngle, 3000.0 * laserAngle, colorValue, iAmount * 250.0)
		
		draw_circle(64.0 * laserAngle, 0.5 * iAmount * 175.0, Color.WHITE)
		draw_line(64.0 * laserAngle, 2968.0 * laserAngle, Color.WHITE, iAmount * 175.0)
