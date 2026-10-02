extends Control
## 미니게임 연습장 (개발용). 게임 흐름 없이 미니게임 하나만 해 본다.
## 인스펙터에서 레시피, 몇 번째 요리 단계, 오늘의 부탁을 고르고 이 씬만 실행(F6)한다.
## 끝나면 결과를 보여 주고 restart_delay 초 뒤에 같은 미니게임을 다시 시작한다.

const RESULT_FORMAT: String = "결과: %s   ·   완벽 %s   ·   할머니 손맛 %s   ·   부탁 %s   (%d번째)"
const YES_TEXT: String = "O"
const NO_TEXT: String = "X"
const NONE_TEXT: String = "-"

## 해 볼 레시피
@export var recipe: Recipe
## 레시피의 몇 번째 요리 단계인지 (0 = 첫 번째)
@export var step_index: int = 0
## 걸어 볼 오늘의 부탁 (비워 두면 부탁 없이)
@export var request: GuestRequest
## 켜면 그 레시피의 할머니 비법을 아는 것으로 하고 비법 자리를 보여 준다
@export var is_secret_known: bool = false
## 끝난 뒤 다시 시작하기까지 기다리는 시간(초)
@export var restart_delay: float = 1.5
## 미니게임 종류마다 쓸 씬
@export var minigame_scenes: Dictionary[Recipe.MinigameType, PackedScene] = {}

var _minigame: Minigame
var _round: int = 0

@onready var _background: ColorRect = %Background
@onready var _info_label: Label = %InfoLabel
@onready var _result_label: Label = %ResultLabel


func _ready() -> void:
	GameState.start_new_game()
	if recipe == null or step_index < 0 or step_index >= recipe.cook_steps.size():
		_info_label.text = "인스펙터에서 Recipe 와 Step Index 를 골라 주세요."
		return
	var step: CookStep = recipe.cook_steps[step_index]
	if request != null and not request.is_garnish_request() and not request.applies_to_step(step):
		_info_label.text = "이 부탁은 이 단계에 걸 수 없어요. 다른 단계나 부탁을 골라 주세요."
		return
	var minigame_type: Recipe.MinigameType = request.get_minigame_type(step) if request != null and not request.is_garnish_request() else step.type
	if not minigame_scenes.has(minigame_type):
		_info_label.text = "이 미니게임 종류의 씬이 Minigame Scenes 에 없어요."
		return
	if is_secret_known:
		GameState.learn_secret(recipe.id)
	_minigame = minigame_scenes[minigame_type].instantiate()
	add_child(_minigame)
	# 배경 바로 위, 안내 글 아래에 놓는다.
	move_child(_minigame, _background.get_index() + 1)
	_minigame.finished.connect(_on_finished)
	_info_label.text = "연습장: %s · %d번째 단계 · 부탁: %s" % [recipe.display_name, step_index + 1,
			request.line if request != null else "없음"]
	_start()


func _start() -> void:
	_round += 1
	_minigame.start(recipe, recipe.cook_steps[step_index], request)


func _on_finished(is_perfect: bool, is_grandma_taste: bool, is_request_met: bool) -> void:
	var has_secret: bool = recipe.cook_steps[step_index].has_secret()
	_result_label.text = RESULT_FORMAT % [
		"성공" if is_perfect or is_grandma_taste or is_request_met else "완료",
		YES_TEXT if is_perfect else NO_TEXT,
		(YES_TEXT if is_grandma_taste else NO_TEXT) if has_secret else NONE_TEXT,
		(YES_TEXT if is_request_met else NO_TEXT) if request != null else NONE_TEXT,
		_round]
	# 두 번째 값 false: 일시 정지 중에는 이 기다림도 멈춘다.
	await get_tree().create_timer(restart_delay, false).timeout
	_start()
