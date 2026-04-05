extends CanvasLayer

const TRANSITION_DURATION_IN: float = 0.4
const TRANSITION_DURATION_OUT: float = 0.3
const TRANSITION_DELAY: float = 1.0

const TRANSITION_COLOR_DEFAULT: Color = Color("1b1b1b")
const TRANSITION_COLOR_BOSS: Color = Color("ea323c")

enum Scene{
	MAIN_MENU, 
	LEVEL_SELECTION, 
	BLOCK_SELECTION, 
	PERK_SELECTION, 
	GAME
}


var scenes: Dictionary = {
	Scene.MAIN_MENU: preload("res://scenes/main_menu.tscn"), 
	Scene.LEVEL_SELECTION: preload("res://scenes/level_selection/level_selection.tscn"), 
	#Scene.BLOCK_SELECTION: preload("res://scenes/block_selection/block_selection.tscn"), 
	#Scene.PERK_SELECTION: preload("res://scenes/perk_selection/perk_selection.tscn"), 
	Scene.GAME: preload("res://scenes/game.tscn")
}

var tween: Tween
var target: Scene = Scene.MAIN_MENU


@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void :
	(color_rect.material as ShaderMaterial).set_shader_parameter("screen_width", 1920)
	(color_rect.material as ShaderMaterial).set_shader_parameter("screen_height", 1080)
	(color_rect.material as ShaderMaterial).set_shader_parameter("circle_size", 1.05)


func goto(scene: Scene, on_black_callback: Callable = Callable(), force: bool = false) -> void :
	_transition_to_scene(scene, on_black_callback, force)


func restart(on_black_callback: Callable = Callable()) -> void :
	_transition_to_scene(Scene.LEVEL_SELECTION, on_black_callback, true)


func _transition_to_scene(scene: Scene, on_black_callback: Callable = Callable(), force: bool = false) -> void :

	if target == scene and not force:
		return


	if tween and tween.is_running():
		tween.kill()


	target = scene

	#AudioManager.play(AudioManager.SoundEffects.TRANSITION, 0.9)

	if GameManager.current_round % 3 == 0 and scene == Scene.GAME:
		color_rect.color = TRANSITION_COLOR_BOSS
	else:
		color_rect.color = TRANSITION_COLOR_DEFAULT

	var speed: float = GameManager.timescale
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	tween.tween_property(color_rect, "material:shader_parameter/circle_size", 0, TRANSITION_DURATION_IN / speed)
	tween.tween_callback(_on_screen_black.bind(scene, on_black_callback))
	tween.set_ease(Tween.EASE_IN)
	tween.tween_interval(TRANSITION_DELAY / speed)
	tween.tween_callback(
		func() -> void :
			return
			#AudioManager.play(AudioManager.SoundEffects.TRANSITION, 1.1)
	)
	tween.tween_property(color_rect, "material:shader_parameter/circle_size", 1.05, TRANSITION_DURATION_OUT / speed)


func _on_screen_black(scene: Scene, on_black_callback: Callable) -> void :
	if on_black_callback.is_valid():
		on_black_callback.call()
	_change_scene(scene)


func _change_scene(scene: Scene) -> void :

	var main_viewport: SubViewport = get_tree().current_scene.find_child("MainViewport", true, false)
	

	if main_viewport.get_child_count() > 0:
		var current_child = main_viewport.get_child(0)
		main_viewport.remove_child(current_child)
		current_child.queue_free()


	var new_scene = scenes[scene].instantiate()
	main_viewport.add_child(new_scene)
