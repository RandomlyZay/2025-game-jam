# 2025 Game Jam - Developer Documentation

## Project Structure

### Core Directories
- `/stages` - Game levels and scenes
  - `/level1` - First level implementation with scene file (`.tscn`) and script (`.gd`)
  - Contains level-specific dialogue in `/dialogues`

- `/entities` - Game objects and characters
  - `/characters` - Player and NPC implementations
	- `/player` - Player character implementation
	- `/enemies` - Enemy types and behaviors
  - `/items` - Collectibles and interactive objects

- `/global` - Singleton managers and utilities
  - `audio_manager.gd` - Handles all game audio
  - `settings_manager.gd` - Manages game settings
  - `input_manager.gd` - Input handling and device switching
  - `ui_manager.gd` - UI state and management

- `/ui` - User interface elements
  - `/menus/main_menu` - Main menu implementation

- `/graphics` - Art assets and resources
- `/audio` - Sound effects and music
  - `/sfx` - Sound effects (.wav, .ogg)
  - `/music` - Music tracks (.ogg, .wav)

## Core Systems

### Player System
- Health system with signals for health changes and death
- Movement mechanics:
  - Base speed: 500 units/sec
  - Knockback system with resistance (30%) and recovery
  - Dash ability:
	- Speed: 1500 units/sec
	- Duration: 0.2 seconds
	- Cooldown: 0.5 seconds
	- Temporary invincibility (0.3 seconds)

### Audio System
- Three audio buses: Master, Music, and SFX
- Volume control for each bus with dB conversion
- Music features:
  - Transition types: instant, crossfade, fade_out_in
  - Position memory for music tracks
  - Customizable transition durations
- SFX features:
  - Positional audio support
  - Pitch adjustment
  - Random SFX playback from lists

### Settings System
- Persistent settings management
- Audio volume control (0-100% range)
- Display mode management (fullscreen/windowed)
- Settings auto-save and load
- Signal system for settings changes

### Input System
- Supports keyboard/mouse and controller input
- Automatic input mode switching based on last used device
- Controller support with configurable deadzone (currently 0.5)
- Key bindings:
  - Movement: WASD / Left Stick
  - Dash: Spacebar / Controller Button 2
  - UI Accept: Enter/Space/Controller A
  - UI Cancel: Escape/Controller B

### Display Settings
- Default viewport: 1152x648
- Transparent background enabled
- Fullscreen mode enabled by default (window/size/mode=3)
- Pixel art optimized with default texture filter

### UI System
- Menu Structure:
  - Main Menu:
	- Play, Controls, Settings, Credits, and Quit options
	- Automatic controller focus management
	- Responsive to input mode changes
  - Gameplay Menus:
	- Pause Menu (triggered by ESC/Controller Start)
	- Game Over Menu
  - HUD Elements:
	- Health bar
	- Dialogue box system

### Menu Navigation
- Keyboard/Mouse:
  - Direct click interaction
  - Tab navigation support
- Controller:
  - Automatic focus management
  - Circular navigation (last to first item)
  - Consistent button mapping across menus

### Dialogue System
- JSON-based dialogue data structure
- Features:
  - Character-by-character text animation
  - Configurable dialogue speed (default: 0.05s per character)
  - Speaker name support
  - Skip functionality (ui_accept action)
  - Sound effects per character with pitch variation
  - Custom event triggers
- File Structure:
  - Dialogue files stored in `stages/[stage_name]/dialogues/`
  - JSON format for dialogue sequences
- Signals:
  - `dialogue_finished` - Emitted when dialogue sequence ends
  - `custom_event` - For triggering game events from dialogue

## Development Guidelines

### Scene Organization
- Main scenes are in the `/stages` directory
- Each level should have its own directory with:
  - `.tscn` file for scene layout
  - `.gd` script for level logic
  - `/dialogues` subfolder for level-specific dialogue

### Audio Guidelines
1. Place audio files in appropriate directories:
   - Sound effects: `res://audio/sfx/`
   - Music: `res://audio/music/`
2. Use the Audio singleton for all sound playback
3. Implement volume controls through the Settings manager

### Asset Licensing
- **Code**: Licensed under the MIT License. See [LICENSE](LICENSE).  
- **Assets (Music & Art)**: Licensed under Creative Commons BY-NC 4.0. See [ASSETS_LICENSE.md](ASSETS_LICENSE.md).

### UI Development Guidelines
1. Menu Creation:
   - Place menu scenes in `/ui/menus/`
   - Implement controller focus navigation
   - Connect to input mode changes
2. HUD Elements:
   - Initialize through UI Manager
   - Use signal system for updates
3. Dialogue Implementation:
   - Store dialogue data in level-specific `/dialogues`
   - Use UI Manager's dialogue methods for display

### Dialogue Development
1. File Structure:
   - Create JSON files in stage-specific dialogue folders
   - Follow the format:
	 ```json
	 [
	   {
		 "speaker": "Character Name",
		 "text": "Dialogue text",
		 "sound": "text_sound",  // Optional
		 "pitch_range": [0.9, 1.1]  // Optional
	   }
	 ]
	 ```
2. Integration:
   - Load dialogues using `load_and_start_dialogue(stage_name, dialogue_name)`
   - Monitor dialogue state with `is_dialogue_active()`
   - Connect to dialogue signals for game flow control

## Getting Started
1. Open the project in Godot 4.3
2. Main scene is set to: `res://ui/menus/main_menu/main_menu.tscn`
3. Global autoloads are automatically configured in project settings
4. Check audio bus configuration in Project Settings > Audio

## Debugging Tips
- Input mode changes can be monitored through the `input_mode_changed` signal
- Mouse movement threshold for input switching: 5.0 pixels
- Controller deadzone: 0.5
- Audio debugging:
  - Check bus indices in Settings Manager
  - Monitor volume changes through settings_changed signal
- Player debugging:
  - Monitor health_changed and player_died signals
  - Watch dash cooldown and invincibility timers
- UI debugging:
  - Check menu focus with controller input
  - Monitor dialogue states through UI Manager
  - Verify pause menu exclusions during game over
- Dialogue debugging:
  - Check JSON file paths and format
  - Monitor dialogue signals
  - Verify sound configuration
  - Test skip functionality

---
*Note: This document was generated using AI. Please update it as the project evolves.*
