extends CanvasLayer

@onready var score_label: Label = $Score
var notice_time: float = 0.0

@onready var objective_label: Label = $Objective
@onready var message_label: Label = $Message

func update_stats(score: int, coins: int, time_left: float, minimum_score: int) -> void:
	var seconds_left = maxi(0, ceili(time_left))
	var minutes: int = seconds_left / 60
	var seconds: int = seconds_left % 60
	score_label.text = "PONTOS %06d   MOEDAS %02d   TEMPO %02d:%02d" % [score, coins, minutes, seconds]

	objective_label.visible = minimum_score > 0
	if minimum_score > 0:
		objective_label.text = "META %d  |  FALTAM %d" % [minimum_score, maxi(0, minimum_score - score)]

func show_completion(score: int) -> void:
	notice_time = 0.0
	message_label.text = "FASE CONCLUÍDA!\nPontos: %d\nR para jogar novamente" % score

func show_timeout() -> void:
	notice_time = 0.0
	message_label.text = "TEMPO ESGOTADO!
Tentando novamente..."

func show_score_required(missing_points: int) -> void:
	notice_time = 3.0
	message_label.text = "FALTAM %d PONTOS!\nColete moedas ou\nderrote inimigos." % missing_points

func _process(delta: float) -> void:
	if notice_time > 0:
		notice_time = maxf(0, notice_time - delta)
		if notice_time == 0:
			message_label.text = ""
