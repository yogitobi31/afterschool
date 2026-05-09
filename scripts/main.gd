extends Control

const DAY_INTRO_TEXTS: Dictionary = {
	1: "비가 내리고 있었다.\n버스는 분명 집으로 가고 있었지만,\n어쩐지 아무 곳에도 도착하지 못할 것 같았다.",
	2: "같은 빗소리.\n같은 좌석.\n하지만 어제 보지 못했던 색이 하나 보였다.",
	3: "버스 안의 색이 조금씩 사라지고 있었다.\n누군가의 마음이 회색으로 접히고 있었다.",
	4: "이제는 알아야 했다.\n밝아 보이는 색이, 정말 그 아이의 색인지.",
	5: "다섯 번째 하교길.\n오늘은 누군가에게 하나의 색을 건네야 한다."
}

const STUDENT_IDS: Array[String] = ["honor_student", "academy_child", "drifting_dreamer"]

@onready var title_layer: VBoxContainer = $Root/TitleLayer
@onready var intro_layer: PanelContainer = $Root/IntroLayer
@onready var day_intro_layer: PanelContainer = $Root/DayIntroLayer
@onready var bus_layer: PanelContainer = $Root/BusLayer
@onready var color_layer: PanelContainer = $Root/ColorLayer
@onready var result_layer: PanelContainer = $Root/ResultLayer
@onready var ending_layer: PanelContainer = $Root/EndingLayer
@onready var day_label: Label = $Root/BusLayer/Margin/V/DayLabel
@onready var guide_label: Label = $Root/BusLayer/Margin/V/GuideLabel
@onready var observe_label: Label = $Root/BusLayer/Margin/V/Observe
@onready var area_buttons: HBoxContainer = $Root/BusLayer/Margin/V/Students
@onready var day_intro_label: Label = $Root/DayIntroLayer/Margin/V/Text
@onready var day_intro_next_button: Button = $Root/DayIntroLayer/Margin/V/NextButton
@onready var color_prompt_label: Label = $Root/ColorLayer/Margin/V/Prompt
@onready var color_cards: VBoxContainer = $Root/ColorLayer/Margin/V/Cards
@onready var result_label: Label = $Root/ResultLayer/Margin/V/ResultText
@onready var ending_label: Label = $Root/EndingLayer/Margin/V/EndingText

var data: DataManager = DataManager.new()
var state: GameState = GameState.new()
var audio: AudioManager = AudioManager.new()
var selected_student_id: String = ""
var selected_area_id: String = ""
var action_buttons: HBoxContainer
var next_day_button: Button
var journal_button: Button

func _ready() -> void:
	data.load_all()
	add_child(audio)
	_setup_bus_extra_ui()
	_setup_buttons()
	_show_only(title_layer)
	audio.play_bgm("title_bgm")
	audio.play_ambience("rain_ambience")

func _setup_bus_extra_ui() -> void:
	var bus_v: VBoxContainer = $Root/BusLayer/Margin/V
	action_buttons = HBoxContainer.new()
	journal_button = Button.new()
	next_day_button = Button.new()
	journal_button.text = "마음 기록장"
	next_day_button.text = "다음 하교길로"
	next_day_button.disabled = true
	journal_button.pressed.connect(func() -> void: _show_journal())
	next_day_button.pressed.connect(func() -> void: _advance_flow())
	bus_v.add_child(action_buttons)
	bus_v.add_child(journal_button)
	bus_v.add_child(next_day_button)

func _setup_buttons() -> void:
	var start_button: Button = $Root/TitleLayer/StartButton
	var intro_next_button: Button = $Root/IntroLayer/Margin/V/NextButton
	var result_next_button: Button = $Root/ResultLayer/Margin/V/NextButton
	var restart_button: Button = $Root/EndingLayer/Margin/V/RestartButton
	start_button.text = "창밖을 바라본다"
	start_button.pressed.connect(func() -> void: _show_only(intro_layer))
	intro_next_button.pressed.connect(func() -> void: _show_day_intro())
	day_intro_next_button.disabled = false
	day_intro_next_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if not day_intro_next_button.pressed.is_connected(_on_day_intro_continue_pressed):
		day_intro_next_button.pressed.connect(_on_day_intro_continue_pressed)
	result_next_button.pressed.connect(func() -> void: _advance_flow())
	restart_button.pressed.connect(func() -> void: _restart())
	_set_mouse_ignore_recursive(day_intro_layer, day_intro_next_button)

