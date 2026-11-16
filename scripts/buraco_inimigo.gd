extends Area2D

# Aqui você vai arrastar a cena do seu Inimigo (Inimigo.tscn) lá no Inspector
@export var cena_inimigo: PackedScene

# Garante que esse buraco só possa ser cavado uma única vez
var ja_foi_cavado: bool = false

func _ready():
	# Avisa o código sempre que algum corpo entrar ou sair de cima do buraco
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# Quando a Mel pisa em cima do buraco:
func _on_body_entered(body):
	if body.has_method("definir_buraco_atual"):
		body.definir_buraco_atual(self)

# Quando a Mel sai de cima do buraco:
func _on_body_exited(body):
	if body.has_method("definir_buraco_atual"):
		body.definir_buraco_atual(null)

# O Player chama essa função exatamente no milissegundo em que a animação "cavando" termina
func revelar_conteudo():
	if ja_foi_cavado:
		return
		
	ja_foi_cavado = true
	
	# Escurece o montinho de terra para indicar visualmente que o buraco já foi aberto
	$Sprite2D.modulate = Color(0.45, 0.45, 0.45)
	
	# Cria o inimigo e faz ele pular de dentro do buraco
	if cena_inimigo != null:
		var inimigo = cena_inimigo.instantiate()
		
		# ADICIONA UM PEQUENO DESLOCAMENTO AO NASCER:
		# Joga o inimigo ligeiramente para o lado para ele não nascer dentro da Mel parada
		var desvio_aleatorio = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		inimigo.global_position = global_position + desvio_aleatorio
		
		get_tree().current_scene.add_child(inimigo)
		
		# Chama a animação/efeito de pulo que está no script do Inimigo
		if inimigo.has_method("surgir_do_buraco"):
			inimigo.surgir_do_buraco()
