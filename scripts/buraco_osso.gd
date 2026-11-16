extends Area2D

# Arraste a cena do Osso (Osso.tscn) aqui no Inspector
@export var cena_osso: PackedScene

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

# Chamado pela Mel quando termina a animação de cavar
func revelar_conteudo():
	if ja_foi_cavado:
		return
		
	ja_foi_cavado = true
	
	# Escurece a terra do buraco
	$Sprite2D.modulate = Color(0.45, 0.45, 0.45)
	
	# Cria o osso na cena
	if cena_osso != null:
		var osso = cena_osso.instantiate()
		osso.global_position = global_position
		get_tree().current_scene.add_child(osso)
		
		# Faz o osso executar os pulinhos para fora do buraco
		if osso.has_method("pular_do_buraco"):
			osso.pular_do_buraco()
