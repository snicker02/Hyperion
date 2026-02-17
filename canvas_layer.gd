extends CanvasLayer

@export var fractal_mesh: MeshInstance3D
@export var main_camera: Camera3D
var waypoints: Array = []
var _pending_screenshot: Image
var time: float = 0.0 # Manual clock for the fractal
var mandelbox_shader = preload("res://Mandelbox4D.gdshader")
var menger_shader = preload("res://menger.gdshader")
var animation_tween: Tween # This allows us to pause and step the animation
@onready var save_video_dialog = %SaveVideoDialog # Create a FileDialog in your scene
# Track which fractal is currently active
var current_fractal: String = "Mandelbox" # Default to Mandelbox

# Core Menger 4D Sliders
@onready var menger_scale_slider = %MengerScaleSlider
@onready var menger_offset_w_slider = %OffsetWSlider
@onready var menger_iterations_slider = %IterationsSlider
@onready var menger_rotation_slider = %Rotations4DSlider

# Menger Offset 1 (X, Y, Z, W)
@onready var menger_ox_slider = %MengerOffset1_xSlider
@onready var menger_oy_slider = %MengerOffset1_ySlider
@onready var menger_oz_slider = %MengerOffset1_zSlider
@onready var menger_ow_slider = %MengerOffset1_wSlider

# Menger Julia 4D
@onready var menger_julia_toggle = %MS4DJuliaToggle
@onready var menger_morph_slider = %MS4DMorphSlider
@onready var menger_jx_slider = %MS4DJuliaXSlider
@onready var menger_jy_slider = %MS4DJuliaYSlider
@onready var menger_jz_slider = %MS4DJuliaZSlider
@onready var menger_jw_slider = %MS4DJuliaWSlider

var is_recording: bool = false
var frame_counter: int = 0
var recording_dir: String = "user://recordings"
@onready var record_timer = %RecordTimer # Make sure you added this Timer node

@onready var background_texture = %BackgroundTexture
@onready var bg_file_dialog = %SaveDialog # You can reuse your SaveDialog or create a new one



