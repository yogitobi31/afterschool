extends Control

const DAY_INTRO_TEXTS := {
	1: "비가 내리고 있었다.\n버스는 분명 집으로 가고 있었지만,\n어쩐지 아무 곳에도 도착하지 못할 것 같았다.",
	2: "같은 빗소리.\n같은 좌석.\n하지만 어제 보지 못했던 것이 하나 보였다.",
	3: "세 번째 하교길.\n반복되는 것은 하루가 아니라,\n아직 말하지 못한 마음들인지도 모른다."
}

const DAY_GUIDES := {
	1: "오늘, 누구의 마음을 바라볼까.",
	2: "어제와 같은 자리였다.\n하지만 같은 마음은 아니었다.",
	3: "세 번째 하교길.\n이제 버스 안의 침묵에도 색이 있다는 걸 알 것 같았다."
}

const SMALL_CHANGE_BY_COLOR := {
	"blue": "어제보다 숨이 조금 느려진 것 같았다.",
	"green": "그 아이는 창밖을 피하지 않고 바라보고 있었다.",
	"red": "손끝에 힘이 들어가 있었다. 도망만 치는 표정은 아니었다.",
	"purple": "가방 속 노트가 조금 열려 있었다.",
	"yellow": "웃음이 조금 가벼워졌다. 억지로 만든 표정은 아니었다.",
	"gray": "아무 일도 일어나지 않은 것 같았지만, 침묵의 모양은 조금 달랐다."
}

@onready var title_layer: VBoxContainer = $Root/TitleLayer
@onready var intro_layer: PanelContainer = $Root/IntroLayer
@onready var day_intro_layer: PanelContainer = $Root/DayIntroLayer
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
@onready var color_prompt_label: Label = $Root/ColorLayer/Margin/V/Prompt
@onready var color_cards: VBoxContainer = $Root/ColorLayer/Margin/V/Cards
@onready var result_label: Label = $Root/ResultLayer/Margin/V/ResultText
@onready var ending_label: Label = $Root/EndingLayer/Margin/V/EndingText
@onready var day_intro_label: Label = $Root/DayIntroLayer/Margin/V/Text
@onready var day_intro_next_button: Button = $Root/DayIntroLayer/Margin/V/NextButton

@onready var backdrop: ColorRect = $Backdrop
@onready var bus_background_day1: ColorRect = $ArtLayer/BusBackgroundDay1
@onready var bus_background_day2: ColorRect = $ArtLayer/BusBackgroundDay2
@onready var bus_background_day3: ColorRect = $ArtLayer/BusBackgroundDay3
@onready var student_1_normal: ColorRect = $ArtLayer/Student1Normal
@onready var student_1_changed: ColorRect = $ArtLayer/Student1Changed
@onready var student_2_normal: ColorRect = $ArtLayer/Student2Normal
@onready var student_2_changed: ColorRect = $ArtLayer/Student2Changed
@onready var student_3_normal: ColorRect = $ArtLayer/Student3Normal
@onready var student_3_changed: ColorRect = $ArtLayer/Student3Changed
@onready var color_overlay_blue: ColorRect = $ArtLayer/ColorOverlayBlue
@onready var color_overlay_red: ColorRect = $ArtLayer/ColorOverlayRed
@onready var color_overlay_yellow: ColorRect = $ArtLayer/ColorOverlayYellow
@onready var color_overlay_green: ColorRect = $ArtLayer/ColorOverlayGreen
@onready var color_overlay_purple: ColorRect = $ArtLayer/ColorOverlayPurple
@onready var color_overlay_gray: ColorRect = $ArtLayer/ColorOverlayGray

var data: DataManager = DataManager.new()
var state: GameState = GameState.new()
var audio: AudioManager = AudioManager.new()
var current_student: Dictionary = {}

func _ready() -> void:
	data.load_all()
	add_child(audio)
	_setup_static_buttons()
	_show_only(title_layer)
	audio.play_bgm("title_bgm")

