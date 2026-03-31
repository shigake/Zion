extends CanvasLayer

## Boss dialogue overlay — shows intro, phase change, and death lines for Sentinelas.
## Uses typewriter effect and boss-themed border colors.
## Text sourced from LocaleManager for i18n support.

const BOSS_KEY_MAP := {
	"BossNecromancer": "necromancer",
	"BossFairyQueen": "fairy_queen",
	"BossAlienCow": "alien_cow",
	"BossAiOverlord": "ai_overlord",
	"BossDemonLord": "demon_lord",
	"BossLeviathan": "leviathan",
	"BossEmperor": "emperor",
	"BossSingularity": "singularity",
	"BossDracula": "dracula",
	"BossSugarKing": "sugar_king",
	# Alt bosses
	"BossCemeteryLich": "cemetery_lich",
	"BossCemeteryReaper": "cemetery_reaper",
	"BossForestElder": "forest_elder",
	"BossForestSpider": "forest_spider",
	"BossFarmScarecrow": "farm_scarecrow",
	"BossFarmHarvester": "farm_harvester",
	"BossTokyoShogun": "tokyo_shogun",
	"BossTokyoKaiju": "tokyo_kaiju",
	"BossVolcanoPhoenix": "volcano_phoenix",
	"BossVolcanoTitan": "volcano_titan",
	"BossOceanSiren": "ocean_siren",
	"BossOceanHydra": "ocean_hydra",
	"BossArenaMinotaur": "arena_minotaur",
	"BossArenaChimera": "arena_chimera",
	"BossSpaceHivemind": "space_hivemind",
	"BossSpaceWarden": "space_warden",
	"BossCastleWerewolf": "castle_werewolf",
	"BossCastleBanshee": "castle_banshee",
	"BossCandyWitch": "candy_witch",
	"BossCandyDragon": "candy_dragon",
}

## Border color per boss — matches their elemental identity
const BOSS_COLORS := {
	"necromancer": Color(0.5, 0.1, 0.7, 0.8),    # Purple (dark/death)
	"fairy_queen": Color(0.2, 0.8, 0.3, 0.8),     # Green (nature)
	"alien_cow": Color(0.3, 1.0, 0.3, 0.8),       # Bright green (alien)
	"ai_overlord": Color(0.2, 0.8, 1.0, 0.8),     # Cyan (tech)
	"demon_lord": Color(1.0, 0.3, 0.1, 0.8),      # Red-orange (fire)
	"leviathan": Color(0.1, 0.4, 0.9, 0.8),       # Deep blue (ocean)
	"emperor": Color(0.9, 0.7, 0.2, 0.8),         # Gold (arena)
	"singularity": Color(0.6, 0.2, 1.0, 0.8),     # Violet (space)
	"dracula": Color(0.7, 0.0, 0.1, 0.8),         # Dark red (blood)
	"sugar_king": Color(1.0, 0.5, 0.7, 0.8),      # Pink (candy)
	# Alt bosses
	"cemetery_lich": Color(0.3, 0.8, 0.3, 0.8),
	"cemetery_reaper": Color(0.3, 0.1, 0.15, 0.8),
	"forest_elder": Color(0.3, 0.6, 0.15, 0.8),
	"forest_spider": Color(0.5, 0.15, 0.6, 0.8),
	"farm_scarecrow": Color(0.7, 0.5, 0.15, 0.8),
	"farm_harvester": Color(0.4, 0.4, 0.4, 0.8),
	"tokyo_shogun": Color(0.8, 0.15, 0.3, 0.8),
	"tokyo_kaiju": Color(0.2, 0.7, 0.3, 0.8),
	"volcano_phoenix": Color(1.0, 0.6, 0.1, 0.8),
	"volcano_titan": Color(0.5, 0.15, 0.05, 0.8),
	"ocean_siren": Color(0.3, 0.7, 0.9, 0.8),
	"ocean_hydra": Color(0.15, 0.25, 0.5, 0.8),
	"arena_minotaur": Color(0.6, 0.35, 0.15, 0.8),
	"arena_chimera": Color(0.5, 0.25, 0.6, 0.8),
	"space_hivemind": Color(0.2, 0.8, 0.2, 0.8),
	"space_warden": Color(0.4, 0.25, 0.8, 0.8),
	"castle_werewolf": Color(0.4, 0.3, 0.2, 0.8),
	"castle_banshee": Color(0.5, 0.7, 0.9, 0.8),
	"candy_witch": Color(0.9, 0.35, 0.7, 0.8),
	"candy_dragon": Color(0.25, 0.8, 0.45, 0.8),
}

## Stage-to-boss key for LocaleManager title lookup
const STAGE_BOSS_MAP := {
	"necromancer": "cemetery",
	"fairy_queen": "forest",
	"alien_cow": "farm",
	"ai_overlord": "tokyo",
	"demon_lord": "volcano",
	"leviathan": "ocean",
	"emperor": "arena",
	"singularity": "space",
	"dracula": "castle",
	"sugar_king": "candy",
}

var _panel: PanelContainer
var _title_label: Label
var _body_label: Label
var _dismiss_timer: Timer
var _visible: bool = false
var _typewriter_tween: Tween = null
var _full_text: String = ""
var _stylebox: StyleBoxFlat

