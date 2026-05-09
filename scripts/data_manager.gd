extends Node
class_name DataManager

# JSON 데이터 로딩을 담당한다.
var students: Array = []
var colors: Array = []

func load_all() -> void:
	students = _load_json("res://data/students.json")
	colors = _load_json("res://data/colors.json")

func _load_json(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("데이터 파일을 찾을 수 없습니다: %s" % path)
		return []

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("데이터 파일을 열 수 없습니다: %s" % path)
		return []

	var json_text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(json_text)
	if not parsed is Array:
		push_error("데이터 형식 오류: %s" % path)
		return []

	return parsed as Array
