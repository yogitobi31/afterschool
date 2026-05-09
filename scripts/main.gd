extends Control

const DAY_INTRO_TEXTS: Dictionary = {
	1: "비가 내리고 있었다.\n버스는 분명 집으로 가고 있었지만,\n어쩐지 아무 곳에도 도착하지 못할 것 같았다.",
	2: "같은 하교길인데 어제 보지 못한 장면이 보였다.",
	3: "반복될수록 버스 안의 색이 조금씩 옅어졌다.",
	4: "겉으로 보이는 색과 진짜 마음이 다를 수도 있다는 생각이 들었다.",
	5: "다섯 번째 하교길. 오늘은 더는 조사하지 않는다. 이제 선택해야 한다."
}

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
@onready var student_buttons: HBoxContainer = $Root/BusLayer/Margin/V/Students
@onready var day_intro_label: Label = $Root/DayIntroLayer/Margin/V/Text
@onready var color_prompt_label: Label = $Root/ColorLayer/Margin/V/Prompt
@onready var color_cards: VBoxContainer = $Root/ColorLayer/Margin/V/Cards
@onready var result_label: Label = $Root/ResultLayer/Margin/V/ResultText
@onready var ending_label: Label = $Root/EndingLayer/Margin/V/EndingText

var data: DataManager = DataManager.new()
var state: GameState = GameState.new()
var audio: AudioManager = AudioManager.new()
var selected_student_id: String = ""
var selected_color_id: String = ""

func _ready() -> void:
	data.load_all()
	add_child(audio)
	_setup_buttons()
	_show_only(title_layer)

func _setup_buttons() -> void:
	$Root/TitleLayer/StartButton.text = "창밖을 바라본다"
	$Root/TitleLayer/StartButton.pressed.connect(func() -> void: _show_only(intro_layer))
	$Root/IntroLayer/Margin/V/NextButton.pressed.connect(func() -> void: _show_day_intro())
	$Root/DayIntroLayer/Margin/V/NextButton.pressed.connect(func() -> void: _show_bus())
	$Root/ResultLayer/Margin/V/NextButton.pressed.connect(func() -> void: _advance_flow())
	$Root/EndingLayer/Margin/V/RestartButton.pressed.connect(func() -> void: _restart())

func _show_day_intro() -> void:
	_show_only(day_intro_layer)
	day_intro_label.text = str(DAY_INTRO_TEXTS.get(state.day, ""))

func _show_bus() -> void:
	_show_only(bus_layer)
	day_label.text = "%d일차 하교길" % state.day
	guide_label.text = "마지막 선택: 학생 한 명과 색 하나를 고른다." if state.day == 5 else "오늘, 더 바라볼 수 있는 마음: %d" % state.action_points
	observe_label.text = "이상한 안내방송: 이번 정류장은… 오늘입니다. 내리실 문은 없습니다."
	_refresh_bus_actions()

func _refresh_bus_actions() -> void:
	for c in student_buttons.get_children():
		c.queue_free()
	for student in data.students:
		var student_data: Dictionary = student
		var b: Button = Button.new()
		var student_id: String = str(student_data.get("id", ""))
		b.text = str(student_data.get("name", ""))
		b.pressed.connect(func() -> void: _on_area_selected(student_id))
		student_buttons.add_child(b)
	for area_id in ["window", "bell", "sign"]:
		var area_button: Button = Button.new()
		area_button.text = _area_name(area_id)
		area_button.pressed.connect(func() -> void: _on_area_selected(area_id))
		student_buttons.add_child(area_button)

func _on_area_selected(area_id: String) -> void:
	if state.day == 5:
		if area_id in ["honor_student", "academy_child", "drifting_dreamer"]:
			selected_student_id = area_id
			_show_color_choice()
		return
	if not state.can_act():
		observe_label.text = "오늘은 더 바라볼 수 없다."
		return
	var clue: Dictionary = _find_clue_for(area_id)
	if clue.is_empty():
		state.spend_action()
		observe_label.text = "기억에 남은 장면은 있었지만, 새 단서는 찾지 못했다."
		guide_label.text = "오늘, 더 바라볼 수 있는 마음: %d" % state.action_points if state.action_points > 0 else "오늘은 더 바라볼 수 없다."
		return
	state.spend_action()
	var clue_id: String = str(clue.get("id", ""))
	var student_id: String = str(clue.get("student_id", ""))
	var clue_title: String = str(clue.get("title", ""))
	var hint_text: String = _hint_text(clue.get("color_hints", []) as Array)
	if state.mark_clue_discovered(student_id, clue_id):
		observe_label.text = "새로 보인 마음: %s\n색의 흔적: %s\n%s" % [clue_title, hint_text, str(clue.get("text", ""))]
		audio.play_sfx("ui_select_sfx")
	else:
		observe_label.text = "기억에 남은 장면: %s\n이미 본 마음이었지만, 오늘은 다르게 남았다." % clue_title
	guide_label.text = "오늘, 더 바라볼 수 있는 마음: %d" % state.action_points if state.action_points > 0 else "오늘은 더 바라볼 수 없다."