func _setup_static_buttons() -> void:
	$Root/TitleLayer/StartButton.text = "창밖을 바라본다"
	$Root/TitleLayer/StartButton.pressed.connect(_on_start_pressed)
	$Root/IntroLayer/Margin/V/NextButton.pressed.connect(func(): show_day_intro(state.day))
	$Root/TalkLayer/Margin/V/NextButton.text = "색을 건넨다"
	$Root/TalkLayer/Margin/V/NextButton.pressed.connect(func(): _show_color_choice())
	$Root/ResultLayer/Margin/V/NextButton.pressed.connect(_on_next_day)
	$Root/EndingLayer/Margin/V/RestartButton.pressed.connect(_restart)
	day_intro_next_button.pressed.connect(func(): _show_bus())

func _on_start_pressed() -> void:
	audio.play_ambience("rain_ambience")
	_show_only(intro_layer)

func show_day_intro(day: int) -> void:
	_show_only(day_intro_layer)
	day_intro_label.text = str(DAY_INTRO_TEXTS.get(day, ""))
	audio.fade_bgm(0.6, -14.0)
	await get_tree().create_timer(1.7).timeout
	day_intro_next_button.disabled = false

func _show_bus() -> void:
	_show_only(bus_layer)
	_apply_day_tone()
	audio.play_bgm("bus_loop_bgm")
	audio.play_ambience("bus_engine_ambience")
	day_intro_next_button.disabled = true
	day_label.text = "%d일차 하교길" % state.day
	guide_label.text = str(DAY_GUIDES.get(state.day, "오늘, 누구의 마음을 바라볼까."))
	observe_label.text = "버스 안 공기는 조용히 흔들리고 있었다."
	for child in student_buttons.get_children():
		child.queue_free()
	for student_data in data.students:
		var student: Dictionary = student_data as Dictionary
		var b: Button = Button.new()
		var student_name: String = str(student.get("name", "이름 없는 학생"))
		var outer_color: String = str(student.get("outer_color", ""))
		b.text = "%s (%s)" % [student_name, outer_color]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(s = student): _select_student(s))
		student_buttons.add_child(b)

func _select_student(student: Dictionary) -> void:
	current_student = student
	var observations: Array = student.get("day_observations", [])
	if observations.is_empty():
		observe_label.text = "아직 관찰할 수 있는 단서가 없었다."
		return
	var day_index: int = clamp(state.day - 1, 0, observations.size() - 1)
	var observation: String = str(observations[day_index])
	var student_id: String = str(student.get("id", "unknown"))
	var small_change: String = state.small_change_for_today(student_id)
	if not small_change.is_empty():
		observation += "\n" + small_change
	observe_label.text = observation
	guide_label.text = "조금 더 살펴본다"
	_set_student_change_slot(student_id, not small_change.is_empty())
	if not $Root/BusLayer/Margin/V.has_node("TalkNow"):
		var talk_btn: Button = Button.new()
		talk_btn.name = "TalkNow"
		talk_btn.text = "그 아이에게 말을 건넨다"
		talk_btn.pressed.connect(_show_talk)
		$Root/BusLayer/Margin/V.add_child(talk_btn)

func _show_talk() -> void:
	_show_only(talk_layer)
	var student_name: String = str(current_student.get("name", "이름 없는 학생"))
	talk_name_label.text = student_name
	var talks: Dictionary = current_student.get("talk", {}) as Dictionary
	var talk_key: String = "day%d" % state.day
	talk_text_label.text = str(talks.get(talk_key, "..."))