func _ready():
	if has_node("%ColorPicker1"):
		%ColorPicker1.color_changed.connect(func(c): 
			get_fractal_material().set_shader_parameter("Color1", Vector3(c.r, c.g, c.b)))
	if has_node("%ColorPicker2"):
		%ColorPicker2.color_changed.connect(func(c): 
			get_fractal_material().set_shader_parameter("Color2", Vector3(c.r, c.g, c.b)))
	if has_node("%ColorPicker3"):
		%ColorPicker3.color_changed.connect(func(c): 
			get_fractal_material().set_shader_parameter("Color3", Vector3(c.r, c.g, c.b)))
	var mat = get_fractal_material()
	
	# Set initial fractal based on current shader
	if mat and mat.shader:
		if "menger" in mat.shader.resource_path.to_lower():
			current_fractal = "Menger"
		else:
			current_fractal = "Mandelbox"
	
	setup_navigation_tree()
	
	# Connect the Tree's selection signal
	if has_node("%NavigationTree"):
		%NavigationTree.item_selected.connect(_on_tree_item_selected)
	
	# Connect all UI elements using Unique Names (%)
	if has_node("%TypeSelector"): 
		%TypeSelector.item_selected.connect(_on_inv_type_selected)
	if has_node("%ScaleSlider"): 
		%ScaleSlider.value_changed.connect(_on_scale_changed)
	if has_node("%WSlider"): 
		%WSlider.value_changed.connect(_on_w_changed)
	if has_node("%ColorCycleSlider"): 
		%ColorCycleSlider.value_changed.connect(_on_color_cycle_changed)
	if has_node("%PaletteSelector"): 
		%PaletteSelector.item_selected.connect(_on_palette_selected)
	if has_node("%StepsSlider"): 
		%StepsSlider.value_changed.connect(_on_steps_changed)
	if has_node("%DetailSlider"): 
		%DetailSlider.value_changed.connect(_on_detail_changed)
	
	if has_node("%JuliaXSlider"):
		%JuliaXSlider.value_changed.connect(_on_julia_slider_changed)
	if has_node("%JuliaYSlider"):
		%JuliaYSlider.value_changed.connect(_on_julia_slider_changed)
	if has_node("%JuliaZSlider"):
		%JuliaZSlider.value_changed.connect(_on_julia_slider_changed)
	
	if has_node("%SidesSlider"):
		%SidesSlider.value_changed.connect(_on_sides_changed)
		# Set initial label
		_update_sides_label(%SidesSlider.value)
	
	if has_node("%JuliaToggle"):
		%JuliaToggle.toggled.connect(_on_julia_toggled)
	
	if has_node("%ReflectSlider"):
		%ReflectSlider.value_changed.connect(_on_reflect_changed)
	if has_node("%FogSlider"):
		%FogSlider.value_changed.connect(_on_fog_changed)
	if has_node("%SpeedSlider"):
		%SpeedSlider.value_changed.connect(_on_speed_changed)
	if has_node("%RotationSlider"):
		%RotationSlider.value_changed.connect(_on_rotation_changed)
	
	if has_node("%InvParamA") and mat:
		%InvParamA.value_changed.connect(_on_inv_param_a_changed)
		var inv_param_a = mat.get_shader_parameter("InvParamA")
		if inv_param_a != null:
			%InvParamA.value = inv_param_a
			_on_inv_param_a_changed(inv_param_a)
	
	if has_node("%FixedRadiusSlider") and mat:
		%FixedRadiusSlider.value_changed.connect(_on_fixed_radius_changed)
		var inv_scale = mat.get_shader_parameter("InvScale")
		if inv_scale != null:
			%FixedRadiusSlider.value = inv_scale
			_on_fixed_radius_changed(inv_scale)
	
	# Connect Symmetry Toggles
	if has_node("%AbsXToggle"):
		%AbsXToggle.toggled.connect(func(v): get_fractal_material().set_shader_parameter("F_absX", v))
	if has_node("%AbsYToggle"):
		%AbsYToggle.toggled.connect(func(v): get_fractal_material().set_shader_parameter("F_absY", v))
	if has_node("%AbsZToggle"):
		%AbsZToggle.toggled.connect(func(v): get_fractal_material().set_shader_parameter("F_absZ", v))
	
	if has_node("%XSwapToggle"):
		%XSwapToggle.toggled.connect(func(v): get_fractal_material().set_shader_parameter("F_X", v))
	if has_node("%YSwapToggle"):
		%YSwapToggle.toggled.connect(func(v): get_fractal_material().set_shader_parameter("F_Y", v))
	if has_node("%ZSwapToggle"):
		%ZSwapToggle.toggled.connect(func(v): get_fractal_material().set_shader_parameter("F_Z", v))
	
	# Connect Symmetry Sliders
	if has_node("%PFiveSlider"):
		%PFiveSlider.value_changed.connect(_on_pfive_changed)
	if has_node("%FoldOffsetSlider"):
		%FoldOffsetSlider.value_changed.connect(_on_fold_offset_changed)
	
	if has_node("%MengerToggle"):
		%MengerToggle.toggled.connect(_on_menger_toggled)
	
	# Buttons
	if has_node("%ResetButton"): 
		%ResetButton.pressed.connect(_on_reset_pressed)
	if has_node("%ScreenshotButton"): 
		%ScreenshotButton.pressed.connect(_on_screenshot_pressed)
	
	# Save Dialog
	if has_node("%SaveDialog"): 
		%SaveDialog.file_selected.connect(_on_dir_selected)
	
	# Initialize all labels to match the current shader state
	if mat:
		# Force the shader values to 0 for reflectivity and fog
		mat.set_shader_parameter("Reflectivity", 0.0)
		mat.set_shader_parameter("FogDensity", 0.0)
		
		# Manually update the labels to 0.0 text
		if has_node("%ReflectLabel"):
			%ReflectLabel.text = "Reflectivity: 0.0"
		if has_node("%FogLabel"):
			%FogLabel.text = "Fog Density: 0.0"
		
		# Set the sliders themselves to 0
		if has_node("%ReflectSlider"):
			%ReflectSlider.value = 0.0
		if has_node("%FogSlider"):
			%FogSlider.value = 0.0
		
		var current_seed = mat.get_shader_parameter("JuliaSeed")
		var scale_val = mat.get_shader_parameter("Scale")
		var offset_w = mat.get_shader_parameter("OffsetW")
		var sides_val = mat.get_shader_parameter("InvParamB")
		var max_steps = mat.get_shader_parameter("MaxSteps")
		var detail_val = mat.get_shader_parameter("Detail")
		
		# Sync the sliders and labels to the shader's default values
		if has_node("%ScaleSlider") and scale_val != null:
			%ScaleSlider.value = scale_val
			_on_scale_changed(scale_val)
		
		if has_node("%WSlider") and offset_w != null:
			%WSlider.value = offset_w
			_on_w_changed(offset_w)
		
		if has_node("%SidesSlider") and sides_val != null:
			%SidesSlider.value = sides_val
			_on_sides_changed(sides_val)
		
		# Sync Reflectivity
		if has_node("%ReflectSlider"):
			var r_val = mat.get_shader_parameter("Reflectivity")
			if r_val != null:
				%ReflectSlider.value = r_val
				_on_reflect_changed(r_val)
		
		# Sync Fog
		if has_node("%FogSlider"):
			var f_val = mat.get_shader_parameter("FogDensity")
			if f_val != null:
				%FogSlider.value = f_val
				_on_fog_changed(f_val)
		
		# Set initial text for the static labels
		if max_steps != null:
			_update_steps_label(max_steps)
		if detail_val != null:
			_update_detail_label(detail_val)
		
		if current_seed != null:
			if has_node("%JuliaXSlider"):
				%JuliaXSlider.value = current_seed.x
			if has_node("%JuliaYSlider"):
				%JuliaYSlider.value = current_seed.y
			if has_node("%JuliaZSlider"):
				%JuliaZSlider.value = current_seed.z
	
	_on_julia_slider_changed(0.0) # Refresh labels
	
	if has_node("%TypeSelector"):
		%TypeSelector.selected = 0
	
	if has_node("%PaletteSelector"):
		%PaletteSelector.selected = 0
	
	if has_node("%ResolutionSelector"):
		%ResolutionSelector.selected = 0
	
	if has_node("%SpeedSlider"):
		_on_speed_changed(%SpeedSlider.value)
	
	# Connect Menger sliders - with null checks
	if menger_scale_slider:
		menger_scale_slider.value_changed.connect(_update_menger)
	if menger_offset_w_slider:
		menger_offset_w_slider.value_changed.connect(_update_menger)
	if menger_iterations_slider:
		menger_iterations_slider.value_changed.connect(_update_menger)
	if menger_rotation_slider:
		menger_rotation_slider.value_changed.connect(_update_menger)
	
	# Menger Offset 1 (X, Y, Z, W)
	if menger_ox_slider:
		menger_ox_slider.value_changed.connect(_update_menger)
	if menger_oy_slider:
		menger_oy_slider.value_changed.connect(_update_menger)
	if menger_oz_slider:
		menger_oz_slider.value_changed.connect(_update_menger)
	if menger_ow_slider:
		menger_ow_slider.value_changed.connect(_update_menger)
	
	# Menger Julia 4D
	if menger_julia_toggle:
		menger_julia_toggle.toggled.connect(_update_menger)
	if menger_morph_slider:
		menger_morph_slider.value_changed.connect(_update_menger)
	if menger_jx_slider:
		menger_jx_slider.value_changed.connect(_update_menger)
	if menger_jy_slider:
		menger_jy_slider.value_changed.connect(_update_menger)
	if menger_jz_slider:
		menger_jz_slider.value_changed.connect(_update_menger)
	if menger_jw_slider:
		menger_jw_slider.value_changed.connect(_update_menger)
		
		
		
	if has_node("%SaturationSlider"):
		%SaturationSlider.value_changed.connect(_on_saturation_changed)
		# Set initial label
		_on_saturation_changed(%SaturationSlider.value)

	if has_node("%ContrastSlider"):
		%ContrastSlider.value_changed.connect(_on_contrast_changed)
		_on_contrast_changed(%ContrastSlider.value)

	if has_node("%BrightnessSlider"):
		%BrightnessSlider.value_changed.connect(_on_brightness_changed)
		_on_brightness_changed(%BrightnessSlider.value)
		
		
	_on_palette_selected(%PaletteSelector.selected)
	# Animation System Connections
	if has_node("%AddWaypointButton"):
		%AddWaypointButton.pressed.connect(_on_add_waypoint_pressed)
		
	if has_node("%PlayAnimationButton"):
		%PlayAnimationButton.pressed.connect(play_flythrough)
		
	if has_node("%ClearPathButton"):
		%ClearPathButton.pressed.connect(_on_clear_path_pressed)
	if has_node("%RecordButton"):
		%RecordButton.toggled.connect(_on_record_button_toggled)
		
	if has_node("%RecordTimer"):
		%RecordTimer.timeout.connect(_on_record_timer_timeout)
		
	if has_node("%SaveVideoDialog"):
		%SaveVideoDialog.file_selected.connect(_on_save_video_dialog_file_selected)
	if has_node("%OverlayStopButton"):
		%OverlayStopButton.pressed.connect(func(): %RecordButton.button_pressed = false)
	
