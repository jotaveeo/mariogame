extends CanvasLayer

@onready var score_label: Label = $Score
@onready var message_label: Label = $Message

func update_stats(score: int, coins: int, time_left: float) -> void:
	score_label.text = "PONTOS %06d   MOEDAS %02d   TEMPO %03d" % [score, coins, ceili(time_left)]

func show_completion(score: int) -> void:
	message_label.text = "FASE CONCLUÍDA!\nPontos: %d\nR para jogar novamente" % score