func _show_color_choice() -> void:
	_show_only(color_layer)
	audio.play_bgm("color_choice_bgm")
	audio.set_ambience_volume(-8.0)
	color_prompt_label.text = "어떤 색을 조심스럽게 건넬까."
	for child in color_cards.get_children():
		child.queue_free()
	for color_item in data.colors:
		var color_data: Dictionary = color_item as Dictionary
		var card: Button = Button.new()
		var color_name: String = str(color_data.get("name", "이름 없는 색"))
		var color_meaning: String = str(color_data.get("meaning", ""))
		card.text = "%s\n%s" % [color_name, color_meaning]
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.custom_minimum_size = Vector2(0, 72)
		var color_hex: String = str(color_data.get("hex", "#ffffff"))
		card.modulate = Color.from_string(color_hex, Color.WHITE)
		card.pressed.connect(func(c = color_data): _choose_color(c))
		color_cards.add_child(card)

func _choose_color(color_data: Dictionary) -> void:
	var student_id: String = str(current_student.get("id", "unknown"))
	var color_id: String = str(color_data.get("id", "gray"))
	state.record_choice(student_id, color_id)
	audio.play_sfx("ui_select_sfx")
	audio.set_ambience_volume(0.0)
	_show_only(result_layer)
	var student_name: String = str(current_student.get("name", "그 아이"))
	var color_name: String = str(color_data.get("name", "색"))
	result_label.text = "%s에게 %s을(를) 건넸다.\n%s" % [student_name, color_name, _reaction_text(color_id)]
	$Root/ResultLayer/Margin/V/NextButton.text = "다음 하교길"

func _reaction_text(color_id: String) -> String:
	var hint_colors: Array = current_student.get("hint_colors", [])
	if hint_colors.has(color_id):
		return "그 아이의 침묵이 아주 조금 덜 무거워졌다."
	return "정답은 없어도, 바라본 마음은 남는다."

func _on_next_day() -> void:
	audio.fade_bgm()
	if state.advance_day():
		_show_ending()
	else:
		show_day_intro(state.day)

func _show_ending() -> void:
	_show_only(ending_layer)
	audio.play_bgm("ending_bgm")
	audio.play_ambience("rain_ambience")
	var top: String = state.top_color_id()
	var ending_tail: String = str(SMALL_CHANGE_BY_COLOR.get(top, SMALL_CHANGE_BY_COLOR["gray"]))
	ending_label.text = "버스는 여전히 비 오는 길을 달리고 있었다.\n학원가의 불빛도, 젖은 창문도 그대로였다.\n하지만 오늘,\n누군가의 마음은 아주 조금 덜 혼자였다.\n%s" % ending_tail

func _restart() -> void:
	state.reset()
	_show_only(title_layer)
	audio.play_bgm("title_bgm")

func _apply_day_tone() -> void:
	var hint_alpha: float = 0.03 + float(state.day - 1) * 0.05
	var day_colors: Array[Color] = [Color(0.09, 0.11, 0.15), Color(0.1, 0.12, 0.16), Color(0.11, 0.13, 0.17)]
	var day_index: int = clamp(state.day - 1, 0, day_colors.size() - 1)
	backdrop.color = day_colors[day_index]
	bus_background_day1.visible = state.day == 1
	bus_background_day2.visible = state.day == 2
	bus_background_day3.visible = state.day == 3
	color_overlay_blue.color.a = hint_alpha
	color_overlay_red.color.a = hint_alpha * 0.7
	color_overlay_yellow.color.a = hint_alpha * 0.7
	color_overlay_green.color.a = hint_alpha
	color_overlay_purple.color.a = hint_alpha * 0.8
	color_overlay_gray.color.a = 0.08 + hint_alpha

func _set_student_change_slot(student_id: String, changed: bool) -> void:
	student_1_changed.visible = changed and student_id == "top_student"
	student_2_changed.visible = changed and student_id == "academy_student"
	student_3_changed.visible = changed and student_id == "dream_student"

func _show_only(target: Control) -> void:
	var layers: Array[Control] = [title_layer, intro_layer, day_intro_layer, bus_layer, talk_layer, color_layer, result_layer, ending_layer]
	for layer in layers:
		layer.visible = layer == target