# Add a button connection for "Change Background"
	if has_node("%ChangeBGButton"):
		%ChangeBGButton.pressed.connect(_on_change_bg_pressed)
	
	# Connect the dialog specifically for loading
	bg_file_dialog.file_selected.connect(_on_bg_image_selected)

func _on_change_bg_pressed():
	bg_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	bg_file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg ; Images"])
	bg_file_dialog.popup_centered()
	
func _on_bg_image_selected(path: String):
	var img = Image.load_from_file(path)
	
	# Create a horizontally mirrored seamless texture
	var width = img.get_width()
	var height = img.get_height()
	var seamless_img = Image.create(width * 2, height, false, img.get_format())
	
	# Copy original to left half
	seamless_img.blit_rect(img, Rect2i(0, 0, width, height), Vector2i(0, 0))
	
	# Mirror it to the right half
	for x in range(width):
		for y in range(height):
			var color = img.get_pixel(width - 1 - x, y)
			seamless_img.set_pixel(width + x, y, color)
	
	# Set it as the 3D environment background
	var world_env = get_node_or_null("../WorldEnvironment")
	if world_env and world_env.environment:
		var sky = Sky.new()
		var sky_material = PanoramaSkyMaterial.new()
		sky_material.panorama = ImageTexture.create_from_image(seamless_img)
		sky.sky_material = sky_material
		
		world_env.environment.background_mode = Environment.BG_SKY
		world_env.environment.sky = sky
		


	
	
	
