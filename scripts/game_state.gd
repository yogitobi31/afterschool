extends Node
class_name GameState

# 3일 루프 진행 상태를 관리한다.
const MAX_DAY := 3

var day: int = 1
var selected_student_id: String = ""
var choice_history: Array[Dictionary] = []
var color_counts: Dictionary = {}

func reset() -> void:
	day = 1
	selected_student_id = ""
	choice_history.clear()
	color_counts.clear()

func record_choice(student_id: String, color_id: String) -> void:
	selected_student_id = student_id
	choice_history.append({"day": day, "student_id": student_id, "color_id": color_id})
	color_counts[color_id] = int(color_counts.get(color_id, 0)) + 1

func advance_day() -> bool:
	day += 1
	return day > MAX_DAY

func top_color_id() -> String:
	var top := "blue"
	var top_count := -1
	for color_id in color_counts.keys():
		if color_counts[color_id] > top_count:
			top = color_id
			top_count = color_counts[color_id]
	return top
