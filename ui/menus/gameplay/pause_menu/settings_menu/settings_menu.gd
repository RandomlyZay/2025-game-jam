extends Control

@onready var fullscreen_check: CheckBox = $VBoxContainer/FullscreenCheck
@onready var music_slider: HSlider = $VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/SFXSlider
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	connect_signals()
	load_settings()
	
	InputManager.input_mode_changed.connect(_on_input_mode_changed)
	_on_input_mode_changed(InputManager.get_current_mode())
	
	setup_focus()
	
	# Set up initial focus for controller support
	back_button.focus_mode = Control.FOCUS_ALL
	back_button.grab_focus()
	
	# Handle UI cancel action 
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	
	# Listen for settings changes from other menus
	SettingsManager.settings_changed.connect(_on_settings_changed)

func connect_signals() -> void:
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

func load_settings() -> void:
	fullscreen_check.button_pressed = SettingsManager.fullscreen
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume

func setup_focus() -> void:
	# Setup focus neighbors
	fullscreen_check.focus_neighbor_top = fullscreen_check.get_path_to(back_button)
	fullscreen_check.focus_neighbor_bottom = fullscreen_check.get_path_to(back_button)
	
	back_button.focus_neighbor_top = back_button.get_path_to(fullscreen_check)
	back_button.focus_neighbor_bottom = back_button.get_path_to(fullscreen_check)
	
	# Setup focus next/previous
	fullscreen_check.focus_next = fullscreen_check.get_path_to(back_button)
	fullscreen_check.focus_previous = fullscreen_check.get_path_to(back_button)
	
	back_button.focus_next = back_button.get_path_to(fullscreen_check)
	back_button.focus_previous = back_button.get_path_to(fullscreen_check)

func _on_fullscreen_toggled(button_pressed: bool) -> void:
	SettingsManager.set_fullscreen(button_pressed)

func _on_back_pressed() -> void:
	hide()  # Hide settings menu
	var pause_menu = get_parent()
	pause_menu.background.show()  # Show pause menu background
	pause_menu.center_container.show()  # Show pause menu buttons

func _on_input_mode_changed(mode: String) -> void:
	if mode == "controller":
		fullscreen_check.grab_focus()

func _on_music_volume_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _on_settings_changed() -> void:
	# Update UI to match current settings
	if fullscreen_check.button_pressed != SettingsManager.fullscreen:
		fullscreen_check.button_pressed = SettingsManager.fullscreen
	if music_slider.value != SettingsManager.music_volume:
		music_slider.value = SettingsManager.music_volume
	if sfx_slider.value != SettingsManager.sfx_volume:
		sfx_slider.value = SettingsManager.sfx_volume