# --- Logic Functions ---
func setup_navigation_tree():
	%NavigationTree.clear()
	var root = %NavigationTree.create_item()
	%NavigationTree.hide_root = true
	
	# --- GLOBAL SETTINGS ---
	var global_node = %NavigationTree.create_item(root)
	global_node.set_text(0, "Global Settings")
	global_node.set_selectable(0, false)
	
	var cam = %NavigationTree.create_item(global_node)
	cam.set_text(0, "Camera & Speed")
	cam.set_metadata(0, 0)
	
	var env = %NavigationTree.create_item(global_node)
	env.set_text(0, "Environment & Glow")
	env.set_metadata(0, 1)
	
	# --- FRACTALS (Visually Nested) ---
	var fractal_node = %NavigationTree.create_item(root)
	fractal_node.set_text(0, "Fractals")
	fractal_node.set_selectable(0, false)
	
	var mandel = %NavigationTree.create_item(fractal_node)
	mandel.set_text(0, "Mandelbox")
	mandel.set_metadata(0, 2) # Mandelbox4D tab index
	
	var menger = %NavigationTree.create_item(fractal_node)
	menger.set_text(0, "Menger4D")
	menger.set_metadata(0, 3) # Menger4D tab index
	
	# --- SYMMETRY ---
	var sym = %NavigationTree.create_item(root)
	sym.set_text(0, "Symmetry Folding")
	sym.set_metadata(0, 4) # Symmetry tab index

func _on_speed_changed(value: float):
	# Find your Camera3D node - adjust the path if necessary
	var camera = get_viewport().get_camera_3d() 
	if camera and "fly_speed" in camera:
		camera.fly_speed = value
	
	# Update the label text
	if has_node("%SpeedLabel"):
		%SpeedLabel.text = "Fly Speed: " + str(snapped(value, 0.01))

func _on_julia_slider_changed(_value: float):
	var mat = get_fractal_material()
	if mat and has_node("%JuliaXSlider") and has_node("%JuliaYSlider") and has_node("%JuliaZSlider"):
		# Create a new vector from the three slider values
		var current_seed = mat.get_shader_parameter("JuliaSeed")
		var new_seed = Vector4(
			%JuliaXSlider.value,
			%JuliaYSlider.value,
			%JuliaZSlider.value,
			current_seed.w if current_seed else 0.0 # Keep W as is
		)
		mat.set_shader_parameter("JuliaSeed", new_seed)
		
		# Update Labels
		if has_node("%JuliaXLabel"):
			%JuliaXLabel.text = "Julia X: " + str(snapped(new_seed.x, 0.01))
		if has_node("%JuliaYLabel"):
			%JuliaYLabel.text = "Julia Y: " + str(snapped(new_seed.y, 0.01))
		if has_node("%JuliaZLabel"):
			%JuliaZLabel.text = "Julia Z: " + str(snapped(new_seed.z, 0.01))

func _on_reflect_changed(value: float):
	var mat = get_fractal_material()
	if mat:
		mat.set_shader_parameter("Reflectivity", value)
	
	if has_node("%ReflectLabel"):
		%ReflectLabel.text = "Reflectivity: " + str(snapped(value, 0.01))

func _on_fog_changed(value: float):
	var mat = get_fractal_material()
	if mat:
		mat.set_shader_parameter("FogDensity", value)
	
	if has_node("%FogLabel"):
		%FogLabel.text = "Fog Density: " + str(snapped(value, 0.001))

func _on_julia_toggled(button_pressed: bool):
	var mat = get_fractal_material()
	if mat:
		mat.set_shader_parameter("JuliaMode", button_pressed)

func _update_steps_label(value: float):
	if has_node("%StepsLabel"):
		%StepsLabel.text = "Max Steps: " + str(int(value))

func _update_detail_label(value: float):
	if has_node("%DetailLabel"):
		%DetailLabel.text = "Detail: " + str(snapped(value, 0.1))

func get_fractal_material() -> ShaderMaterial:
	if not fractal_mesh: 
		return null
	var mat = fractal_mesh.get_active_material(0)
	return mat as ShaderMaterial

func _input(event):
	# Press 'H' to toggle UI visibility
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		if has_node("%PanelContainer"):
			%PanelContainer.visible = !%PanelContainer.visible
	
	# Press F2 to toggle debug tools
	if event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		# Access the plugin via the absolute root path
		var rdt = get_node_or_null("/root/RuntimeDebugTools")
		
		if rdt:
			var ui = rdt.get_node_or_null("DebugUI")
			if ui:
				ui.visible = !ui.visible
				# Free the mouse so you can click the UI
				if ui.visible:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				else:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				print("DebugUI child not found under RuntimeDebugTools")
		else:
			print("RuntimeDebugTools node not found at /root/")
	# If 'R' is pressed while recording, stop it
	if is_recording and event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			%RecordButton.button_pressed = false # Triggers the stop logic

func _on_reset_pressed():
	if main_camera:
		main_camera.global_position = Vector3(0, 0, 5)
		main_camera.rotation_degrees = Vector3.ZERO
		if main_camera.has_method("reset_internal_rotation"):
			main_camera.call("reset_internal_rotation")