func _set_mouse_ignore_recursive(node: Node, except_button: Button) -> void:
	for child_node in node.get_children():
		var child: Node = child_node
		if child is Control:
			var control_child: Control = child as Control
			if control_child != except_button:
				control_child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if child.get_child_count() > 0:
			_set_mouse_ignore_recursive(child, except_button)

func _show_day_intro() -> void:
	_show_only(day_intro_layer)
	day_intro_label.text = str(DAY_INTRO_TEXTS.get(state.day, ""))
	day_intro_next_button.text = "마지막 하교길로 간다" if state.day == 5 else "오늘의 하교길로 돌아간다"

func _on_day_intro_continue_pressed() -> void:
	_show_bus()

func _unhandled_input(event: InputEvent) -> void:
	if day_intro_layer.visible and event.is_action_pressed("ui_accept"):
		_on_day_intro_continue_pressed()

func _show_bus() -> void:
	_show_only(bus_layer)
	day_label.text = "%d일차 하교길" % state.day
	guide_label.text = _ap_text()
	observe_label.text = "이번 정류장은… 오늘입니다. 내리실 문은 없습니다."
	_refresh_bus_actions()
	audio.play_bgm("color_choice_bgm" if state.day == 5 else "bus_loop_bgm")
	audio.play_ambience("bus_engine_ambience")

func _refresh_bus_actions() -> void:
	for c in area_buttons.get_children():
		c.queue_free()
	for student_data in data.students:
		var student: Dictionary = student_data as Dictionary
		var b: Button = Button.new()
		var student_id: String = str(student.get("id", ""))
		b.text = str(student.get("name", ""))
		b.pressed.connect(func() -> void: _on_area_selected(student_id))
		area_buttons.add_child(b)
	for area_id in ["window", "bell", "sign"]:
		var area_button: Button = Button.new()
		area_button.text = _area_name(str(area_id))
		area_button.pressed.connect(func() -> void: _on_area_selected(str(area_id)))
		area_buttons.add_child(area_button)
	_update_action_buttons([])
	next_day_button.disabled = state.day < 5 and state.action_points > 0

func _on_area_selected(area_id: String) -> void:
	selected_area_id = area_id
	if state.day == 5:
		if STUDENT_IDS.has(area_id):
			selected_student_id = area_id
			_show_color_choice()
		return
	if not state.can_act():
		observe_label.text = "오늘은 더 바라볼 수 없다."
		return
	var actions: Array[String] = _actions_for_area(area_id)
	_update_action_buttons(actions)

func _actions_for_area(area_id: String) -> Array[String]:
	if STUDENT_IDS.has(area_id):
		return ["observe", "talk", "inspect_item"]
	if area_id == "window":
		return ["observe", "inspect_item"]
	if area_id == "bell" or area_id == "sign":
		return ["observe"]
	return []

func _update_action_buttons(actions: Array[String]) -> void:
	for c in action_buttons.get_children():
		c.queue_free()
	for action_id in actions:
		var button: Button = Button.new()
		var action_type: String = str(action_id)
		button.text = _action_name(action_type)
		button.pressed.connect(func() -> void: _perform_action(action_type))
		action_buttons.add_child(button)

func _perform_action(action_type: String) -> void:
	if not state.can_act():
		observe_label.text = "오늘은 더 바라볼 수 없다."
		return
	var clue: Dictionary = _find_clue_for(selected_area_id, action_type)
	state.spend_action()
	if clue.is_empty():
		observe_label.text = "기억에 남은 장면은 있었지만, 새 단서는 찾지 못했다."
	else:
		var clue_id: String = str(clue.get("id", ""))
		var student_id: String = str(clue.get("student_id", ""))
		var clue_title: String = str(clue.get("title", ""))
		var hint_text: String = _hint_text(clue.get("color_hints", []) as Array)
		if state.mark_clue_discovered(student_id, clue_id):
			observe_label.text = "새로 보인 마음: %s\n색의 흔적: %s\n기억에 남은 장면이 기록되었다." % [clue_title, hint_text]
			audio.play_sfx("ui_select_sfx")
		else:
			observe_label.text = "이미 보았던 마음이지만, 오늘은 다르게 남았다."
	guide_label.text = _ap_text()
	next_day_button.disabled = state.day < 5 and state.action_points > 0

func _find_clue_for(area_id: String, action_type: String) -> Dictionary:
	for clue_data in data.clues:
		var clue: Dictionary = clue_data as Dictionary
		var day_available: int = int(clue.get("day_available", 9))
		var clue_id: String = str(clue.get("id", ""))
		var clue_area: String = str(clue.get("area", ""))
		var clue_action_type: String = str(clue.get("action_type", ""))
		if day_available <= state.day and clue_area == area_id and clue_action_type == action_type and not state.is_clue_discovered(clue_id):
			return clue
	return {}

