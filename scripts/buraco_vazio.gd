extends Area2D

var ja_foi_cavado: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.has_method("definir_buraco_atual"):
		body.definir_buraco_atual(self)

func _on_body_exited(body):
	if body.has_method("definir_buraco_atual"):
		body.definir_buraco_atual(null)

# Chamado pela Mel quando termina de cavar este buraco
func revelar_conteudo():
	if ja_foi_cavado:
		return
		
	ja_foi_cavado = true
	
	# Deixa a terra do buraco escurecida
	$Sprite2D.modulate = Color(0.45, 0.45, 0.45)
	
	# Procura a Mel e aciona a reação de desapontamento
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("reagir_buraco_vazio"):
		player.reagir_buraco_vazio()
