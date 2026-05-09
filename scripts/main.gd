extends Control

@onready var title_layer: VBoxContainer = $Root/TitleLayer
@onready var intro_layer: PanelContainer = $Root/IntroLayer
@onready var bus_layer: PanelContainer = $Root/BusLayer
@onready var talk_layer: PanelContainer = $Root/TalkLayer
@onready var color_layer: PanelContainer = $Root/ColorLayer
@onready var result_layer: PanelContainer = $Root/ResultLayer
@onready var ending_layer: PanelContainer = $Root/EndingLayer

@onready var day_label: Label = $Root/BusLayer/Margin/V/DayLabel
@onready var guide_label: Label = $Root/BusLayer/Margin/V/GuideLabel
@onready var student_buttons: HBoxContainer = $Root/BusLayer/Margin/V/Students
@onready var observe_label: Label = $Root/BusLayer/Margin/V/Observe
@onready var talk_name_label: Label = $Root/TalkLayer/Margin/V/Name
@onready var talk_text_label: Label = $Root/TalkLayer/Margin/V/Text
@onready var color_cards: VBoxContainer = $Root/ColorLayer/Margin/V/Cards
@onready var result_label: Label = $Root/ResultLayer/Margin/V/ResultText
@onready var ending_label: Label = $Root/EndingLayer/Margin/V/EndingText

var data := DataManager.new()
var state := GameState.new()
var current_student: Dictionary = {}

func _ready() -> void:
	data.load_all()
	_setup_static_buttons()
	_show_only(title_layer)

func _setup_static_buttons() -> void:
	$Root/TitleLayer/StartButton.pressed.connect(_on_start_pressed)
	$Root/IntroLayer/Margin/V/NextButton.pressed.connect(func(): _show_bus())
	$Root/TalkLayer/Margin/V/NextButton.pressed.connect(func(): _show_color_choice())
	$Root/ResultLayer/Margin/V/NextButton.pressed.connect(_on_next_day)
	$Root/EndingLayer/Margin/V/RestartButton.pressed.connect(_restart)

func _on_start_pressed() -> void:
	_show_only(intro_layer)

func _show_bus() -> void:
	_show_only(bus_layer)
	day_label.text = "%d일차 하교길" % state.day
	guide_label.text = "오늘은 한 명만 바라볼 수 있습니다."
	observe_label.text = "비가 창문을 천천히 긁고 지나간다."
	for child in student_buttons.get_children():
		child.queue_free()
	for student in data.students:
		var b := Button.new()
		b.text = "%s (%s)" % [student.name, student.outer_color]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(s = student): _select_student(s))
		student_buttons.add_child(b)

func _select_student(student: Dictionary) -> void:
	current_student = student
	observe_label.text = student.observations[state.day - 1]
	guide_label.text = "선택 완료: 대화를 시작하세요."
	var talk_btn := Button.new()
	talk_btn.text = "짧은 대화 시작"
	talk_btn.pressed.connect(_show_talk)
	if not $Root/BusLayer/Margin/V.has_node("TalkNow"):
		talk_btn.name = "TalkNow"
		$Root/BusLayer/Margin/V.add_child(talk_btn)

func _show_talk() -> void:
	_show_only(talk_layer)
	talk_name_label.text = current_student.name
	talk_text_label.text = current_student.talk["day%d" % state.day]

func _show_color_choice() -> void:
	_show_only(color_layer)
	for child in color_cards.get_children():
		child.queue_free()
	for color_data in data.colors:
		var card := Button.new()
		card.text = "%s\n%s" % [color_data.name, color_data.meaning]
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.custom_minimum_size = Vector2(0, 72)
		card.modulate = Color.from_string(color_data.hex, Color.WHITE)
		card.pressed.connect(func(c = color_data): _choose_color(c))
		color_cards.add_child(card)

func _choose_color(color_data: Dictionary) -> void:
	state.record_choice(current_student.id, color_data.id)
	_show_only(result_layer)
	result_label.text = "%s에게 %s을(를) 건넸다.\n%s" % [current_student.name, color_data.name, _reaction_text(color_data.id)]

func _reaction_text(color_id: String) -> String:
	if current_student.hint_colors.has(color_id):
		return "그 아이의 숨이 아주 조금 느려졌다."
	return "정답은 없어도, 바라본 마음은 남는다."

func _on_next_day() -> void:
	if state.advance_day():
		_show_ending()
	else:
		_show_bus()

func _show_ending() -> void:
	_show_only(ending_layer)
	var top := state.top_color_id()
	var color_name := "파랑"
	for c in data.colors:
		if c.id == top:
			color_name = c.name
	ending_label.text = "오늘의 하교길에 가장 많이 남은 것은 %s이었다.\n조금 덜 혼자가 된 저녁이, 창문에 천천히 맺혔다." % color_name

func _restart() -> void:
	state.reset()
	_show_only(title_layer)

func _show_only(target: Control) -> void:
	for layer in [title_layer, intro_layer, bus_layer, talk_layer, color_layer, result_layer, ending_layer]:
		layer.visible = layer == target
