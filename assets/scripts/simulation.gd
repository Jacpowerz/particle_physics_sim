@tool
extends Node2D

@onready var particle_object = $Particle
@onready var simulation_node = $"."

# Constant settings --> I dont even rlly know why i made the naming conventions different than below
#sorry future me 
@export var DEFAULT_GRAVITY = 9.8
@export var COLLISION_DAMPING = .85
const SPEED_NORAMILZER = 10
const COLLISION_COOLDOWN = 3
const BOUNCE_LIMIT = 20

# settings --> --> I dont even rlly know why i made the naming conventions different than above
var entireScreen = Rect2(0,0,1000,600)
var boundingBoxArea = Rect2(100,100,800,400)
@export var boundingBoxBorderWeight = 5
@export var number_of_particles = 100
@export var particleRadius = 1 # Has to be >= 1
var gap_distance = 5

# part of simulation
var particles : Array
var gravity = DEFAULT_GRAVITY
var time = 0
var doing_reset : bool = false
	
func _ready():
	#Initilize particles
	initlializeParticles()

func initlializeParticles():
	
	for i in range(number_of_particles):
		var particle = particle_object.duplicate()
		var otherParticlesOffset = number_of_particles - i*(particleRadius*2 + gap_distance) + number_of_particles*particleRadius
		
		particle.coords = Vector2(otherParticlesOffset + boundingBoxArea.position.x+boundingBoxArea.size.x / 2, 
								boundingBoxArea.position.x+boundingBoxArea.size.y / 2)
		particle.particleRadius = particleRadius
		simulation_node.add_child(particle)
		particle.add_to_group("Particles")
		particle.velocity = Vector2(20,20)
	particles = get_tree().get_nodes_in_group("Particles")
	particles.remove_at(0)
	
	
func _physics_process(delta):
	# use as update function
	if !doing_reset:
	
		time += delta
		
		for p in particles:
			
			p.collisionCooldown -= delta
			
			if p.collisionCooldown == 0:
				resolveCollisions(p, delta)
				
			p.velocity += Vector2.DOWN * gravity * delta
			p.coords += p.velocity * delta * SPEED_NORAMILZER
			
		queue_redraw()
	else:
		pass
func _draw():

	draw_rect(boundingBoxArea, Color.SANDY_BROWN, false, boundingBoxBorderWeight)
	
	for p in particles:
		draw_circle(p.coords, p.particleRadius, p.color)

func resolveCollisions(p : Node2D, delta):
	
	#Bounding Box Collisions
	
	var boundingBoxXMinLimit = boundingBoxArea.position.x
	var boundingBoxYMinLimit = boundingBoxArea.position.y
	var boundingBoxXArea = boundingBoxArea.size.x
	var boundingBoxYArea = boundingBoxArea.size.y
		
	if not (boundingBoxXMinLimit+boundingBoxBorderWeight/2 <= p.coords.x-p.particleRadius 
		and p.coords.x+p.particleRadius <= boundingBoxArea.end.x - boundingBoxBorderWeight/2):
		p.velocity.x *= -1 * COLLISION_DAMPING
		p.collisions += 1
		p.collisionCooldown = COLLISION_COOLDOWN
	elif not (boundingBoxYMinLimit+boundingBoxBorderWeight/2 <= p.coords.y-p.particleRadius 
		and p.coords.y+p.particleRadius <= boundingBoxArea.end.y - boundingBoxBorderWeight/2):
			p.velocity.y *= -1 * COLLISION_DAMPING
			p.collisions += 1
			p.collisionCooldown = COLLISION_COOLDOWN
	
	if p.collisions / delta > 50:
		p.collisions = 0
		gravity = 0
	else:
		gravity = DEFAULT_GRAVITY
	
	# Inter-particle Collisions
	
	for particle2 in particles:
		if p != particle2:
			var pos_diff = sqrt((p.coords.x - particle2.coords.x)**2 + (p.coords.y - particle2.coords.y)**2)
			if pos_diff < particleRadius * 2:
				p.velocity += Vector2(pos_diff / 2, pos_diff / 2)
				p.velocity *= -1
				
				particle2.velocity += Vector2(pos_diff / 2, pos_diff / 2)
				particle2.velocity *= -1
				
func reset():
	doing_reset = true
	
	for p in particles:
		delete_particle(p)
	queue_redraw()
	initlializeParticles()
	doing_reset = false
	time = 0

func delete_particle(p):
	
	p.remove_from_group("Particles")
	p.queue_free()
	
func _on_button_pressed():
	reset()
