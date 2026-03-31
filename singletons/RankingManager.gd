extends Node

const API_URL = "https://script.google.com/macros/s/AKfycbwXuKqq0mV2t4dUQQqUZbRajsB0rBR_LQXy6KgRYtKFY_JJLv4GW5cWVI-JtYxzriEc1w/exec"

var ranking_data: Array = []
var http_get: HTTPRequest = null
var http_submit: HTTPRequest = null

signal ranking_loaded(data: Array)
signal score_submitted(success: bool)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	http_get = HTTPRequest.new()
	http_get.request_completed.connect(_on_get_completed)
	add_child(http_get)

	http_submit = HTTPRequest.new()
	http_submit.request_completed.connect(_on_submit_completed)
	add_child(http_submit)

func fetch_ranking() -> void:
	var err = http_get.request(API_URL)
	if err != OK:
		ranking_loaded.emit([])

func submit_score(nombre: String, puntaje: int) -> void:
	var url = API_URL + "?nombre=" + nombre.uri_encode() + "&puntaje=" + str(puntaje)
	print("[RankingManager] Sending: ", url)
	var err = http_submit.request(url)
	if err != OK:
		score_submitted.emit(false)

func _on_get_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json != null:
			ranking_data = json
			ranking_loaded.emit(ranking_data)
			return
	ranking_loaded.emit([])

func _on_submit_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print("[RankingManager] Submit result: ", result, " code: ", response_code)
	print("[RankingManager] Body: ", body.get_string_from_utf8())
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		score_submitted.emit(true)
	else:
		score_submitted.emit(false)
