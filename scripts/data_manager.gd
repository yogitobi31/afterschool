extends Node
class_name DataManager

# JSON 데이터 로딩을 담당한다.
var students: Array = []
var colors: Array = []

func load_all() -> void:
	students = _load_json("res://data/students.json")
	colors = _load_json("res://data/colors.json")

func _load_json(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("데이터 파일을 열 수 없습니다: %s" % path)
		return []
	var parsed := JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("데이터 형식 오류: %s" % path)
		return []
	return parsed
