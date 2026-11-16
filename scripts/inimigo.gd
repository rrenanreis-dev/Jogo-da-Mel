extends CharacterBody2D

@export var velocidade: float = 110.0
@export var dano: int = 1
var player: Node2D = null

var esta_acordando: bool = false
var esta_recuando: bool = false
var direcao_recuo: Vector2 = Vector2.ZERO

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	if has_node("AreaDano"):
		$AreaDano.body_entered.connect(_on_area_dano_body_entered)

func _physics_process(delta):
	if esta_acordando:
		return

	if player != null and is_instance_valid(player):
		if esta_recuando:
			global_position += direcao_recuo * (velocidade * 1.5) * delta
			return

		var distancia = global_position.distance_to(player.global_position)
		
		if distancia > 22:
			var direcao = global_position.direction_to(player.global_position)
			velocity = direcao * velocidade
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			verificar_dano_continuo()

func surgir_do_buraco():
	esta_acordando = true
	var posicao_original = global_position
	global_position = posicao_original - Vector2(0, 40)
	scale = Vector2(0.3, 0.3)
	modulate.a = 0.0 
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", posicao_original, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	await tween.finished
	esta_acordando = false

func _on_area_dano_body_entered(body):
	if esta_acordando or esta_recuando:
		return
		
	if body.is_in_group("player"):
		aplicar_dano_e_recuo(body)

func verificar_dano_continuo():
	if esta_acordando or esta_recuando:
		return
		
	if has_node("AreaDano"):
		for body in $AreaDano.get_overlapping_bodies():
			if body.is_in_group("player"):
				aplicar_dano_e_recuo(body)
				break

func aplicar_dano_e_recuo(body):
	var direcao_empurrao = (body.global_position - global_position).normalized()
	if direcao_empurrao == Vector2.ZERO:
		direcao_empurrao = Vector2(0, -1)
		
	if body.has_method("levar_dano"):
		body.levar_dano(dano, direcao_empurrao)
		
	iniciar_recuo(direcao_empurrao)

func iniciar_recuo(direcao_player):
	esta_recuando = true
	direcao_recuo = -direcao_player
	
	# Proteção segura contra null no Game Over
	var arvore = get_tree()
	if arvore:
		var timer = arvore.create_timer(0.15)
		if timer:
			await timer.timeout
			
	esta_recuando = false