func _find_clue_for(area_id: String) -> Dictionary:
	for clue_data in data.clues:
		var clue: Dictionary = clue_data
		var day_available: int = int(clue.get("day_available", 9))
		var clue_id: String = str(clue.get("id", ""))
		var clue_area: String = str(clue.get("area", ""))
		if day_available <= state.day and clue_area == area_id and not state.is_clue_discovered(clue_id):
			return clue
	return {}

func _show_color_choice() -> void:
	_show_only(color_layer)
	color_prompt_label.text = "마지막 하교길이 끝나기 전, %s에게 건넬 색을 고른다." % _student_name(selected_student_id)
	for c in color_cards.get_children():
		c.queue_free()
	for color in data.colors:
		var color_data: Dictionary = color
		var b: Button = Button.new()
		b.text = "%s\n%s" % [str(color_data.get("name", "")), str(color_data.get("meaning", ""))]
		var color_id: String = str(color_data.get("id", ""))
		b.pressed.connect(func() -> void: _resolve_final_choice(color_id))
		color_cards.add_child(b)

func _resolve_final_choice(color_id: String) -> void:
	selected_color_id = color_id
	var student: Dictionary = _student_by_id(selected_student_id)
	var true_colors: Array = student.get("true_colors", []) as Array
	var surface_color: String = str(student.get("surface_color", ""))
	var risk_color: String = str(student.get("risk_color", ""))
	var result_type: String = "other"
	if true_colors.has(color_id):
		result_type = "good"
	elif color_id == surface_color and not true_colors.has(color_id):
		result_type = "surface"
	elif color_id == risk_color:
		result_type = "risk"
	state.record_final_choice(selected_student_id, color_id, result_type)
	_show_only(result_layer)
	var result_texts: Dictionary = student.get("result_texts", {}) as Dictionary
	result_label.text = str(result_texts.get(result_type, ""))

func _advance_flow() -> void:
	if state.day == 5:
		_show_ending()
		return
	if state.advance_day():
		_show_ending()
	else:
		_show_day_intro()

func _show_ending() -> void:
	_show_only(ending_layer)
	ending_label.text = "이 하교길은 끝났지만, 다시 바라볼 이유가 남았다.\n마음 기록장에 남은 장면들을 따라가면 다른 결론에 닿을지도 모른다."

func _restart() -> void:
	state.reset()
	_show_only(title_layer)

func _show_only(target: Control) -> void:
	var layers: Array[Control] = [title_layer, intro_layer, day_intro_layer, bus_layer, color_layer, result_layer, ending_layer]
	for layer in layers:
		layer.visible = layer == target

func _hint_text(colors: Array) -> String:
	var words: Array[String] = []
	for color_var in colors:
		var color_id: String = str(color_var)
		if color_id == "blue": words.append("파랑(차가운 숨)")
		elif color_id == "green": words.append("초록(다시 시작)")
		elif color_id == "red": words.append("빨강(멈춘 진심)")
		elif color_id == "yellow": words.append("노랑(밝은 가면)")
		elif color_id == "purple": words.append("보라(흔들리는 꿈)")
		elif color_id == "gray": words.append("회색(오래 버틴 마음)")
	return ", ".join(words)

func _area_name(area_id: String) -> String:
	if area_id == "window": return "창밖"
	if area_id == "bell": return "하차벨"
	return "안내판"

func _student_name(student_id: String) -> String:
	var student: Dictionary = _student_by_id(student_id)
	return str(student.get("name", "학생"))

func _student_by_id(student_id: String) -> Dictionary:
	for student in data.students:
		var item: Dictionary = student
		if str(item.get("id", "")) == student_id:
			return item
	return {}