func _on_screenshot_pressed():
	if not has_node("%PanelContainer") or not has_node("%ResolutionSelector"):
		return
	
	# 1. Get chosen resolution from the dropdown
	var res_index = %ResolutionSelector.selected
	var target_res = Vector2i(1920, 1080) # Default
	
	match res_index:
		1: target_res = Vector2i(3840, 2160) # 4K
		2: target_res = Vector2i(7680, 4320) # 8K
	
	# 2. Hide UI
	%PanelContainer.visible = false
	
	# 3. Setup Viewport
	if not has_node("%HighResViewport"):
		return
	var high_res_v = %HighResViewport
	high_res_v.size = target_res
	
	# 4. Sync Cameras
	if main_camera and has_node("%HighResViewport/Camera3D"):
		var hr_cam = %HighResViewport/Camera3D
		hr_cam.global_transform = main_camera.global_transform
		hr_cam.fov = main_camera.fov
	
	# 5. Capture Frame
	if has_node("%RenderContainer"):
		%RenderContainer.visible = true
	await RenderingServer.frame_post_draw
	_pending_screenshot = high_res_v.get_texture().get_image()
	
	# 6. Cleanup
	if has_node("%RenderContainer"):
		%RenderContainer.visible = false
	%PanelContainer.visible = true
	
	if has_node("%SaveDialog"):
		# Set default filename with timestamp and fractal type
		var timestamp = str(Time.get_unix_time_from_system())
		var fractal_name = current_fractal.to_lower()
		%SaveDialog.current_file = fractal_name + "_" + timestamp + ".png"
		%SaveDialog.popup_centered()

func _on_dir_selected(path: String):
	if _pending_screenshot:
		if not path.ends_with(".png"): 
			path += ".png"
		_pending_screenshot.save_png(path)

# --- Parameter Updates ---

func _on_scale_changed(value):
	var mat = get_fractal_material()
	if mat: 
		mat.set_shader_parameter("Scale", value)
	
	if has_node("%ScaleLabel"):
		%ScaleLabel.text = "Scale: " + str(snapped(value, 0.01))

func _on_w_changed(value):
	var mat = get_fractal_material()
	if mat: 
		mat.set_shader_parameter("OffsetW", value)
	
	if has_node("%WLabel"):
		%WLabel.text = "4D Slice (W): " + str(snapped(value, 0.01))

func _on_steps_changed(value):
	var mat = get_fractal_material()
	if mat: 
		mat.set_shader_parameter("MaxSteps", int(value))
	
	if has_node("%StepsLabel"):
		%StepsLabel.text = "Max Steps: " + str(int(value))

func _on_detail_changed(value):
	var mat = get_fractal_material()
	if mat: 
		mat.set_shader_parameter("Detail", value)
	
	if has_node("%DetailLabel"):
		%DetailLabel.text = "Detail: " + str(snapped(value, 0.1))

func _on_color_cycle_changed(value):
	var mat = get_fractal_material()
	if mat: 
		mat.set_shader_parameter("ColorCycle", value)

func _on_palette_selected(index: int):
	var mat = get_fractal_material()
	if mat:
		mat.set_shader_parameter("PaletteType", index)
	
	# Hide color pickers unless "Custom Gradient" (Index 4) is chosen
	if has_node("%CustomColorContainer"):
		%CustomColorContainer.visible = (index == 4)

func _on_inv_type_selected(index):
	var mat = get_fractal_material()
	if mat:
		mat.set_shader_parameter("InvType", index)
	
	# Update label based on inversion type
	if has_node("%ParamALabel"):
		match index:
			7: # Toroidal
				%ParamALabel.text = "Major Radius (Donut Size)"
			8: # Amazing Box
				%ParamALabel.text = "Min Radius (Inversion)"
			_: # Default for all other types
				%ParamALabel.text = "Inversion Param A"

func _on_sides_changed(value: float):
	var mat = get_fractal_material()
	if mat:
		mat.set_shader_parameter("InvParamB", value)
	_update_sides_label(value)

func _update_sides_label(value: float):
	if has_node("%SidesLabel"):
		%SidesLabel.text = "Polygon Sides: " + str(int(value))

func _on_tree_item_selected():
	var selected = %NavigationTree.get_selected()
	if not selected: 
		return
	
	var tab_index = selected.get_metadata(0)
	if has_node("%TabContainer"):
		%TabContainer.current_tab = tab_index
	
	var mat = get_fractal_material()
	if not mat: 
		return
	
	# Swap shaders based on selection
	if selected.get_text(0) == "Menger4D":
		current_fractal = "Menger"
		mat.shader = menger_shader
		# Force reset Menger offsets to proper defaults
		mat.set_shader_parameter("MengerOffset1", Vector4(1.0, 1.0, 1.0, 1.0))
		mat.set_shader_parameter("OffsetW", 0.0)
		mat.set_shader_parameter("RotationAngle", 0.0)
		_update_menger()
	elif selected.get_text(0) == "Mandelbox":
		current_fractal = "Mandelbox"
		mat.shader = mandelbox_shader
		# Sync Mandelbox-specific parameters
		if has_node("%ScaleSlider"):
			_on_scale_changed(%ScaleSlider.value)
		if has_node("%WSlider"):
			_on_w_changed(%WSlider.value)
		if has_node("%RotationSlider"):
			_on_rotation_changed(%RotationSlider.value)
	
	# Update UI to show which fractal is active
	if has_node("%TabContainer"):
		if current_fractal == "Menger":
			print("Switched to Menger4D")
		else:
			print("Switched to Mandelbox")
	
	if OS.is_debug_build():
		diagnostic_check()

func _on_pfive_changed(value: float):
	var mat = get_fractal_material()
	if mat:
		# SymmetryStrength is the new name for pfive in the shader
		mat.set_shader_parameter("SymmetryStrength", Vector3(value, value, value))
	
	if has_node("%PFiveLabel"):
		%PFiveLabel.text = "Symmetry: " + str(snapped(value, 0.01))

