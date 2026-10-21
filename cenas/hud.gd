extends CanvasLayer

@onready var score_label: Label = $Score
var notice_time: float = 0.0

@onready var objective_label: Label = $Objective
@onready var message_label: Label = $Message

func _ready() -> void:
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func update_stats(score: int, coins: int, time_left: float, minimum_score: int) -> void:
	var seconds_left = maxi(0, ceili(time_left))
	var minutes: int = seconds_left / 60
	var seconds: int = seconds_left % 60
	score_label.text = "PONTOS %06d   MOEDAS %02d   TEMPO %02d:%02d" % [score, coins, minutes, seconds]

	objective_label.text = "META %d  |  FALTAM %d" % [minimum_score, maxi(0, minimum_score - score)]

func show_completion(score: int, has_next_level: bool = false) -> void:
	notice_time = 0.0
	if has_next_level:
		message_label.text = "FASE CONCLUÍDA!\nPontos: %d\nENTER: próxima fase\nESC: Menu" % score
	else:
		message_label.text = "FASE CONCLUÍDA!\nPontos: %d\nR: jogar novamente\nESC: Menu" % score

func show_start_prompt() -> void:
	score_label.hide()
	objective_label.hide()

func show_game_hud() -> void:
	score_label.show()
	objective_label.show()
	message_label.text = ""

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
