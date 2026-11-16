extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func pular_do_buraco():
	var posicao_original = global_position
	global_position = posicao_original - Vector2(0, 5)
	scale = Vector2(0.2, 0.2)
	modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", posicao_original - Vector2(0, 25), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.25)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	
	await tween.finished
	
	var tween_queda = create_tween().set_parallel(true)
	tween_queda.tween_property(self, "global_position", posicao_original, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_queda.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	
	await tween_queda.finished

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("coletar_osso"):
			body.coletar_osso()
		queue_free()