func _show_journal() -> void:
	var lines: Array[String] = ["마음 기록장"]
	for student_data in data.students:
		var student: Dictionary = student_data as Dictionary
		var student_id: String = str(student.get("id", ""))
		lines.append("\n[%s]" % str(student.get("name", "학생")))
		for clue_data in data.clues:
			var clue: Dictionary = clue_data as Dictionary
			if str(clue.get("student_id", "")) != student_id:
				continue
			var clue_id: String = str(clue.get("id", ""))
			if state.is_clue_discovered(clue_id):
				lines.append("- %s | %s" % [str(clue.get("title", "")), _hint_text(clue.get("color_hints", []) as Array)])
			else:
				lines.append("- 아직 보지 못한 마음")
	observe_label.text = "\n".join(lines)

func _show_color_choice() -> void:
	_show_only(color_layer)
	color_prompt_label.text = "%s에게 마지막 색을 건넨다." % _student_name(selected_student_id)
	for c in color_cards.get_children():
		c.queue_free()
	for color_data in data.colors:
		var color: Dictionary = color_data as Dictionary
		var b: Button = Button.new()
		var color_id: String = str(color.get("id", ""))
		b.text = "%s\n%s" % [str(color.get("name", "")), str(color.get("meaning", ""))]
		b.pressed.connect(func() -> void: _resolve_final_choice(color_id))
		color_cards.add_child(b)

func _resolve_final_choice(color_id: String) -> void:
	var student: Dictionary = _student_by_id(selected_student_id)
	var true_colors: Array = student.get("true_colors", []) as Array
	var surface_color: String = str(student.get("surface_color", ""))
	var risk_color: String = str(student.get("risk_color", ""))
	var result_type: String = "other"
	if true_colors.has(color_id): result_type = "good"
	elif color_id == surface_color and not true_colors.has(color_id): result_type = "surface"
	elif color_id == risk_color: result_type = "risk"
	state.record_final_choice(selected_student_id, color_id, result_type)
	_show_only(result_layer)
	var result_texts: Dictionary = student.get("result_texts", {}) as Dictionary
	result_label.text = str(result_texts.get(result_type, "불완전한 선택이었지만, 다시 바라볼 이유가 남았다."))
	audio.fade_bgm(0.6, -20.0)
	audio.stop_ambience()
	audio.play_ambience("rain_ambience")

func _advance_flow() -> void:
	if state.day == 5:
		_show_ending(); return
	if state.advance_day(): _show_ending()
	else: _show_day_intro()

func _show_ending() -> void:
	_show_only(ending_layer)
	ending_label.text = "같은 하교길을 반복할수록, 웃고 있던 아이들의 진짜 색이 보이기 시작했다.\n아직 닿지 못한 마음이 남아 있다."

func _restart() -> void:
	state.reset()
	audio.play_bgm("title_bgm")
	_show_only(title_layer)

func _show_only(target: Control) -> void:
	var layers: Array[Control] = [title_layer, intro_layer, day_intro_layer, bus_layer, color_layer, result_layer, ending_layer]
	for layer in layers: layer.visible = layer == target

func _ap_text() -> String:
	if state.action_points > 0:
		return "오늘, 더 바라볼 수 있는 마음: %d" % state.action_points
	return "오늘은 더 바라볼 수 없다."

func _action_name(action_type: String) -> String:
	if action_type == "observe": return "관찰하기"
	if action_type == "talk": return "말을 걸어본다"
	return "소품을 살펴본다"

func _hint_text(colors: Array) -> String:
	var words: Array[String] = []
	for color_var in colors:
		var color_id: String = str(color_var)
		if color_id == "blue": words.append("파랑")
		elif color_id == "green": words.append("초록")
		elif color_id == "red": words.append("빨강")
		elif color_id == "yellow": words.append("노랑")
		elif color_id == "purple": words.append("보라")
		elif color_id == "gray": words.append("회색")
	return ", ".join(words)

func _area_name(area_id: String) -> String:
	if area_id == "window": return "창밖"
	if area_id == "bell": return "하차벨"
	if area_id == "sign": return "안내판"
	return ""

func _student_name(student_id: String) -> String:
	var student: Dictionary = _student_by_id(student_id)
	return str(student.get("name", "학생"))

func _student_by_id(student_id: String) -> Dictionary:
	for item_data in data.students:
		var item: Dictionary = item_data as Dictionary
		if str(item.get("id", "")) == student_id: return item
	return {}