func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Build UI
	_panel = PanelContainer.new()
	_panel.name = "BossDialoguePanel"
	_stylebox = StyleBoxFlat.new()
	_stylebox.bg_color = Color(0.0, 0.0, 0.0, 0.9)
	_stylebox.corner_radius_top_left = 10
	_stylebox.corner_radius_top_right = 10
	_stylebox.corner_radius_bottom_left = 10
	_stylebox.corner_radius_bottom_right = 10
	_stylebox.content_margin_left = 28.0
	_stylebox.content_margin_right = 28.0
	_stylebox.content_margin_top = 14.0
	_stylebox.content_margin_bottom = 16.0
	_stylebox.border_width_top = 2
	_stylebox.border_width_bottom = 2
	_stylebox.border_width_left = 2
	_stylebox.border_width_right = 2
	_stylebox.border_color = Color(0.8, 0.2, 0.2, 0.7)
	_panel.add_theme_stylebox_override("panel", _stylebox)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	# Sentinel title
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	_title_label.uppercase = true
	vbox.add_child(_title_label)

	# Dialogue text
	_body_label = Label.new()
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_body_label.add_theme_font_size_override("font_size", 22)
	_body_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_body_label)

	_panel.add_child(vbox)

	# Center at bottom of screen
	_panel.anchors_preset = Control.PRESET_CENTER_BOTTOM
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_bottom = -40.0
	_panel.offset_top = -140.0

	_panel.visible = false
	add_child(_panel)

	# Auto-dismiss timer
	_dismiss_timer = Timer.new()
	_dismiss_timer.one_shot = true
	_dismiss_timer.wait_time = 4.0
	_dismiss_timer.timeout.connect(_dismiss)
	add_child(_dismiss_timer)

	# Connect signals
	GameManager.boss_spawned.connect(_on_boss_spawned)
	GameManager.boss_died.connect(_on_boss_died)
	GameManager.boss_phase_changed.connect(_on_boss_phase_changed)

func _on_boss_spawned(boss_name: String) -> void:
	var key = _get_boss_key(boss_name)
	if key.is_empty():
		return
	var title = _get_boss_title(key)
	var text = LocaleManager.tr_key("boss_intro_" + key)
	_show_dialogue(title, text, key)

func _on_boss_died(boss_name: String) -> void:
	var key = _get_boss_key(boss_name)
	if key.is_empty():
		return
	var title = _get_boss_title(key)
	var text = LocaleManager.tr_key("boss_death_" + key)
	_show_dialogue(title, text, key)

func _on_boss_phase_changed(boss_name: String, phase: int) -> void:
	if phase < 2:
		return
	var key = _get_boss_key(boss_name)
	if key.is_empty():
		return
	var locale_key = "boss_phase" + str(phase) + "_" + key
	var text = LocaleManager.tr_key(locale_key)
	if text == locale_key:
		return  # No translation found
	var title = _get_boss_title(key)
	_show_dialogue(title, text, key)

func _get_boss_key(boss_name: String) -> String:
	var clean = boss_name.split("@")[0].strip_edges().replace(" ", "")
	if BOSS_KEY_MAP.has(clean):
		return BOSS_KEY_MAP[clean]
	return ""

func _get_boss_title(key: String) -> String:
	var stage = STAGE_BOSS_MAP.get(key, "")
	if stage.is_empty():
		return ""
	return LocaleManager.tr_key("boss_" + stage)

func _show_dialogue(title: String, text: String, boss_key: String) -> void:
	# Update border color per boss
	var border_color = BOSS_COLORS.get(boss_key, Color(0.8, 0.2, 0.2, 0.7))
	_stylebox.border_color = border_color
	_title_label.add_theme_color_override("font_color", Color(border_color.r * 0.9 + 0.1, border_color.g * 0.9 + 0.1, border_color.b * 0.9 + 0.1))

	_title_label.text = title
	_full_text = text
	_body_label.text = ""
	_panel.visible = true
	_visible = true
	_dismiss_timer.wait_time = 4.0
	_dismiss_timer.start()

	# Fade-in
	_panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(_panel, "modulate", Color(1, 1, 1, 1), 0.3)

	# Typewriter effect
	_start_typewriter(text)

func _start_typewriter(text: String) -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	_body_label.text = ""
	_body_label.visible_characters = 0
	_body_label.text = text
	var char_count = text.length()
	var duration = char_count * 0.03  # 30ms per character
	duration = clampf(duration, 0.5, 3.0)
	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(_body_label, "visible_characters", char_count, duration)

func _dismiss() -> void:
	if not _visible:
		return
	_visible = false
	_dismiss_timer.stop()
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	var tween = create_tween()
	tween.tween_property(_panel, "modulate", Color(1, 1, 1, 0), 0.25)
	tween.tween_callback(func(): _panel.visible = false)

func _unhandled_input(event: InputEvent) -> void:
	if _visible and (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton):
		if event.is_pressed():
			# If typewriter still running, show full text instead of dismissing
			if _typewriter_tween and _typewriter_tween.is_valid():
				_typewriter_tween.kill()
				_body_label.visible_characters = -1
				# Reset dismiss timer so player can read
				_dismiss_timer.start()
			else:
				_dismiss()
			get_viewport().set_input_as_handled()
