extends Node
class_name DataManager

var students: Array[Dictionary] = []
var colors: Array[Dictionary] = []
var clues: Array[Dictionary] = []

func load_all() -> void:
	students = _to_dict_array(_load_json("res://data/students.json"))
	colors = _to_dict_array(_load_json("res://data/colors.json"))
	clues = _build_clues()

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("데이터 파일을 찾을 수 없습니다: %s" % path)
		return []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("데이터 파일을 열 수 없습니다: %s" % path)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("JSON 파싱 실패: %s" % path)
		return []
	return parsed

func _to_dict_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item_variant in value:
			var item: Dictionary = item_variant as Dictionary
			result.append(item)
	return result

func _build_clues() -> Array[Dictionary]:
	return [
		{"id":"honor_career_sheet","student_id":"honor_student","day_available":1,"action_type":"inspect_item","area":"honor_student","title":"구겨진 진로 상담지","text":"희망 진로 칸에는 여러 번 지운 흔적이 있었다. 마지막에 남은 글자는 ‘모르겠음’이었다.","color_hints":["blue"]},
		{"id":"honor_wrong_note","student_id":"honor_student","day_available":2,"action_type":"observe","area":"honor_student","title":"너무 깨끗한 오답노트","text":"틀린 문제보다, 틀렸다는 사실을 더 견디기 어려운 사람처럼 보였다.","color_hints":["blue"]},
		{"id":"honor_parent_msg","student_id":"honor_student","day_available":3,"action_type":"talk","area":"honor_student","title":"부모에게서 온 메시지","text":"‘이번에도 잘할 거지?’라는 문장이 잠금화면에 오래 남아 있었다.","color_hints":["yellow","blue"]},
		{"id":"honor_window_face","student_id":"honor_student","day_available":4,"action_type":"observe","area":"window","title":"창문에 비친 얼굴","text":"웃고 있는 얼굴과 창문에 비친 얼굴이 달랐다.","color_hints":["blue"]},
		{"id":"academy_bell_hand","student_id":"academy_child","day_available":1,"action_type":"observe","area":"bell","title":"하차벨 앞의 손","text":"누르려는 듯했지만, 손끝은 매번 그 앞에서 멈췄다.","color_hints":["red"]},
		{"id":"academy_schedule","student_id":"academy_child","day_available":2,"action_type":"inspect_item","area":"academy_child","title":"빈틈없는 학원 시간표","text":"시간표 사이에 작은 글씨가 적혀 있었다. ‘오늘은 안 가면 안 돼?’","color_hints":["gray","red"]},
		{"id":"academy_missed_call","student_id":"academy_child","day_available":3,"action_type":"talk","area":"academy_child","title":"받지 않은 전화","text":"엄마에게서 온 부재중 전화가 세 통이었다.","color_hints":["green"]},
		{"id":"academy_grip","student_id":"academy_child","day_available":4,"action_type":"observe","area":"academy_child","title":"꽉 쥔 손잡이","text":"도망가고 싶은 게 아니라, 버티고 있는 것일지도 모른다.","color_hints":["red"]},
		{"id":"dream_doodles","student_id":"drifting_dreamer","day_available":1,"action_type":"inspect_item","area":"drifting_dreamer","title":"지워진 낙서들","text":"웹툰, 게임, 우주선, 카메라, 아무 의미 없는 선들이 겹쳐 있었다.","color_hints":["purple"]},
		{"id":"dream_search","student_id":"drifting_dreamer","day_available":2,"action_type":"inspect_item","area":"drifting_dreamer","title":"검색 기록","text":"검색창에 ‘꿈이 자주 바뀌면 문제인가요’가 남아 있었다.","color_hints":["green"]},
		{"id":"dream_poster","student_id":"drifting_dreamer","day_available":3,"action_type":"observe","area":"window","title":"접힌 공모전 포스터","text":"제출하지 못한 흔적이 있었다.","color_hints":["purple","blue"]},
		{"id":"dream_keep_drawing","student_id":"drifting_dreamer","day_available":4,"action_type":"talk","area":"drifting_dreamer","title":"지워지지 않은 그림","text":"처음으로, 지우지 않은 그림 하나가 남아 있었다.","color_hints":["green"]}
	]