func _on_fold_offset_changed(value: float):
	var mat = get_fractal_material()
	if mat:
		# Updating F_offset as a uniform vec3
		mat.set_shader_parameter("F_offset", Vector3(value, value, value))
	
	if has_node("%FoldOffsetLabel"):
		%FoldOffsetLabel.text = "Fold Offset: " + str(snapped(value, 0.01))

func _on_rotation_changed(value: float):
	var mat = get_fractal_material()
	if mat:
		mat.set_shader_parameter("RotationAngle", value)
	
	if has_node("%RotationLabel"):
		%RotationLabel.text = "4D Rotation: " + str(snapped(value, 0.01))

func _on_inv_param_a_changed(value: float):
	var mat = get_fractal_material()
	if mat: 
		mat.set_shader_parameter("InvParamA", value)
	
	if has_node("%ParamALabel"):
		%ParamALabel.text = "Min Radius: " + str(snapped(value, 0.01))

func _on_fixed_radius_changed(value: float):
	var mat = get_fractal_material()
	if mat: 
		mat.set_shader_parameter("InvScale", value)
	
	if has_node("%FixedRadiusLabel"):
		%FixedRadiusLabel.text = "Fixed Radius: " + str(snapped(value, 0.01))

func _on_menger_toggled(button_pressed: bool):
	var mat = get_fractal_material()
	if mat:
		mat.set_shader_parameter("MengerMode", button_pressed)

func _update_menger(_value = 0):
	var mat = get_fractal_material()
	if not mat: 
		return
	
	# Check if sliders exist before accessing them
	if not menger_scale_slider or not menger_offset_w_slider or not menger_iterations_slider:
		return
	if not menger_rotation_slider or not menger_julia_toggle or not menger_morph_slider:
		return
	
	# Set shader parameters from slider values
	mat.set_shader_parameter("MengerScale", menger_scale_slider.value)
	mat.set_shader_parameter("OffsetW", menger_offset_w_slider.value)
	mat.set_shader_parameter("Iterations", int(menger_iterations_slider.value))
	mat.set_shader_parameter("RotationAngle", menger_rotation_slider.value)
	mat.set_shader_parameter("JuliaMode", menger_julia_toggle.button_pressed)
	mat.set_shader_parameter("JuliaMorph", menger_morph_slider.value)
	
	# Update labels - Core Menger 4D
	if has_node("%MengerScalelabel"):
		%MengerScalelabel.text = "Sponge Scale: " + str(snapped(menger_scale_slider.value, 0.01))
	if has_node("%OffsetWlabel"):
		%OffsetWlabel.text = "4D Slice (W): " + str(snapped(menger_offset_w_slider.value, 0.01))
	if has_node("%Iterationslabel"):
		%Iterationslabel.text = "Complexity: " + str(int(menger_iterations_slider.value))
	if has_node("%Rotation4Dslabel"):
		%Rotation4Dslabel.text = "4D Rotation: " + str(snapped(menger_rotation_slider.value, 0.01))
	
	# Update Menger Offset 1 Vector Labels
	if menger_ox_slider and has_node("%MengerOffset1_xlabel"):
		%MengerOffset1_xlabel.text = "Offset X: " + str(snapped(menger_ox_slider.value, 0.01))
	if menger_oy_slider and has_node("%MengerOffset1_ylabel"):
		%MengerOffset1_ylabel.text = "Offset Y: " + str(snapped(menger_oy_slider.value, 0.01))
	if menger_oz_slider and has_node("%MengerOffset1_zlabel"):
		%MengerOffset1_zlabel.text = "Offset Z: " + str(snapped(menger_oz_slider.value, 0.01))
	if menger_ow_slider and has_node("%MengerOffset1_wlabel"):
		%MengerOffset1_wlabel.text = "Offset W: " + str(snapped(menger_ow_slider.value, 0.01))
	
	# Update MS4D Julia 4D Labels
	if menger_jx_slider and has_node("%MS4DJuliaXLabel"):
		%MS4DJuliaXLabel.text = "Julia X: " + str(snapped(menger_jx_slider.value, 0.01))
	if menger_jy_slider and has_node("%MS4DJuliaYLabel"):
		%MS4DJuliaYLabel.text = "Julia Y: " + str(snapped(menger_jy_slider.value, 0.01))
	if menger_jz_slider and has_node("%MS4DJuliaZLabel"):
		%MS4DJuliaZLabel.text = "Julia Z: " + str(snapped(menger_jz_slider.value, 0.01))
	if menger_jw_slider and has_node("%MS4DJuliaWLabel"):
		%MS4DJuliaWLabel.text = "Julia W: " + str(snapped(menger_jw_slider.value, 0.01))
	
	# Update Morph label (this was missing in the original)
	if has_node("%MS4DMorphLabel"):
		%MS4DMorphLabel.text = "Julia Influence: " + str(int(menger_morph_slider.value * 100)) + "%"
	
	# Create Vector4s for the 4D math - only if sliders exist
	if menger_ox_slider and menger_oy_slider and menger_oz_slider and menger_ow_slider:
		var m_offset = Vector4(
			menger_ox_slider.value,
			menger_oy_slider.value,
			menger_oz_slider.value,
			menger_ow_slider.value
		)
		mat.set_shader_parameter("MengerOffset1", m_offset)
	
	if menger_jx_slider and menger_jy_slider and menger_jz_slider and menger_jw_slider:
		var j_seed = Vector4(
			menger_jx_slider.value,
			menger_jy_slider.value,
			menger_jz_slider.value,
			menger_jw_slider.value
		)
		mat.set_shader_parameter("JuliaSeed", j_seed)

