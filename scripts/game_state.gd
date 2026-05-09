extends Node
class_name GameState

const MAX_DAY := 3
const SMALL_CHANGE_BY_COLOR := {
	"blue": "어제보다 숨이 조금 느려진 것 같았다.",
	"green": "그 아이는 창밖을 피하지 않고 바라보고 있었다.",
	"red": "손끝에 힘이 들어가 있었다. 도망만 치는 표정은 아니었다.",
	"purple": "가방 속 노트가 조금 열려 있었다.",
	"yellow": "웃음이 조금 가벼워졌다. 억지로 만든 표정은 아니었다.",
	"gray": "아무 일도 일어나지 않은 것 같았지만, 침묵의 모양은 조금 달랐다."
}

var day: int = 1
var selected_student_id: String = ""
var player_choices: Array[Dictionary] = []
var color_counts: Dictionary = {}

func reset() -> void:
	day = 1
	selected_student_id = ""
	player_choices.clear()
	color_counts.clear()

func record_choice(student_id: String, color_id: String) -> void:
	selected_student_id = student_id
	player_choices.append({"day": day, "student_id": student_id, "color_id": color_id})
	color_counts[color_id] = int(color_counts.get(color_id, 0)) + 1

func small_change_for_today(student_id: String) -> String:
	for choice in player_choices:
		if choice.student_id == student_id and int(choice.day) == day - 1:
			return SMALL_CHANGE_BY_COLOR.get(choice.color_id, "")
	return ""

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
