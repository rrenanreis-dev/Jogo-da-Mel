extends CharacterBody2D

@export var speed: float = 200.0
@onready var animated_sprite = $AnimatedSprite2D

var esta_cavando: bool = false
var buraco_atual = null

# === SISTEMA DE OSSOS ===
var ossos_coletados: int = 0
var total_ossos: int = 3

# === SISTEMA DE VIDA E DANO ===
@export var vida_maxima: int = 3
@onready var vida_atual: int = vida_maxima

@export var label_vida_path: NodePath
var label_vida: Label

var esta_levando_dano: bool = false
var invencivel: bool = false

func _ready():
	if label_vida_path:
		label_vida = get_node(label_vida_path)
	else:
		label_vida = get_tree().get_first_node_in_group("hud_vida")
		
	atualizar_hud_vida()
	atualizar_hud_ossos()

func _physics_process(delta):
	if esta_cavando:
		return

	if esta_levando_dano:
		move_and_slide()
		return

	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()
	
	if direction != Vector2.ZERO:
		animated_sprite.play()
		
		if abs(direction.y) > abs(direction.x):
			if direction.y < 0:
				animated_sprite.animation = "cima"
				animated_sprite.flip_h = false
			else:
				animated_sprite.animation = "baixo"
				animated_sprite.flip_h = false
		else:
			animated_sprite.animation = "lado"
			animated_sprite.flip_h = (direction.x < 0)
	else:
		animated_sprite.stop()

	if Input.is_action_just_pressed("ui_accept"):
		if buraco_atual != null and not buraco_atual.ja_foi_cavado:
			iniciar_cavar()

func definir_buraco_atual(buraco):
	buraco_atual = buraco

func iniciar_cavar():
	esta_cavando = true
	velocity = Vector2.ZERO
	animated_sprite.play("cavando")
	
	if not animated_sprite.is_connected("animation_finished", _on_animacao_cavar_terminou):
		animated_sprite.connect("animation_finished", _on_animacao_cavar_terminou)

func _on_animacao_cavar_terminou():
	if animated_sprite.is_connected("animation_finished", _on_animacao_cavar_terminou):
		animated_sprite.disconnect("animation_finished", _on_animacao_cavar_terminou)
	
	esta_cavando = false
	animated_sprite.animation = "baixo"
	
	if buraco_atual != null:
		# Revela o conteúdo (seja osso, inimigo ou buraco vazio que chamará a reação triste)
		buraco_atual.revelar_conteudo()
		# (O salto evasivo foi retirado daqui para ela não ser empurrada no buraco vazio)

func fazer_salto_evasivo():
	esta_levando_dano = true
	
	var direcao_fuga = Vector2(0, 1)
	if buraco_atual != null:
		direcao_fuga = (global_position - buraco_atual.global_position).normalized()
		if direcao_fuga == Vector2.ZERO:
			direcao_fuga = Vector2(0, 1)
			
	var tween_salto = create_tween()
	var alvo_pos = global_position + (direcao_fuga * 40.0)
	tween_salto.tween_property(self, "global_position", alvo_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	await tween_salto.finished
	esta_levando_dano = false

# === REAÇÃO AO BURACO VAZIO (SEM NADA) ===
func reagir_buraco_vazio():
	esta_levando_dano = true # Congela os controles momentaneamente
	velocity = Vector2.ZERO
	
	# Toca a animação triste/desapontada com as linhas de choque/derrota estilo anime
	if animated_sprite.sprite_frames.has_animation("triste"):
		animated_sprite.play("triste")
	elif animated_sprite.sprite_frames.has_animation("desapontada"):
		animated_sprite.play("desapontada")
	else:
		animated_sprite.play("baixo")
		
	print("Mel cavou e não achou nada... que decepção!")
	
	# Tempo em que ela fica congelada com a carinha triste (0.8 segundos) sem sair do lugar
	await get_tree().create_timer(0.8).timeout
	
	esta_levando_dano = false
	animated_sprite.animation = "baixo"

# === COLETAR OSSO E ATUALIZAR HUD ===
func coletar_osso():
	if ossos_coletados < total_ossos:
		ossos_coletados += 1
		print("Osso coletado! Total: ", ossos_coletados, "/", total_ossos)
		atualizar_hud_ossos()
		
		if ossos_coletados >= total_ossos:
			print("Parabéns! A Mel coletou todos os ossos!")

func atualizar_hud_ossos():
	var hud_ossos = get_tree().get_first_node_in_group("hud_ossos")
	if hud_ossos:
		hud_ossos.text = str(ossos_coletados) + "/" + str(total_ossos)

# === SISTEMA DE DANO E SUSTO ===
func levar_dano(quantidade: int, direcao_empurrao: Vector2):
	if esta_levando_dano or invencivel:
		return 
		
	vida_atual -= quantidade
	print("Mel levou dano! Vida restante: ", vida_atual)
	
	atualizar_hud_vida()
	
	if vida_atual <= 0:
		game_over()
		return

	esta_levando_dano = true
	invencivel = true
	
	if animated_sprite.sprite_frames.has_animation("espantada"):
		animated_sprite.play("espantada")
	else:
		animated_sprite.play("baixo")
		
	piscar_sprite()
	
	var tween_salto = create_tween()
	var alvo_pos = global_position + (direcao_empurrao * 60.0)
	tween_salto.tween_property(self, "global_position", alvo_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	await tween_salto.finished
	esta_levando_dano = false
	
	await get_tree().create_timer(0.4).timeout
	
	var inimigo = get_tree().get_first_node_in_group("inimigo")
	if inimigo and is_instance_valid(inimigo):
		var distancia = global_position.distance_to(inimigo.global_position)
		if distancia < 35:
			var direcao_escape = (global_position - inimigo.global_position).normalized()
			if direcao_escape == Vector2.ZERO:
				direcao_escape = Vector2(0, 1)
			global_position += direcao_escape * 30.0
			
	invencivel = false

func atualizar_hud_vida():
	var hud = get_tree().get_first_node_in_group("hud_vida")
	if hud:
		hud.text = "Vidas: " + str(vida_atual)
	elif label_vida:
		label_vida.text = "Vidas: " + str(vida_atual)

func piscar_sprite():
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(animated_sprite, "modulate", Color(1, 0.3, 0.3, 0.4), 0.05)
		tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.05)

func game_over():
	print("GAME OVER! A Mel perdeu todas as vidas.")
	get_tree().reload_current_scene()