func diagnostic_check():
	var mat = get_fractal_material()
	if not mat:
		print("DIAGNOSTIC: No material found!")
		return
	
	print("--- Hyperion Shader Diagnostic ---")
	print("Active Fractal: ", current_fractal)
	print("Current Shader: ", mat.shader.resource_path)
	
	# Camera info
	if main_camera:
		print("Camera Position: ", main_camera.global_position)
		print("Camera Forward: ", -main_camera.global_transform.basis.z)
	
	# Check Global Environment
	print("Reflectivity: ", mat.get_shader_parameter("Reflectivity"))
	print("FogDensity: ", mat.get_shader_parameter("FogDensity"))
	print("OffsetW: ", mat.get_shader_parameter("OffsetW"))
	print("ColorCycle: ", mat.get_shader_parameter("ColorCycle"))
	print("PaletteType: ", mat.get_shader_parameter("PaletteType"))
	
	# Check Symmetry State
	print("Symmetry X Active: ", mat.get_shader_parameter("F_X"))
	print("Symmetry Y Active: ", mat.get_shader_parameter("F_Y"))
	print("Symmetry Z Active: ", mat.get_shader_parameter("F_Z"))
	print("SymmetryStrength Vector: ", mat.get_shader_parameter("SymmetryStrength"))
	print("Fold Offset: ", mat.get_shader_parameter("F_offset"))
	
	# Check Fractal-Specific Parameters
	var shader_path = mat.shader.resource_path
	if "Mandelbox" in shader_path:
		print("Scale: ", mat.get_shader_parameter("Scale"))
		print("BoxFoldLimit: ", mat.get_shader_parameter("BoxFoldLimit"))
		print("Iterations: ", mat.get_shader_parameter("Iterations"))
		print("RotationAngle: ", mat.get_shader_parameter("RotationAngle"))
		print("JuliaMode: ", mat.get_shader_parameter("JuliaMode"))
		print("InvType: ", mat.get_shader_parameter("InvType"))
		print("InvParamA: ", mat.get_shader_parameter("InvParamA"))
		print("InvParamB: ", mat.get_shader_parameter("InvParamB"))
		print("InvScale: ", mat.get_shader_parameter("InvScale"))
	elif "menger" in shader_path:
		print("MengerScale: ", mat.get_shader_parameter("MengerScale"))
		print("Iterations: ", mat.get_shader_parameter("Iterations"))
		print("RotationAngle: ", mat.get_shader_parameter("RotationAngle"))
		print("JuliaMode: ", mat.get_shader_parameter("JuliaMode"))
		print("JuliaMorph: ", mat.get_shader_parameter("JuliaMorph"))
	
	# Note: SCREEN_TEXTURE is automatically provided by Godot's hint_screen_texture
	# It cannot be queried via get_shader_parameter() - this is normal behavior
	print("Note: SCREEN_TEXTURE is auto-provided by hint_screen_texture (cannot be queried)")
	print("----------------------------------")

func advanced_diagnostic():
	var mat = get_fractal_material()
	if not mat:
		return
	
	var shader_rid = mat.get_shader_rid()
	
	# Check if the engine thinks the uniform is valid
	var has_offset_w = RenderingServer.shader_get_parameter_default(shader_rid, "OffsetW")
	var has_screen_tex = RenderingServer.shader_get_parameter_default(shader_rid, "SCREEN_TEXTURE")
	
	print("--- Hyperion System Check ---")
	print("GPU recognizes OffsetW: ", has_offset_w != null)
	print("GPU recognizes SCREEN_TEXTURE: ", has_screen_tex != null)
	print("-----------------------------")
func _on_saturation_changed(value: float):
	var mat = get_fractal_material()
	if mat: mat.set_shader_parameter("Saturation", value)
	if has_node("%SaturationLabel"):
		%SaturationLabel.text = "Saturation: " + str(snapped(value, 0.01))

func _on_contrast_changed(value: float):
	var mat = get_fractal_material()
	if mat: mat.set_shader_parameter("Contrast", value)
	if has_node("%ContrastLabel"):
		%ContrastLabel.text = "Contrast: " + str(snapped(value, 0.01))

func _on_brightness_changed(value: float):
	var mat = get_fractal_material()
	if mat: mat.set_shader_parameter("Brightness", value)
	if has_node("%BrightnessLabel"):
		%BrightnessLabel.text = "Brightness: " + str(snapped(value, 0.01))


func _on_add_waypoint_pressed():
	if not main_camera: return
	
	var point = {
		"pos": main_camera.global_position,
		"rot": main_camera.global_transform.basis, # Basis captures full rotation state
		"w": %WSlider.value,
		"sat": %SaturationSlider.value,
		"con": %ContrastSlider.value
	}
	waypoints.append(point)
	print("Waypoint #", waypoints.size(), " recorded with rotation.")
	
	
