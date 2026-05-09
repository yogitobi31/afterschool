extends Node
class_name GameState

const MAX_DAY: int = 5
const DAILY_ACTION_POINTS: int = 2

var day: int = 1
var action_points: int = DAILY_ACTION_POINTS
var discovered_clues: Array[String] = []
var discovered_by_student: Dictionary = {}
var final_choice: Dictionary = {}

func reset() -> void:
	day = 1
	action_points = DAILY_ACTION_POINTS
	discovered_clues.clear()
	discovered_by_student.clear()
	final_choice.clear()

func start_day() -> void:
	action_points = DAILY_ACTION_POINTS

func can_act() -> bool:
	return day < MAX_DAY and action_points > 0

func spend_action() -> void:
	action_points = max(action_points - 1, 0)

func mark_clue_discovered(student_id: String, clue_id: String) -> bool:
	if discovered_clues.has(clue_id):
		return false
	discovered_clues.append(clue_id)
	if not discovered_by_student.has(student_id):
		discovered_by_student[student_id] = []
	var student_clues: Array = discovered_by_student.get(student_id, []) as Array
	student_clues.append(clue_id)
	discovered_by_student[student_id] = student_clues
	return true

func is_clue_discovered(clue_id: String) -> bool:
	return discovered_clues.has(clue_id)

func advance_day() -> bool:
	day += 1
	if day <= MAX_DAY:
		start_day()
	return day > MAX_DAY

func record_final_choice(student_id: String, color_id: String, result_type: String) -> void:
	final_choice = {"student_id": student_id, "color_id": color_id, "result_type": result_type}