func play_flythrough():
	if waypoints.size() < 2:
		print("Need at least 2 waypoints!")
		return
	
	# Clean up any old animation before starting a new one
	if animation_tween:
		animation_tween.kill()
	
	animation_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# THE SYNC FIX: If we are recording, pause the tween immediately
	if is_recording:
		animation_tween.pause()
	
	for i in range(waypoints.size()):
		var p = waypoints[i]
		var duration = 10.0 # Your chosen speed
		
		# Animate Camera Position and Rotation
		animation_tween.tween_property(main_camera, "global_position", p.pos, duration)
		animation_tween.parallel().tween_property(main_camera, "global_basis", p.rot, duration)
		
		# Sync the W-Slider and Shader parameter
		var start_w = %WSlider.value if i == 0 else waypoints[i-1].w
		animation_tween.parallel().tween_method(func(v): 
			%WSlider.value = v
			_on_w_changed(v), start_w, p.w, duration)
	
func _on_clear_path_pressed():
	waypoints.clear()
	print("Animation path cleared.")
	
func save_animation_path(path: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		# Convert our Basis objects to something JSON-friendly
		var save_data = []
		for p in waypoints:
			save_data.append({
				"pos": var_to_str(p.pos),
				"rot": var_to_str(p.rot),
				"w": p.w,
				"sat": p.sat,
				"con": p.con
			})
		file.store_string(JSON.stringify(save_data))
		print("Animation path saved to: ", path)

		
func start_video_capture():
	var screen_res = get_viewport().size
	# If using a plugin like GodotVideoRecorder:
	# recorder.start_recording("user://temp_output.mp4", screen_res, 60.0)
	print("Capturing at: ", screen_res.x, "x", screen_res.y)
func stop_video_capture():
	# This is where you tell the plugin to finalize the MP4
	print("Recording stopped and finalized.")
	# If using the FFmpeg extension, you'd call its 'stop' method here
func _stitch_frames_to_video(save_path: String):
	var global_rec_dir = ProjectSettings.globalize_path(recording_dir)
	var input_path = global_rec_dir.path_join("frame_%05d.png")
	
	# Arguments used in your Fractility code
	var ffmpeg_args = [
		"-y", 
	"-framerate", "10", # Keep the input at 30
	"-i", input_path, 
	"-c:v", "libx264", 
	"-pix_fmt", "yuv420p", 
	"-r", "10", # ADD THIS: Force the output to strictly 30 FPS
	save_path 
]
	
	var output = []
	var exit_code = OS.execute("ffmpeg", ffmpeg_args, output, true)
	
	if exit_code == 0:
		print("Video saved successfully!")
		OS.shell_open(save_path)
	else:
		OS.alert("FFmpeg failed. Ensure FFmpeg is installed on your system.", "Export Error")
		
func _on_record_timer_timeout():
	if not is_recording: return

	# 1. Manually step the animation by exactly 1/30th of a second
	if animation_tween and animation_tween.is_valid():
		animation_tween.custom_step(0.033333)

	# 2. Capture the "Clean" frame without UI
	%PanelContainer.hide()
	%OverlayStopButton.hide()
	
	await RenderingServer.frame_post_draw
	
	var img = get_viewport().get_texture().get_image()
	img.save_png("user://recordings/frame_%05d.png" % frame_counter)
	
	# 3. Restore the Stop Button for the user
	%OverlayStopButton.show()
	frame_counter += 1
	
func prepare_recording_dir():
	var dir = DirAccess.open("user://")
	if not dir:
		printerr("CRITICAL: Cannot open 'user://' directory.")
		return false

	# Ensure the subdirectory exists
	if not dir.dir_exists("recordings"):
		dir.make_dir("recordings")
	
	# Open the recordings folder to clean it
	var rec_dir = DirAccess.open("user://recordings")
	if rec_dir:
		rec_dir.list_dir_begin()
		var file_name = rec_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png"):
				rec_dir.remove(file_name)
			file_name = rec_dir.get_next()
		print("Cleaned old frames from recordings directory.")
	return true
	
func _on_record_button_toggled(is_pressed: bool):
	is_recording = is_pressed
	
	if is_recording:
		# --- STARTING RECORDING ---
		%RecordButton.text = "Stop Recording"
		
		# FORCE UI CHANGES FOR DESKTOP
		if has_node("%PanelContainer"): %PanelContainer.visible = false
		if has_node("%OverlayStopButton"): %OverlayStopButton.visible = true
		
		frame_counter = 0
		if prepare_recording_dir():
			%RecordTimer.start()
			print("Recording started at 30 FPS...")
			
	else:
		# --- STOPPING RECORDING ---
		%RecordButton.text = "Start Recording"
		
		# RESTORE UI
		if has_node("%PanelContainer"): %PanelContainer.visible = true
		if has_node("%OverlayStopButton"): %OverlayStopButton.visible = false
		
		%RecordTimer.stop()
		print("Recording finished. %d frames saved." % frame_counter)
		
		# Open the dialog to name your MP4
		%SaveVideoDialog.popup_centered()
func _on_save_video_dialog_file_selected(path: String):
	# This path is where the user wants the final MP4
	_stitch_frames_to_video(path)
