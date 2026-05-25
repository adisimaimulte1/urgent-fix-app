extends Control

signal logout_requested

const DESIGN_WIDTH := 390.0
const DESIGN_HEIGHT := 844.0
const MAX_CONTENT_WIDTH := 340.0

const BLUE := Color("#02286E")
const BLUE_DARK := Color("#011C50")
const TEAL := Color("#12BAC2")
const TEAL_DARK := Color("#058C99")
const FIX_GREEN := Color("#159EA3")
const TEXT := Color("#02286E")
const MUTED := Color("#7289A8")
const CARD := Color.WHITE
const BORDER := Color("#DDEDF8")
const SOFT := Color("#F3FAFF")

const FONT_PATH := ""
const LOGO_PATH := "res://assets/icon/logo_cropped.png"
const FALLBACK_LOGO_PATH := "res://assets/icon/adaptive_foreground.png"
const BACKGROUND_PATH := "res://assets/background/app_background.png"
const DEMO_PHOTO_PATH := "res://app/assets/demo/plumbing_preview.png"
const LOCAL_DB_PATH := "user://urgentfix_demo_data.json"
const MEDIA_MAX_SIDE := 360
const MEDIA_MIN_SIDE := 220
const MEDIA_JPEG_QUALITY_START := 0.48
const MEDIA_JPEG_QUALITY_MIN := 0.30
const MEDIA_TARGET_BASE64_CHARS := 240000
const LUCIDE_FILE_PLUS_PATH := "res://addons/lucide_icons/icons_png/file-plus-2_512.png"
const LUCIDE_USER_ROUND_PATH := "res://addons/lucide_icons/icons_png/user-round_512.png"
const LUCIDE_ARROW_RIGHT_PATH := "res://addons/lucide_icons/icons_png/arrow-right_512.png"
const LUCIDE_MENU_PATH := "res://addons/lucide_icons/icons_png/menu_512.png"
const LUCIDE_BACK_PATH := "res://addons/lucide_icons/icons_png/chevron-left_512.png"
const LUCIDE_PLUG_PATH := "res://addons/lucide_icons/icons_png/plug_512.png"
const LUCIDE_BOLT_PATH := "res://addons/lucide_icons/icons_png/bolt_512.png"
const LUCIDE_PAINT_PATH := "res://addons/lucide_icons/icons_png/paint-roller_512.png"
const LUCIDE_FLAME_PATH := "res://addons/lucide_icons/icons_png/flame-kindling_512.png"
const LUCIDE_SHIELD_PATH := "res://addons/lucide_icons/icons_png/shield-check_512.png"
const LUCIDE_CLOCK_PATH := "res://addons/lucide_icons/icons_png/clock_512.png"
const LUCIDE_FILE_TEXT_PATH := "res://addons/lucide_icons/icons_png/file-text_512.png"
const LUCIDE_DROPLETS_PATH := "res://addons/lucide_icons/icons_png/droplets_512.png"
const LUCIDE_AIR_VENT_PATH := "res://addons/lucide_icons/icons_png/air-vent_512.png"
const LUCIDE_ELLIPSIS_PATH := "res://addons/lucide_icons/icons_png/ellipsis_512.png"
const LUCIDE_ALERT_PATH := "res://addons/lucide_icons/icons_png/alert-triangle_512.png"
const LUCIDE_CALENDAR_PATH := "res://addons/lucide_icons/icons_png/calendar_512.png"
const LUCIDE_CALENDAR_DAYS_PATH := "res://addons/lucide_icons/icons_png/calendar-days_512.png"
const LUCIDE_CAMERA_PATH := "res://addons/lucide_icons/icons_png/camera_512.png"
const LUCIDE_GALLERY_PATH := "res://addons/lucide_icons/icons_png/image_512.png"
const LUCIDE_X_PATH := "res://addons/lucide_icons/icons_png/x_512.png"

const UF_ACTION_BUTTON_SCRIPT := preload("res://app/scripts/ui/UFActionButton.gd")
const UF_ICON_CIRCLE_BUTTON_SCRIPT := preload("res://app/scripts/ui/UFIconCircleButton.gd")
const UF_CATEGORY_ICON_BUTTON_SCRIPT := preload("res://app/scripts/ui/UFCategoryIconButton.gd")
const UF_WIDE_ICON_OPTION_BUTTON_SCRIPT := preload("res://app/scripts/ui/UFWideIconOptionButton.gd")
const UF_PILL_ICON_BUTTON_SCRIPT := preload("res://app/scripts/ui/UFPillIconButton.gd")
const UF_GRADIENT_BACKGROUND_SCRIPT := preload("res://app/scripts/background/UFGradientBackground.gd")
const UF_HILLS_BACKGROUND_SCRIPT := preload("res://app/scripts/background/UFHillsBackground.gd")
const PROVIDER_REQUESTS_FLOW_SCRIPT := preload("res://app/scripts/provider/ProviderRequestsFlow.gd")
const FIRESTORE_SERVICE_SCRIPT := preload("res://app/scripts/firebase/FirestoreService.gd")

var _page_index := 0
var _scale := 1.0
var _phone: Control
var _background_layer: Control
var _background_visual: Control
var _safe: MarginContainer
var _content: Control
var _title: Label
var _back: Button
var _menu: Button
var _menu_overlay: Control
var _back_hit: Button
var _menu_hit: Button
var _menu_open := false
var _history: Array[int] = []
var _rebuild_pending := false
var _app_font: Font
var _auth_profile: Dictionary = {}
var _account_type := "client"
var _firestore_service: Node
var _provider_flow: Control
var _requests_loaded_from_db := false
var _pending_request_sync := false
var _requests_last_signature := ""
var _form_data: Dictionary = {
	"problem_category": "",
	"other_issue": "",
	"urgency": "",
	"description": "",
	"media": []
}
var _file_dialog: FileDialog
var _camera_overlay: Control
var _camera_texture: CameraTexture
var _camera_feed_id := -1
var _native_camera: Node
var _native_camera_overlay: Control
var _native_camera_preview: TextureRect
var _native_camera_image_texture: ImageTexture
var _native_camera_last_image: Image
var _native_camera_streaming := false
var _native_camera_mode := "photo"
var _native_video_recording := false
var _native_video_started_msec := 0
var _native_video_timer: Timer
var _native_video_status_label: Label
var _native_video_record_button: Button
var _description_counter: Label
var _media_carousel_scroll: ScrollContainer
var _media_carousel_dots: Array[PanelContainer] = []
var _media_page_index := 0
var _rounded_image_shader_cache: Shader
var _saved_requests: Array = []
var _permission_notice_overlay: Control
var _initial_intro_pending := true
var _building_initial_intro := false
var _is_transitioning := false

func set_auth_profile(profile: Dictionary) -> void:
	_auth_profile = profile.duplicate(true)
	_account_type = _normalize_account_type(str(_auth_profile.get("account_type", "client")))
	set_meta("auth_profile", _auth_profile)
	set_meta("account_type", _account_type)
	_ensure_firestore_service()
	_start_requests_database_listener()
	if is_inside_tree() and is_instance_valid(_content):
		_rebuild()

func set_account_profile(profile: Dictionary) -> void:
	set_auth_profile(profile)

func _normalize_account_type(value: String) -> String:
	var cleaned := value.strip_edges().to_lower()
	match cleaned:
		"company", "firma", "firmă", "provider", "prestator":
			return "company"
		_:
			return "client"

func _is_client_account() -> bool:
	return _account_type != "company"

func _is_company_account() -> bool:
	return _account_type == "company"

func _enter_tree() -> void:
	RenderingServer.set_default_clear_color(Color.WHITE)

func _ready() -> void:
	_load_font_if_available()
	_load_local_data()
	_ensure_firestore_service()
	_rebuild()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_queue_rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if _is_confirm_event(event):
		if _is_point_inside_control(_menu, _event_position(event)):
			_toggle_menu()
			get_viewport().set_input_as_handled()
			return
		if is_instance_valid(_back) and _back.visible and _is_point_inside_control(_back, _event_position(event)):
			_go_back()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		if _menu_open:
			_close_menu()
		elif _page_index > 0 or _history.size() > 0:
			_go_back()

func _event_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return event.position
	if event is InputEventScreenTouch:
		return event.position
	return Vector2.INF

func _is_point_inside_control(control: Control, point: Vector2) -> bool:
	if not is_instance_valid(control) or not control.visible:
		return false
	return control.get_global_rect().has_point(point)

func _queue_rebuild() -> void:
	if _rebuild_pending:
		return
	_rebuild_pending = true
	call_deferred("_finish_rebuild")

func _finish_rebuild() -> void:
	_rebuild_pending = false
	_rebuild()

func _rebuild() -> void:
	for c in get_children():
		if c != _firestore_service:
			c.queue_free()
	_compute_scale()
	var run_intro := _initial_intro_pending
	_building_initial_intro = run_intro
	_build_shell()
	_show_page(_page_index, not run_intro)
	_building_initial_intro = false
	if run_intro:
		_initial_intro_pending = false
		call_deferred("_run_initial_intro")

func _compute_scale() -> void:
	var vp := get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		_scale = 1.0
		return
	var raw_scale: float = minf(vp.x / DESIGN_WIDTH, vp.y / DESIGN_HEIGHT)
	_scale = clampf(raw_scale, 0.86, 2.65)

func _dp(v: float) -> int:
	return int(round(v * _scale))

func _sp(v: float) -> int:
	return int(round(v * _scale))

func _load_font_if_available() -> void:
	if FONT_PATH != "" and ResourceLoader.exists(FONT_PATH):
		_app_font = load(FONT_PATH)
		return
	var system_font := SystemFont.new()
	system_font.font_names = PackedStringArray(["Arial", "Roboto", "Noto Sans", "Helvetica", "Sans Serif"])
	system_font.font_weight = 800
	system_font.allow_system_fallback = true
	_app_font = system_font

func _apply_font(c: Control, font_size: int) -> void:
	if _app_font != null:
		c.add_theme_font_override("font", _app_font)
	c.add_theme_font_size_override("font_size", _sp(font_size))

func _load_local_data() -> void:
	if not FileAccess.file_exists(LOCAL_DB_PATH):
		_save_local_data()
		return
	var file := FileAccess.open(LOCAL_DB_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and parsed.has("requests") and parsed["requests"] is Array:
		_saved_requests = parsed["requests"]
	_reset_request_form()

func _save_local_data() -> void:
	var file := FileAccess.open(LOCAL_DB_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"requests": _saved_requests}, "\t"))

func _ensure_firestore_service() -> void:
	if is_instance_valid(_firestore_service):
		return
	_firestore_service = FIRESTORE_SERVICE_SCRIPT.new()
	_firestore_service.name = "MainFirestoreService"
	add_child(_firestore_service)
	if _firestore_service.has_signal("requests_loaded"):
		_firestore_service.requests_loaded.connect(_on_database_requests_loaded)
	if _firestore_service.has_signal("request_saved"):
		_firestore_service.request_saved.connect(_on_database_request_saved)
	if _firestore_service.has_signal("requests_saved"):
		_firestore_service.requests_saved.connect(_on_database_requests_saved)
	if _firestore_service.has_signal("firestore_failed"):
		_firestore_service.firestore_failed.connect(_on_database_error)

func _start_requests_database_listener() -> void:
	if not is_instance_valid(_firestore_service):
		return
	var token := str(_auth_profile.get("id_token", "")).strip_edges()
	if token == "":
		return
	_firestore_service.set_id_token(token)
	if _firestore_service.has_method("start_requests_listener"):
		_firestore_service.start_requests_listener(1.5)
	else:
		_refresh_requests_from_database()

func _refresh_requests_from_database() -> void:
	if not is_instance_valid(_firestore_service):
		return
	var token := str(_auth_profile.get("id_token", "")).strip_edges()
	if token == "":
		return
	_firestore_service.set_id_token(token)
	if _firestore_service.has_method("load_requests"):
		_firestore_service.load_requests()

func _on_database_requests_loaded(requests: Array) -> void:
	var next_signature := _requests_signature(requests)
	if _requests_loaded_from_db and next_signature == _requests_last_signature:
		return
	_requests_loaded_from_db = true
	_requests_last_signature = next_signature
	_saved_requests = requests.duplicate(true)
	_save_local_data()
	_update_provider_flow_from_database()

func _update_provider_flow_from_database() -> void:
	if _page_index != 3:
		return
	if is_instance_valid(_provider_flow) and _provider_flow.has_method("update_requests"):
		_provider_flow.update_requests(_visible_provider_requests())
	elif is_instance_valid(_content):
		_show_page(3, false)

func _requests_signature(requests: Array) -> String:
	var simple: Array = []
	for item in requests:
		if not (item is Dictionary):
			continue
		var request := item as Dictionary
		simple.append({
			"id": str(request.get("id", "")),
			"status": str(request.get("status", "")),
			"created_at": str(request.get("created_at", "")),
			"updated_at": str(request.get("updated_at", "")),
			"problem_category": str(request.get("problem_category", "")),
			"urgency": str(request.get("urgency", "")),
			"description": str(request.get("description", "")),
			"provider_uid": str(request.get("provider_uid", "")),
			"provider_message": str(request.get("provider_message", "")),
			"proposed_amount": str(request.get("proposed_amount", "")),
			"payment_status": str(request.get("payment_status", "")),
			"media_signature": _media_signature(request.get("media", {}))
		})
	simple.sort_custom(func(a: Variant, b: Variant) -> bool:
		return str((a as Dictionary).get("id", "")) < str((b as Dictionary).get("id", ""))
	)
	return JSON.stringify(simple)

func _media_signature(value: Variant) -> String:
	var items := _media_array_from_value(value)
	var parts := PackedStringArray()
	for item in items:
		if not (item is Dictionary):
			continue
		var media := item as Dictionary
		parts.append("%s:%s:%d" % [str(media.get("kind", "")), str(media.get("mime_type", "")), str(media.get("image_base64", "")).length()])
	return "|".join(parts)

func _on_database_request_saved(_request: Dictionary) -> void:
	_pending_request_sync = false
	_requests_last_signature = _requests_signature(_saved_requests)

func _on_database_requests_saved(_requests: Array) -> void:
	_pending_request_sync = false
	_requests_last_signature = _requests_signature(_saved_requests)

func _on_database_error(message: String) -> void:
	_pending_request_sync = false
	_show_small_notice("Database", message)

func _save_request_to_database(request: Dictionary) -> void:
	if not is_instance_valid(_firestore_service):
		return
	var token := str(_auth_profile.get("id_token", "")).strip_edges()
	if token == "":
		return
	_pending_request_sync = true
	_firestore_service.set_id_token(token)
	_firestore_service.save_request(request)

func _save_requests_to_database(requests: Array) -> void:
	if not is_instance_valid(_firestore_service):
		return
	var token := str(_auth_profile.get("id_token", "")).strip_edges()
	if token == "":
		return
	_pending_request_sync = true
	_firestore_service.set_id_token(token)
	_firestore_service.save_requests(requests)

func _set_form_value(key: String, value: Variant) -> void:
	_form_data[key] = value

func _selected_media() -> Array:
	return _media_array_from_value(_form_data.get("media", []))

func _media_array_from_value(value: Variant) -> Array:
	var output: Array = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				output.append((item as Dictionary).duplicate(true))
		return output
	if value is Dictionary:
		var media_map := value as Dictionary
		var keys := media_map.keys()
		keys.sort()
		for key in keys:
			var item: Variant = media_map[key]
			if item is Dictionary:
				output.append((item as Dictionary).duplicate(true))
	return output

func _media_storage_map(media: Array) -> Dictionary:
	var output := {}
	var output_index := 0
	for item in media:
		if item is Dictionary:
			var normalized := _normalized_media_item_for_storage(item as Dictionary)
			if not normalized.is_empty():
				output[str(output_index)] = normalized
				output_index += 1
	return output

func _normalized_media_item_for_storage(item: Dictionary) -> Dictionary:
	var encoded := str(item.get("image_base64", "")).strip_edges()
	if encoded == "":
		return {}
	var bytes: PackedByteArray = Marshalls.base64_to_raw(encoded)
	if bytes.is_empty():
		return {}
	var image := _image_from_bytes(bytes, _extension_from_mime(str(item.get("mime_type", "image/png"))))
	if image == null or image.is_empty():
		return {}
	var payload := _compressed_media_payload(image, str(item.get("kind", "photo")))
	if payload.is_empty():
		return {}
	return payload

func _media_base64_from_item(item: Variant) -> String:
	if item is Dictionary:
		return str((item as Dictionary).get("image_base64", ""))
	return ""

func _media_mime_from_item(item: Variant) -> String:
	if item is Dictionary:
		return str((item as Dictionary).get("mime_type", "image/png"))
	return "image/png"

func _media_kind_from_item(item: Variant) -> String:
	if item is Dictionary:
		return str((item as Dictionary).get("kind", "photo"))
	return "photo"

func _add_media_image(image: Image, kind: String) -> bool:
	if image == null or image.is_empty():
		return false
	var payload := _compressed_media_payload(image, kind)
	if payload.is_empty():
		return false
	var media := _selected_media()
	if media.size() >= 3:
		media.remove_at(0)
	media.append(payload)
	_form_data["media"] = media
	if _page_index == 2:
		_show_page(2)
	return true

func _compressed_media_payload(source: Image, kind: String) -> Dictionary:
	var base := _center_square_image(source)
	if base == null or base.is_empty():
		return {}
	var side := mini(MEDIA_MAX_SIDE, mini(base.get_width(), base.get_height()))
	var quality := MEDIA_JPEG_QUALITY_START
	var best_payload := {}
	while side >= MEDIA_MIN_SIDE:
		quality = MEDIA_JPEG_QUALITY_START
		while quality >= MEDIA_JPEG_QUALITY_MIN:
			var encoded := _encode_jpeg_base64(base, side, quality)
			if encoded.strip_edges() != "":
				best_payload = {
					"image_base64": encoded,
					"mime_type": "image/jpeg",
					"kind": kind,
					"created_at": Time.get_datetime_string_from_system(),
					"encoded_width": side,
					"encoded_height": side,
					"encoded_quality": quality
				}
				if encoded.length() <= MEDIA_TARGET_BASE64_CHARS:
					return best_payload
			quality -= 0.08
		side = int(float(side) * 0.82)
	return best_payload

func _encode_jpeg_base64(source: Image, side: int, quality: float) -> String:
	if source == null or source.is_empty():
		return ""
	var img := source.duplicate()
	if img.get_width() != side or img.get_height() != side:
		img.resize(side, side, Image.INTERPOLATE_LANCZOS)
	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)
	var bytes: PackedByteArray = img.save_jpg_to_buffer(clampf(quality, 0.0, 1.0))
	if bytes.is_empty():
		return ""
	return Marshalls.raw_to_base64(bytes)

func _remove_media_item(index: int) -> void:
	var media := _selected_media()
	if index >= 0 and index < media.size():
		media.remove_at(index)
		_form_data["media"] = media
		if _page_index == 2:
			_show_page(2)



func _texture_from_base64_image(encoded: String, mime_type: String = "") -> Texture2D:
	var clean_encoded := encoded.strip_edges()
	if clean_encoded == "":
		return null
	var bytes: PackedByteArray = Marshalls.base64_to_raw(clean_encoded)
	if bytes.is_empty():
		return null
	var image := _image_from_bytes(bytes, _extension_from_mime(mime_type))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _extension_from_mime(mime_type: String) -> String:
	var cleaned := mime_type.strip_edges().to_lower()
	match cleaned:
		"image/jpeg", "image/jpg":
			return "jpg"
		"image/png":
			return "png"
		"image/webp":
			return "webp"
		"image/bmp":
			return "bmp"
		_:
			return ""

func _image_from_bytes(bytes: PackedByteArray, preferred_ext: String = "") -> Image:
	var image := Image.new()
	var loaders: Array[String] = []
	match preferred_ext:
		"png": loaders = ["png", "jpg", "webp", "bmp"]
		"jpg", "jpeg": loaders = ["jpg", "png", "webp", "bmp"]
		"webp": loaders = ["webp", "png", "jpg", "bmp"]
		"bmp": loaders = ["bmp", "png", "jpg", "webp"]
		_: loaders = ["png", "jpg", "webp", "bmp"]
	for loader in loaders:
		var err := OK
		match loader:
			"png": err = image.load_png_from_buffer(bytes)
			"jpg": err = image.load_jpg_from_buffer(bytes)
			"webp": err = image.load_webp_from_buffer(bytes)
			"bmp": err = image.load_bmp_from_buffer(bytes)
		if err == OK and not image.is_empty():
			return image
		image = Image.new()
	return null

func _load_texture(path: String) -> Texture2D:
	if path.strip_edges() == "" or not ResourceLoader.exists(path):
		return null
	var resource: Variant = load(path)
	if resource is Texture2D:
		return resource
	return null

func _open_gallery_picker() -> void:
	var filters := PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp,*.bmp ; Imagini"])
	DisplayServer.file_dialog_show("Alege o poză", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, filters, Callable(self, "_on_gallery_picker_selected"))

func _on_gallery_picker_selected(status: bool, selected_paths: PackedStringArray, _selected_filter_index: int) -> void:
	if not status or selected_paths.is_empty():
		return
	var source_path := selected_paths[0]
	var image := _gallery_image_from_path(source_path)
	if image != null and _add_media_image(image, "photo"):
		return
	_show_small_notice("Galerie", "Poza selectată nu a putut fi citită. Încearcă altă imagine din galerie.")

func _gallery_image_from_path(source_path: String) -> Image:
	if source_path.strip_edges() == "":
		return null
	var img := Image.new()
	var load_error := img.load(source_path)
	if load_error == OK and not img.is_empty():
		return img
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(source_path)
	if bytes.is_empty():
		return null
	return _image_from_bytes(bytes, source_path.get_extension().to_lower())

func _request_camera_permission_if_possible() -> bool:
	if OS.has_method("request_permission"):
		var granted: Variant = OS.call("request_permission", "android.permission.CAMERA")
		if granted is bool:
			return granted
	if OS.has_method("request_permissions"):
		OS.call("request_permissions")
	return true

func _open_camera_capture() -> void:
	_native_camera_mode = "photo"
	_open_native_camera_flow()

func _open_native_camera_flow() -> void:
	_print_native_camera_debug("%s_button_pressed" % _native_camera_mode)
	var native_camera := _get_native_camera_node()
	if native_camera == null:
		_show_small_notice("Camera debug", "Nu am putut crea nodul NativeCamera.\n\n" + _native_camera_debug_report("native_camera_node_null"))
		return
	if not _has_any_native_camera_singleton():
		_show_small_notice("NativeCamera singleton lipsă", "Wrapper-ul există, dar Android singleton-ul pluginului nu este încărcat.\n\n" + _native_camera_debug_report("singleton_missing"))
		return
	_show_native_camera_overlay()
	if native_camera.has_method("has_camera_permission") and not bool(native_camera.call("has_camera_permission")):
		if native_camera.has_method("request_camera_permission"):
			native_camera.call("request_camera_permission")
		else:
			_close_camera_capture(true)
			_show_small_notice("Permisiune necesară", "Pluginul există, dar wrapper-ul nu are request_camera_permission().\n\n" + _native_camera_debug_report("missing_request_permission_method"))
		return
	_start_native_camera_stream()

func _get_native_camera_node() -> Node:
	if is_instance_valid(_native_camera):
		return _native_camera
	_print_native_camera_debug("get_native_camera_node_start")
	var camera_node: Node = null
	if ClassDB.class_exists("NativeCamera"):
		var created: Variant = ClassDB.instantiate("NativeCamera")
		if created is Node:
			camera_node = created
	if camera_node == null:
		var candidate_paths := PackedStringArray([
			"res://addons/NativeCameraPlugin/NativeCamera.gd",
			"res://addon/src/main/NativeCamera.gd",
			"res://addons/native_camera/src/main/NativeCamera.gd",
			"res://addons/native_camera/NativeCamera.gd",
			"res://addons/NativeCamera/NativeCamera.gd"
		])
		for path in candidate_paths:
			if ResourceLoader.exists(path):
				var script_resource: Variant = load(path)
				if script_resource is Script:
					camera_node = Node.new()
					camera_node.set_script(script_resource)
					break
	if camera_node == null:
		return null
	camera_node.name = "UrgentFixNativeCamera"
	add_child(camera_node)
	_native_camera = camera_node
	_connect_native_camera_signal("camera_permission_granted", Callable(self, "_on_native_camera_permission_granted"))
	_connect_native_camera_signal("camera_permission_denied", Callable(self, "_on_native_camera_permission_denied"))
	_connect_native_camera_signal("frame_available", Callable(self, "_on_native_camera_frame_available"))
	_print_native_camera_debug("get_native_camera_node_end")
	return _native_camera

func _connect_native_camera_signal(signal_name: StringName, callable: Callable) -> void:
	if not is_instance_valid(_native_camera):
		return
	if _native_camera.has_signal(signal_name) and not _native_camera.is_connected(signal_name, callable):
		_native_camera.connect(signal_name, callable)

func _has_any_native_camera_singleton() -> bool:
	var singleton_names := PackedStringArray(["NativeCameraPlugin", "NativeCamera", "GodotNativeCamera"])
	for singleton_name in singleton_names:
		if Engine.has_singleton(singleton_name):
			return true
	return false

func _native_camera_debug_report(context: String) -> String:
	var lines := PackedStringArray()
	lines.append("Context: " + context)
	lines.append("OS: " + OS.get_name())
	lines.append("ClassDB NativeCamera: " + str(ClassDB.class_exists("NativeCamera")))
	lines.append("Has NativeCameraPlugin singleton: " + str(Engine.has_singleton("NativeCameraPlugin")))
	lines.append("Has NativeCamera singleton: " + str(Engine.has_singleton("NativeCamera")))
	lines.append("Has GodotNativeCamera singleton: " + str(Engine.has_singleton("GodotNativeCamera")))
	lines.append("Wrapper path exists: " + str(ResourceLoader.exists("res://addons/NativeCameraPlugin/NativeCamera.gd")))
	lines.append("Debug AAR path exists: " + str(FileAccess.file_exists("res://addons/NativeCameraPlugin/bin/debug/NativeCameraPlugin-debug.aar")))
	lines.append("Release AAR path exists: " + str(FileAccess.file_exists("res://addons/NativeCameraPlugin/bin/release/NativeCameraPlugin-release.aar")))
	if is_instance_valid(_native_camera):
		lines.append("Wrapper node valid: true")
		lines.append("Wrapper has has_camera_permission(): " + str(_native_camera.has_method("has_camera_permission")))
		lines.append("Wrapper has request_camera_permission(): " + str(_native_camera.has_method("request_camera_permission")))
		lines.append("Wrapper has get_all_cameras(): " + str(_native_camera.has_method("get_all_cameras")))
		lines.append("Wrapper has start(): " + str(_native_camera.has_method("start")))
	else:
		lines.append("Wrapper node valid: false")
	lines.append("All singletons: " + str(Engine.get_singleton_list()))
	return "\n".join(lines)

func _print_native_camera_debug(context: String) -> void:
	print("\n========== URGENTFIX NATIVE CAMERA DEBUG ==========")
	print(_native_camera_debug_report(context))
	print("===================================================\n")

func _show_native_camera_overlay() -> void:
	_close_camera_capture(true)
	_native_camera_last_image = null
	_native_camera_image_texture = null
	_native_video_recording = false
	_native_video_started_msec = 0
	_native_video_status_label = null
	_native_video_record_button = null
	_native_camera_overlay = Control.new()
	_native_camera_overlay.name = "NativeCameraOverlay"
	_native_camera_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_native_camera_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_native_camera_overlay.z_index = 920
	add_child(_native_camera_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_native_camera_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_native_camera_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_dp(340), _dp(510))
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.98), BLUE, 24, 2))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dp(14))
	margin.add_theme_constant_override("margin_right", _dp(14))
	margin.add_theme_constant_override("margin_top", _dp(14))
	margin.add_theme_constant_override("margin_bottom", _dp(14))
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", _dp(12))
	margin.add_child(box)
	box.add_child(_headline("Fă o poză", 20))
	var preview_shell := PanelContainer.new()
	preview_shell.custom_minimum_size = Vector2(_dp(306), _dp(306))
	preview_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_shell.clip_contents = true
	preview_shell.add_theme_stylebox_override("panel", _frame_style(FIX_GREEN.darkened(0.12), Color(0, 0, 0, 0), 18, 0))
	box.add_child(preview_shell)
	_native_camera_preview = TextureRect.new()
	_native_camera_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	_native_camera_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_native_camera_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_native_camera_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_shell.add_child(_native_camera_preview)
	var hint := _center_text("Se pornește camera...", 12)
	hint.name = "CameraLoadingLabel"
	hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color.WHITE)
	preview_shell.add_child(hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _dp(10))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(row)
	var cancel := _secondary_button("Renunță", func() -> void: _close_camera_capture(true))
	cancel.icon_texture = null
	cancel.arrow_texture = null
	cancel.icon_kind = "none"
	row.add_child(cancel)
	var snap := _primary_button("Capturează", func() -> void: _capture_native_camera_photo())
	snap.icon_texture = null
	snap.arrow_texture = null
	snap.icon_kind = "none"
	row.add_child(snap)
	panel.scale = Vector2(0.94, 0.94)
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_native_camera_permission_granted() -> void:
	_start_native_camera_stream()

func _on_native_camera_permission_denied() -> void:
	_close_camera_capture(true)
	_show_small_notice("Permisiune blocată", "Camera este refuzată. Activeaz-o din setările aplicației și încearcă din nou.")

func _start_native_camera_stream() -> void:
	if not is_instance_valid(_native_camera):
		return
	if not _native_camera.has_method("get_all_cameras") or not _native_camera.has_method("start"):
		_close_camera_capture(true)
		_show_small_notice("Camera indisponibilă", "Pluginul NativeCamera este incomplet sau nu este activ.")
		return
	var cameras: Array = _native_camera.call("get_all_cameras")
	if cameras.is_empty():
		_close_camera_capture(true)
		_show_small_notice("Camera indisponibilă", "Nu am găsit nicio cameră disponibilă pe telefon.")
		return
	var selected_camera: Variant = cameras[0]
	for camera_info in cameras:
		if camera_info != null and camera_info.has_method("is_front_facing") and not bool(camera_info.call("is_front_facing")):
			selected_camera = camera_info
			break
	var selected_size := _best_native_camera_size(selected_camera)
	var request: Variant = null
	if _native_camera.has_method("create_feed_request"):
		request = _native_camera.call("create_feed_request")
	if request == null:
		_close_camera_capture(true)
		_show_small_notice("Camera indisponibilă", "Nu am putut crea cererea pentru feed-ul camerei.")
		return
	if selected_camera != null and selected_camera.has_method("get_camera_id") and request.has_method("set_camera_id"):
		request.call("set_camera_id", str(selected_camera.call("get_camera_id")))
	if request.has_method("set_width"):
		request.call("set_width", int(selected_size.x))
	if request.has_method("set_height"):
		request.call("set_height", int(selected_size.y))
	if request.has_method("set_frames_to_skip"):
		request.call("set_frames_to_skip", 2)
	if request.has_method("set_auto_upright"):
		request.call("set_auto_upright", true)
	elif request.has_method("set_rotation"):
		request.call("set_rotation", 90)
	if request.has_method("set_grayscale"):
		request.call("set_grayscale", false)
	if request.has_method("set_mirror_horizontal"):
		request.call("set_mirror_horizontal", false)
	if request.has_method("set_mirror_vertical"):
		request.call("set_mirror_vertical", false)
	_native_camera.call("start", request)
	_native_camera_streaming = true

func _best_native_camera_size(camera_info: Variant) -> Vector2i:
	var best := Vector2i(1280, 720)
	if camera_info == null or not camera_info.has_method("get_output_sizes"):
		return best
	var sizes: Array = camera_info.call("get_output_sizes")
	if sizes.is_empty():
		return best
	var best_score := 2147483647.0
	for item in sizes:
		if item == null:
			continue
		var width := 0
		var height := 0
		if item.has_method("get_width"):
			width = int(item.call("get_width"))
		if item.has_method("get_height"):
			height = int(item.call("get_height"))
		if width <= 0 or height <= 0:
			continue
		var long_side := maxi(width, height)
		var short_side := mini(width, height)
		var score := absf(float(long_side - 1280)) + absf(float(short_side - 720))
		if score < best_score:
			best_score = score
			best = Vector2i(width, height)
	return best

func _on_native_camera_frame_available(frame_info: Variant) -> void:
	if frame_info == null or not frame_info.has_method("get_image"):
		return
	var image_variant: Variant = frame_info.call("get_image")
	if not (image_variant is Image):
		return
	var frame_image := image_variant as Image
	if frame_image.is_empty():
		return
	_native_camera_last_image = frame_image.duplicate()
	_native_camera_image_texture = ImageTexture.create_from_image(_native_camera_last_image)
	if is_instance_valid(_native_camera_preview):
		_native_camera_preview.texture = _native_camera_image_texture
		var loading := _native_camera_preview.get_parent().get_node_or_null("CameraLoadingLabel") as Control
		if loading != null:
			loading.visible = false

func _capture_native_camera_photo() -> void:
	if _native_camera_last_image == null or _native_camera_last_image.is_empty():
		_show_small_notice("Camera pornește", "Așteaptă o secundă să apară imaginea, apoi încearcă din nou.")
		return
	var captured_image := _center_square_image(_native_camera_last_image)
	_close_camera_capture(true)
	if not _add_media_image(captured_image, "photo"):
		_show_small_notice("Eroare salvare", "Poza a fost capturată, dar nu a putut fi convertită în Base64.")

func _center_square_image(source: Image) -> Image:
	if source == null or source.is_empty():
		return Image.new()
	var side := mini(source.get_width(), source.get_height())
	var x := int((source.get_width() - side) / 2)
	var y := int((source.get_height() - side) / 2)
	return source.get_region(Rect2i(x, y, side, side))

func _close_camera_capture(close_overlay: bool = true) -> void:
	_native_video_recording = false
	if is_instance_valid(_native_video_timer):
		_native_video_timer.stop()
		_native_video_timer.queue_free()
	_native_video_timer = null
	if is_instance_valid(_native_camera) and _native_camera_streaming and _native_camera.has_method("stop"):
		_native_camera.call("stop")
	_native_camera_streaming = false
	if _camera_feed_id >= 0:
		for i in range(CameraServer.get_feed_count()):
			var feed := CameraServer.get_feed(i)
			if feed != null and feed.get_id() == _camera_feed_id:
				feed.set_active(false)
				break
	_camera_feed_id = -1
	_camera_texture = null
	if close_overlay:
		if is_instance_valid(_camera_overlay):
			_camera_overlay.queue_free()
		if is_instance_valid(_native_camera_overlay):
			_native_camera_overlay.queue_free()
		_native_camera_overlay = null
		_native_camera_preview = null

func _build_shell() -> void:
	_phone = Control.new()
	_phone.name = "NativePhoneApp"
	_phone.set_anchors_preset(Control.PRESET_FULL_RECT)
	_phone.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_phone)
	_background_layer = Control.new()
	_background_layer.name = "BackgroundLayer"
	_background_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phone.add_child(_background_layer)
	_background_visual = _build_app_background(_background_layer)
	_background_layer.modulate.a = 1.0
	if _building_initial_intro and is_instance_valid(_background_visual):
		_background_visual.modulate.a = 0.0
	_safe = MarginContainer.new()
	_safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	if _building_initial_intro:
		_safe.modulate.a = 0.0
		_safe.position.y = _dp(12)
	_phone.add_child(_safe)
	_safe.add_theme_constant_override("margin_left", _dp(18))
	_safe.add_theme_constant_override("margin_right", _dp(18))
	_safe.add_theme_constant_override("margin_top", _dp(34))
	_safe.add_theme_constant_override("margin_bottom", _dp(12))
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", _dp(10))
	_safe.add_child(stack)
	var bar := HBoxContainer.new()
	bar.custom_minimum_size.y = _dp(72)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", _dp(8))
	stack.add_child(bar)
	_back = _back_button()
	_back.pressed.connect(_go_back)
	bar.add_child(_back)
	_title = Label.new()
	_title.text = "UrgentFix"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_color_override("font_color", TEXT)
	_apply_font(_title, 18)
	bar.add_child(_title)
	var menu_wrap := MarginContainer.new()
	menu_wrap.custom_minimum_size = Vector2(_dp(52), _dp(52))
	_menu = _menu_button()
	_menu.pressed.connect(_toggle_menu)
	menu_wrap.add_child(_menu)
	bar.add_child(menu_wrap)
	_content = Control.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(_content)
	_build_menu_overlay()
	_build_top_hit_buttons()
	call_deferred("_sync_top_hit_buttons")

func _build_app_background(parent: Control) -> Control:
	var visual := Control.new()
	visual.name = "BackgroundVisual"
	visual.set_anchors_preset(Control.PRESET_FULL_RECT)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(visual)
	if ResourceLoader.exists(BACKGROUND_PATH):
		var bg_image := TextureRect.new()
		bg_image.name = "AppBackgroundImage"
		bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_image.texture = load(BACKGROUND_PATH)
		visual.add_child(bg_image)
		return visual
	var bg := UF_GRADIENT_BACKGROUND_SCRIPT.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(bg)
	var white := ColorRect.new()
	white.color = Color(1, 1, 1, 0.58)
	white.set_anchors_preset(Control.PRESET_FULL_RECT)
	white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(white)
	var hills := UF_HILLS_BACKGROUND_SCRIPT.new()
	hills.set_anchors_preset(Control.PRESET_FULL_RECT)
	hills.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(hills)
	return visual

func _is_confirm_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if event is InputEventScreenTouch:
		return event.pressed
	return false

func _navigate_to(index: int) -> void:
	var next_index := clampi(index, 0, 3)
	if next_index == 1 and _is_company_account():
		_close_menu()
		return
	if next_index == 3 and _is_client_account():
		_close_menu()
		return
	if next_index == _page_index or _is_transitioning:
		_close_menu()
		return
	_close_menu()
	if next_index == 1 and _page_index == 0:
		_reset_request_form()
		_history.clear()
		_show_page(1)
		return
	if next_index == 0 and _page_index == 1:
		_confirm_leave_request()
		return
	if next_index == 0 and _page_index == 2:
		_show_page(1)
		return
	if next_index == 2 and _page_index == 0:
		_reset_request_form()
		_history.clear()
		_show_page(1)
		return
	if next_index == 3:
		_history.clear()
		_show_page(3)
		return
	_show_page(next_index)

func _go_back() -> void:
	_close_menu()
	if _page_index == 3:
		var provider_flow := _content.get_child(0) if is_instance_valid(_content) and _content.get_child_count() > 0 else null
		if provider_flow != null and provider_flow.has_method("_go_back_in_flow") and bool(provider_flow.call("_go_back_in_flow")):
			return
		_history.clear()
		_show_page(0)
		return
	if _page_index == 2:
		_show_page(1)
		return
	if _page_index == 1:
		_confirm_leave_request()
		return
	_history.clear()
	_show_page(0)

func _show_page(index: int, animate: bool = true) -> void:
	var next_index := clampi(index, 0, 3)
	if not is_instance_valid(_content):
		return
	if animate and _content.get_child_count() > 0:
		_is_transitioning = true
		var out_tween := create_tween()
		out_tween.set_parallel(true)
		out_tween.tween_property(_content, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		out_tween.tween_property(_content, "position:y", _dp(-10), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		out_tween.finished.connect(func() -> void:
			_populate_page(next_index, true)
			_is_transitioning = false
		)
		return
	_populate_page(next_index, animate)

func _populate_page(index: int, animate: bool = true) -> void:
	_page_index = clampi(index, 0, 3)
	if not is_instance_valid(_content):
		return
	for c in _content.get_children():
		c.queue_free()
	_back.visible = _page_index > 0 or _history.size() > 0
	call_deferred("_sync_top_hit_buttons")
	_content.modulate.a = 0.0 if animate else 1.0
	_content.position.y = _dp(14) if animate else 0
	match _page_index:
		0: _home()
		1: _problem()
		2: _media()
		3: _provider_requests()
	if animate:
		_animate_page_intro()

func _run_initial_intro() -> void:
	await get_tree().process_frame
	if not is_instance_valid(_background_visual) or not is_instance_valid(_safe):
		return
	_background_layer.modulate.a = 1.0
	_background_visual.modulate.a = 0.0
	_safe.modulate.a = 0.0
	_safe.position.y = _dp(12)
	var page_box: Node = null
	if is_instance_valid(_content):
		page_box = _content.find_child("PageContent", true, false)
	var staged_children: Array[Control] = []
	if page_box is Control:
		for child in (page_box as Control).get_children():
			if child is Control:
				var control_child := child as Control
				control_child.modulate.a = 0.0
				control_child.position.y += _dp(8)
				staged_children.append(control_child)
	var bg_tween := create_tween()
	bg_tween.tween_property(_background_visual, "modulate:a", 1.0, 0.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await bg_tween.finished
	if not is_instance_valid(_safe):
		return
	var ui_tween := create_tween()
	ui_tween.set_parallel(true)
	ui_tween.tween_property(_safe, "modulate:a", 1.0, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	ui_tween.tween_property(_safe, "position:y", 0.0, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var delay := 0.08
	for child in staged_children:
		if is_instance_valid(child):
			ui_tween.tween_property(child, "modulate:a", 1.0, 0.32).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			ui_tween.tween_property(child, "position:y", child.position.y - _dp(8), 0.40).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			delay += 0.045

func _animate_page_intro() -> void:
	if not is_instance_valid(_content):
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_content, "modulate:a", 1.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_content, "position:y", 0.0, 0.46).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _page_scroll() -> VBoxContainer:
	var center := CenterContainer.new()
	center.name = "PageNoScrollCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	_content.add_child(center)

	var box := VBoxContainer.new()
	box.name = "PageContent"
	box.custom_minimum_size.x = _content_width()
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", _dp(12))
	center.add_child(box)
	return box

func _content_width() -> int:
	var vp := get_viewport_rect().size
	var usable := maxf(vp.x - _dp(36), _dp(300))
	return int(round(minf(usable, _dp(MAX_CONTENT_WIDTH))))

func _home() -> void:
	_title.text = ""
	var box := _page_scroll()
	box.add_child(_gap(8))
	box.add_child(_logo_block())
	box.add_child(_gap(2))
	box.add_child(_headline("Ai o problemă\nîn casă?", 31))
	box.add_child(_center_text("Găsește rapid firme verificate\npentru intervenții.", 15))
	box.add_child(_gap(24))
	var report_button := _primary_button("Raportează o problemă", func(): _navigate_to(1))
	if _is_company_account():
		_lock_action_button(report_button)
	else:
		_apply_continue_button_visual(report_button, true)
	box.add_child(report_button)

	var provider_button := _secondary_button("Sunt prestator / firmă", func(): _navigate_to(3))
	if _is_client_account():
		_lock_action_button(provider_button)
	else:
		_apply_continue_button_visual(provider_button, true)
	box.add_child(provider_button)
	box.add_child(_popular_categories_panel())
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", _dp(7))
	box.add_child(chips)
	chips.add_child(_mini_chip("Firme\nverificate", LUCIDE_SHIELD_PATH))
	chips.add_child(_mini_chip("Răspuns\nrapid", LUCIDE_CLOCK_PATH))
	chips.add_child(_mini_chip("Oferte\nclare", LUCIDE_FILE_TEXT_PATH))
	box.add_child(_gap(54))

func _provider_requests() -> void:
	_title.text = ""
	_provider_flow = PROVIDER_REQUESTS_FLOW_SCRIPT.new()
	var provider_flow := _provider_flow
	provider_flow.set_anchors_preset(Control.PRESET_FULL_RECT)
	provider_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	provider_flow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	provider_flow.custom_minimum_size = _content.size
	provider_flow.setup(_visible_provider_requests(), _scale, _app_font)
	provider_flow.back_requested.connect(func() -> void:
		_history.clear()
		_show_page(0)
	)
	provider_flow.requests_changed.connect(func(updated_requests: Array) -> void:
		_apply_provider_request_updates(updated_requests)
	)
	_content.add_child(provider_flow)
	provider_flow.call_deferred("refresh_view")
	if not _requests_loaded_from_db:
		_refresh_requests_from_database()

func _visible_provider_requests() -> Array:
	var visible: Array = []
	for item in _saved_requests:
		if not (item is Dictionary):
			continue
		var request := item as Dictionary
		var status := str(request.get("status", "public_waiting_provider"))
		if status == "closed" or status == "deleted":
			continue
		visible.append(request.duplicate(true))
	return visible

func _apply_provider_request_updates(updated_requests: Array) -> void:
	var by_id := {}
	for item in updated_requests:
		if item is Dictionary:
			var request := (item as Dictionary).duplicate(true)
			var id := str(request.get("id", ""))
			if id != "":
				request["updated_at"] = Time.get_datetime_string_from_system()
				_stamp_provider_data(request)
				by_id[id] = request

	var changed_requests: Array = []
	var merged: Array = []
	var touched_ids := {}
	for existing_item in _saved_requests:
		if not (existing_item is Dictionary):
			continue
		var existing := existing_item as Dictionary
		var existing_id := str(existing.get("id", ""))
		if existing_id != "" and by_id.has(existing_id):
			var next_request := (by_id[existing_id] as Dictionary).duplicate(true)
			merged.append(next_request)
			touched_ids[existing_id] = true
			if _single_request_signature(existing) != _single_request_signature(next_request):
				changed_requests.append(next_request.duplicate(true))
		else:
			merged.append(existing.duplicate(true))

	for id in by_id.keys():
		if not touched_ids.has(id):
			var new_request := (by_id[id] as Dictionary).duplicate(true)
			merged.append(new_request)
			changed_requests.append(new_request.duplicate(true))

	_saved_requests = merged
	_requests_last_signature = _requests_signature(_saved_requests)
	_save_local_data()
	for request in changed_requests:
		if request is Dictionary:
			_save_request_to_database(request as Dictionary)

func _single_request_signature(request: Dictionary) -> String:
	return JSON.stringify({
		"id": str(request.get("id", "")),
		"status": str(request.get("status", "")),
		"provider_uid": str(request.get("provider_uid", "")),
		"provider_email": str(request.get("provider_email", "")),
		"provider_name": str(request.get("provider_name", "")),
		"provider_message": str(request.get("provider_message", "")),
		"proposed_amount": str(request.get("proposed_amount", "")),
		"payment_status": str(request.get("payment_status", "")),
		"contract_signed": bool(request.get("contract_signed", false)),
		"work_done": bool(request.get("work_done", false)),
		"closed_at": str(request.get("closed_at", ""))
	})

func _stamp_provider_data(request: Dictionary) -> void:
	if not _is_company_account():
		return
	var status := str(request.get("status", ""))
	if status == "public_waiting_provider" or status == "":
		return
	request["provider_uid"] = str(_auth_profile.get("uid", request.get("provider_uid", "")))
	request["provider_email"] = str(_auth_profile.get("email", request.get("provider_email", "")))
	var provider_name := str(_auth_profile.get("display_name", _auth_profile.get("company_name", ""))).strip_edges()
	if provider_name == "":
		provider_name = str(_auth_profile.get("email", ""))
	request["provider_name"] = provider_name

func _problem() -> void:
	_title.text = ""
	var box := _page_scroll()
	box.add_theme_constant_override("separation", _dp(9))
	box.add_child(_compact_logo_block())
	box.add_child(_headline("Selectează problema", 22))
	box.add_child(_center_text("Alege categoria care descrie\ncel mai bine intervenția.", 11))
	box.add_child(_gap(2))
	var group := ButtonGroup.new()
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", _dp(8))
	grid.add_theme_constant_override("v_separation", _dp(8))
	box.add_child(grid)
	var card_instalatii := _problem_category_card("Instalații", LUCIDE_PLUG_PATH, TEAL_DARK, Color("#E9FCFD"))
	card_instalatii.button_pressed = str(_form_data.get("problem_category", "")) == "Instalații"
	card_instalatii.button_group = group
	grid.add_child(card_instalatii)
	var card_electric := _problem_category_card("Electric", LUCIDE_BOLT_PATH, Color("#FFC43D"), Color("#FFF6DB"))
	card_electric.button_pressed = str(_form_data.get("problem_category", "")) == "Electric"
	card_electric.button_group = group
	grid.add_child(card_electric)
	var card_zugraveli := _problem_category_card("Zugrăveli", LUCIDE_PAINT_PATH, Color("#4F83D9"), Color("#EEF5FF"))
	card_zugraveli.button_pressed = str(_form_data.get("problem_category", "")) == "Zugrăveli"
	card_zugraveli.button_group = group
	grid.add_child(card_zugraveli)
	var card_centrala := _problem_category_card("Centrală /\nîncălzire", LUCIDE_FLAME_PATH, TEAL_DARK, Color("#E9FCFD"))
	card_centrala.button_pressed = str(_form_data.get("problem_category", "")) == "Centrală / încălzire"
	card_centrala.button_group = group
	grid.add_child(card_centrala)
	var card_infiltratii := _problem_category_card("Infiltrații", LUCIDE_DROPLETS_PATH, Color("#4F83D9"), Color("#EEF5FF"))
	card_infiltratii.button_pressed = str(_form_data.get("problem_category", "")) == "Infiltrații"
	card_infiltratii.button_group = group
	grid.add_child(card_infiltratii)
	var card_aer := _problem_category_card("Aer\ncondiționat", LUCIDE_AIR_VENT_PATH, TEAL_DARK, Color("#E9FCFD"))
	card_aer.button_pressed = str(_form_data.get("problem_category", "")) == "Aer condiționat"
	card_aer.button_group = group
	grid.add_child(card_aer)
	var other := _wide_icon_option("Altele", LUCIDE_ELLIPSIS_PATH)
	other.button_pressed = str(_form_data.get("problem_category", "")) == "Altele"
	other.button_group = group
	box.add_child(other)
	var other_input := _other_issue_input()
	other_input.text = str(_form_data.get("other_issue", ""))
	other_input.visible = other.button_pressed
	other_input.text_changed.connect(func() -> void: _set_form_value("other_issue", other_input.text))
	box.add_child(other_input)
	other.toggled.connect(func(pressed: bool) -> void: other_input.visible = pressed)
	var urgency_title := _section("Cât de urgentă este intervenția?")
	urgency_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	urgency_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(urgency_title)
	var urgency_group := ButtonGroup.new()
	var urgency := HBoxContainer.new()
	urgency.alignment = BoxContainer.ALIGNMENT_CENTER
	urgency.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	urgency.add_theme_constant_override("separation", _dp(7))
	box.add_child(urgency)
	var pill_urgent := _pill_icon("Urgent", LUCIDE_ALERT_PATH, str(_form_data.get("urgency", "")) == "Urgent")
	pill_urgent.button_group = urgency_group
	urgency.add_child(pill_urgent)
	var pill_azi := _pill_icon("Azi", LUCIDE_CALENDAR_PATH, str(_form_data.get("urgency", "")) == "Azi")
	pill_azi.button_group = urgency_group
	urgency.add_child(pill_azi)
	var pill_zile := _pill_icon("2-3 zile", LUCIDE_CLOCK_PATH, str(_form_data.get("urgency", "")) == "2-3 zile")
	pill_zile.button_group = urgency_group
	urgency.add_child(pill_zile)
	var pill_saptamana := _pill_icon("Săptămâna\naceasta", LUCIDE_CALENDAR_DAYS_PATH, str(_form_data.get("urgency", "")) == "Săptămâna aceasta")
	pill_saptamana.button_group = urgency_group
	urgency.add_child(pill_saptamana)
	box.add_child(_gap(5))
	var continue_button := _primary_button("Continuă", func(): _navigate_to(2))
	box.add_child(continue_button)
	_update_problem_continue_state(continue_button, group, urgency_group)
	var refresh_continue := func(_pressed: bool) -> void:
		_save_problem_selection(group, urgency_group)
		_update_problem_continue_state(continue_button, group, urgency_group)
	card_instalatii.toggled.connect(refresh_continue)
	card_electric.toggled.connect(refresh_continue)
	card_zugraveli.toggled.connect(refresh_continue)
	card_centrala.toggled.connect(refresh_continue)
	card_infiltratii.toggled.connect(refresh_continue)
	card_aer.toggled.connect(refresh_continue)
	other.toggled.connect(refresh_continue)
	pill_urgent.toggled.connect(refresh_continue)
	pill_azi.toggled.connect(refresh_continue)
	pill_zile.toggled.connect(refresh_continue)
	pill_saptamana.toggled.connect(refresh_continue)
	box.add_child(_gap(18))

func _save_problem_selection(problem_group: ButtonGroup, urgency_group: ButtonGroup) -> void:
	var problem := ""
	if problem_group != null:
		var pressed_problem := problem_group.get_pressed_button()
		if pressed_problem != null:
			if pressed_problem is UFCategoryIconButton:
				problem = (pressed_problem as UFCategoryIconButton).title.replace("\n", " ")
			elif pressed_problem is UFWideIconOptionButton:
				problem = (pressed_problem as UFWideIconOptionButton).title
			else:
				problem = pressed_problem.text.replace("\n", " ")
	var urgency := ""
	if urgency_group != null:
		var pressed_urgency := urgency_group.get_pressed_button()
		if pressed_urgency != null:
			if pressed_urgency is UFPillIconButton:
				urgency = (pressed_urgency as UFPillIconButton).title.replace("\n", " ")
			else:
				urgency = pressed_urgency.text.replace("\n", " ")
	_form_data["problem_category"] = problem
	_form_data["urgency"] = urgency

func _update_problem_continue_state(button: Button, problem_group: ButtonGroup, urgency_group: ButtonGroup) -> void:
	if not is_instance_valid(button):
		return
	var has_problem := problem_group != null and problem_group.get_pressed_button() != null
	var has_urgency := urgency_group != null and urgency_group.get_pressed_button() != null
	var enabled := has_problem and has_urgency
	button.modulate.a = 1.0
	button.disabled = not enabled
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_FORBIDDEN
	_apply_continue_button_visual(button, enabled)

func _apply_continue_button_visual(button: Button, enabled: bool) -> void:
	if not is_instance_valid(button):
		return
	var fill := BLUE if enabled else Color(1, 1, 1, 0.0)
	var border := BLUE
	var text_color := Color.WHITE if enabled else BLUE
	var border_width := 0 if enabled else 3
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", text_color)
	button.add_theme_stylebox_override("normal", _style(fill, border, 15, border_width))
	button.add_theme_stylebox_override("hover", _style(fill, border, 15, border_width))
	button.add_theme_stylebox_override("pressed", _style(fill, border, 15, border_width))
	button.add_theme_stylebox_override("disabled", _style(fill, border, 15, border_width))
	if button is UFActionButton:
		var action_button := button as UFActionButton
		action_button.icon_color = text_color
		action_button.arrow_color = text_color
		action_button.queue_redraw()

func _other_issue_input() -> TextEdit:
	var edit := TextEdit.new()
	edit.custom_minimum_size.y = _dp(62)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.placeholder_text = "Scrie aici ce problemă ai..."
	edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	edit.scroll_fit_content_height = false
	edit.focus_mode = Control.FOCUS_CLICK
	edit.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_font(edit, 12)
	edit.add_theme_color_override("font_color", TEXT)
	edit.add_theme_color_override("font_placeholder_color", Color("#8AA0BB"))
	edit.add_theme_color_override("caret_color", BLUE)
	edit.add_theme_constant_override("caret_width", _dp(3))
	edit.caret_blink = true
	edit.caret_blink_interval = 0.42
	edit.add_theme_stylebox_override("normal", _style(Color.WHITE, BORDER, 14, 1))
	edit.add_theme_stylebox_override("focus", _style(Color.WHITE, TEAL, 14, 2))
	return edit

func _media() -> void:
	_title.text = ""
	var box := _page_scroll()
	box.add_theme_constant_override("separation", _dp(7))
	box.add_child(_compact_logo_block())
	box.add_child(_headline("Adaugă poze", 22))
	box.add_child(_center_text("Arată-ne problema pentru un\ndiagnostic mai rapid.", 12))

	var desc_panel := PanelContainer.new()
	desc_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_panel.add_theme_stylebox_override("panel", _style(Color.WHITE, BORDER, 14, 1))
	box.add_child(desc_panel)

	var desc_margin := MarginContainer.new()
	desc_margin.add_theme_constant_override("margin_left", _dp(12))
	desc_margin.add_theme_constant_override("margin_right", _dp(12))
	desc_margin.add_theme_constant_override("margin_top", _dp(10))
	desc_margin.add_theme_constant_override("margin_bottom", _dp(9))
	desc_panel.add_child(desc_margin)

	var desc_box := VBoxContainer.new()
	desc_box.add_theme_constant_override("separation", _dp(6))
	desc_margin.add_child(desc_box)

	var desc_title := _section("Descrie problema")
	desc_title.add_theme_font_size_override("font_size", _sp(14))
	desc_box.add_child(desc_title)

	var edit := TextEdit.new()
	edit.text = str(_form_data.get("description", ""))
	edit.placeholder_text = "Ex: Țeava de sub chiuvetă curge și udă dulapul..."
	edit.custom_minimum_size.y = _dp(58)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	edit.scroll_fit_content_height = false
	edit.focus_mode = Control.FOCUS_CLICK
	edit.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_font(edit, 12)
	edit.add_theme_color_override("font_color", TEXT)
	edit.add_theme_color_override("font_placeholder_color", Color("#8AA0BB"))
	edit.add_theme_color_override("caret_color", BLUE)
	edit.add_theme_constant_override("caret_width", _dp(3))
	edit.caret_blink = true
	edit.caret_blink_interval = 0.42
	edit.add_theme_stylebox_override("normal", _style(Color.WHITE, Color("#CFDAE8"), 8, 1))
	edit.add_theme_stylebox_override("focus", _style(Color.WHITE, TEAL, 8, 2))
	desc_box.add_child(edit)

	_description_counter = _small_note("%d/250" % edit.text.length())
	_description_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_description_counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_box.add_child(_description_counter)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _dp(8))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(row)

	var photo_button := _upload_card("Fă o poză", LUCIDE_CAMERA_PATH)
	row.add_child(photo_button)
	photo_button.pressed.connect(func() -> void:
		_open_camera_capture()
	)

	var gallery_button := _upload_card("Din galerie", LUCIDE_GALLERY_PATH)
	row.add_child(gallery_button)
	gallery_button.pressed.connect(func() -> void:
		_open_gallery_picker()
	)

	box.add_child(_media_preview_stack())

	var finalize_button := _primary_button("Finalizează", func() -> void:
		_finalize_request()
	)

	edit.text_changed.connect(func() -> void:
		if edit.text.length() > 250:
			var caret_line := edit.get_caret_line()
			var caret_col := edit.get_caret_column()
			edit.text = edit.text.left(250)
			edit.set_caret_line(mini(caret_line, edit.get_line_count() - 1))
			edit.set_caret_column(mini(caret_col, edit.get_line(edit.get_caret_line()).length()))
		_form_data["description"] = edit.text
		if is_instance_valid(_description_counter):
			_description_counter.text = "%d/250" % edit.text.length()
		_update_media_finalize_state(finalize_button)
	)

	box.add_child(_media_limit_note())
	box.add_child(finalize_button)
	_update_media_finalize_state(finalize_button)
	box.add_child(_gap(54))

func _media_limit_note() -> Label:
	var note := _small_note("ⓘ  Poți adăuga până la 3 poze")
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(note, 16)
	note.add_theme_color_override("font_color", MUTED)
	return note

func _update_media_finalize_state(button: Button) -> void:
	if not is_instance_valid(button):
		return
	var has_media := not _selected_media().is_empty()
	var has_description := str(_form_data.get("description", "")).strip_edges().length() > 0
	var enabled := has_media and has_description
	button.disabled = not enabled
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_FORBIDDEN
	_apply_continue_button_visual(button, enabled)

func _finalize_request() -> void:
	if _selected_media().is_empty():
		return
	if str(_form_data.get("description", "")).strip_edges().length() == 0:
		return
	var now := Time.get_datetime_string_from_system()
	var uid := str(_auth_profile.get("uid", "")).strip_edges()
	var request := {
		"id": "REQ-%d" % Time.get_ticks_msec(),
		"created_at": now,
		"updated_at": now,
		"created_by_uid": uid,
		"created_by_email": str(_auth_profile.get("email", "")),
		"user_name": _request_profile_name(),
		"user_phone": str(_auth_profile.get("phone", "")),
		"account_type": "client",
		"status": "public_waiting_provider",
		"payment_status": "pending_offer",
		"provider_uid": "",
		"provider_email": "",
		"provider_name": "",
		"provider_message": "",
		"proposed_amount": "",
		"problem_category": str(_form_data.get("problem_category", "")),
		"other_issue": str(_form_data.get("other_issue", "")),
		"urgency": str(_form_data.get("urgency", "")),
		"description": str(_form_data.get("description", "")),
		"media": _media_storage_map(_selected_media())
	}
	_saved_requests.append(request)
	_requests_last_signature = _requests_signature(_saved_requests)
	_reset_request_form()
	_save_local_data()
	_save_request_to_database(request)
	_show_request_public_popup()

func _reset_request_form() -> void:
	_form_data = {"problem_category": "", "other_issue": "", "urgency": "", "description": "", "media": []}

func _request_profile_name() -> String:
	var display := str(_auth_profile.get("display_name", "")).strip_edges()
	if display != "":
		return display
	var email := str(_auth_profile.get("email", "")).strip_edges()
	if email.contains("@"):
		return email.get_slice("@", 0)
	return "Client local"

func _confirm_leave_request() -> void:
	_show_confirm_notice("Ieși din cerere?", "Dacă părăsești această pagină, cererea curentă nu va fi salvată.", "Rămâi", "Ieși", func() -> void:
		_reset_request_form()
		_history.clear()
		_show_page(0)
	)

func _show_request_public_popup() -> void:
	_show_small_notice("Cerere înregistrată", "Cererea ta a fost înregistrată și trimisă către prestatori.", func() -> void:
		_history.clear()
		_show_page(0)
	)

func _show_confirm_notice(title_text: String, body_text: String, cancel_text: String, confirm_text: String, on_confirm: Callable, on_cancel: Callable = Callable()) -> void:
	if is_instance_valid(_permission_notice_overlay):
		_permission_notice_overlay.queue_free()
	_permission_notice_overlay = Control.new()
	_permission_notice_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_permission_notice_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_permission_notice_overlay.z_index = 950
	add_child(_permission_notice_overlay)
	var dim := ColorRect.new()
	dim.color = Color(1, 1, 1, 0.58)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_permission_notice_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_permission_notice_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_dp(314), 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.pivot_offset = Vector2(_dp(157), _dp(110))
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.97), BLUE, 24, 2))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dp(18))
	margin.add_theme_constant_override("margin_right", _dp(18))
	margin.add_theme_constant_override("margin_top", _dp(18))
	margin.add_theme_constant_override("margin_bottom", _dp(18))
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", _dp(12))
	margin.add_child(box)
	var title := _headline(title_text, 20)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var body := _center_text(body_text, 13)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(body)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", _dp(10))
	box.add_child(row)
	row.add_child(_dialog_text_button(cancel_text, false, func() -> void:
		if is_instance_valid(_permission_notice_overlay):
			_permission_notice_overlay.queue_free()
		if on_cancel.is_valid():
			on_cancel.call()
	))
	row.add_child(_dialog_text_button(confirm_text, true, func() -> void:
		if is_instance_valid(_permission_notice_overlay):
			_permission_notice_overlay.queue_free()
		if on_confirm.is_valid():
			on_confirm.call()
	))
	panel.scale = Vector2(0.90, 0.90)
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _show_small_notice(title_text: String, body_text: String, on_close: Callable = Callable()) -> void:
	if is_instance_valid(_permission_notice_overlay):
		_permission_notice_overlay.queue_free()
	_permission_notice_overlay = Control.new()
	_permission_notice_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_permission_notice_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_permission_notice_overlay.z_index = 950
	add_child(_permission_notice_overlay)
	var dim := ColorRect.new()
	dim.color = Color(1, 1, 1, 0.58)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_permission_notice_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_permission_notice_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_dp(306), 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.pivot_offset = Vector2(_dp(153), _dp(95))
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.97), BLUE, 24, 2))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dp(18))
	margin.add_theme_constant_override("margin_right", _dp(18))
	margin.add_theme_constant_override("margin_top", _dp(18))
	margin.add_theme_constant_override("margin_bottom", _dp(18))
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", _dp(12))
	margin.add_child(box)
	var title := _headline(title_text, 20)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var body := _center_text(body_text, 13)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(body)
	box.add_child(_dialog_text_button("Am înțeles", true, func() -> void:
		if is_instance_valid(_permission_notice_overlay):
			_permission_notice_overlay.queue_free()
		if on_close.is_valid():
			on_close.call()
	))
	panel.scale = Vector2(0.90, 0.90)
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _logo_block() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", _dp(-8))
	var holder := TextureRect.new()
	holder.custom_minimum_size = Vector2(_dp(156), _dp(137))
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	holder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(LOGO_PATH):
		holder.texture = load(LOGO_PATH)
	elif ResourceLoader.exists(FALLBACK_LOGO_PATH):
		holder.texture = load(FALLBACK_LOGO_PATH)
	box.add_child(holder)
	box.add_child(_logo_wordmark())
	return box

func _compact_logo_block() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", _dp(-7))
	var holder := TextureRect.new()
	holder.custom_minimum_size = Vector2(_dp(108), _dp(95))
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	holder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	holder.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(LOGO_PATH):
		holder.texture = load(LOGO_PATH)
	elif ResourceLoader.exists(FALLBACK_LOGO_PATH):
		holder.texture = load(FALLBACK_LOGO_PATH)
	box.add_child(holder)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 0)
	var urgent := Label.new()
	urgent.text = "Urgent"
	urgent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_apply_font(urgent, 24)
	urgent.add_theme_color_override("font_color", TEXT)
	row.add_child(urgent)
	var fix := Label.new()
	fix.text = "Fix"
	fix.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_font(fix, 24)
	fix.add_theme_color_override("font_color", FIX_GREEN)
	row.add_child(fix)
	box.add_child(row)
	return box

func _logo_wordmark() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 0)
	var urgent := Label.new()
	urgent.text = "Urgent"
	urgent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_apply_font(urgent, 46)
	urgent.add_theme_color_override("font_color", TEXT)
	row.add_child(urgent)
	var fix := Label.new()
	fix.text = "Fix"
	fix.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_font(fix, 46)
	fix.add_theme_color_override("font_color", FIX_GREEN)
	row.add_child(fix)
	return row

func _headline(t: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(l, font_size)
	l.add_theme_color_override("font_color", TEXT)
	l.add_theme_constant_override("line_spacing", _dp(0))
	return l

func _center_text(t: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(l, font_size)
	l.add_theme_color_override("font_color", MUTED)
	return l

func _section(t: String) -> Label:
	var l := Label.new()
	l.text = t
	_apply_font(l, 15)
	l.add_theme_color_override("font_color", TEXT)
	return l

func _small_note(t: String) -> Label:
	var l := Label.new()
	l.text = t
	_apply_font(l, 11)
	l.add_theme_color_override("font_color", MUTED)
	return l

func _dialog_text_button(t: String, primary: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size.y = _dp(50)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(b, 15)
	var fill := BLUE if primary else Color.WHITE
	var border := BLUE
	var text_color := Color.WHITE if primary else BLUE
	b.add_theme_color_override("font_color", text_color)
	b.add_theme_color_override("font_hover_color", text_color)
	b.add_theme_color_override("font_pressed_color", text_color)
	b.add_theme_color_override("font_focus_color", text_color)
	b.add_theme_stylebox_override("normal", _style(fill, border, 14, 2))
	b.add_theme_stylebox_override("hover", _style(fill, border, 14, 2))
	b.add_theme_stylebox_override("pressed", _style(fill, border, 14, 2))
	b.add_theme_stylebox_override("focus", _style(fill, border, 14, 2))
	b.pressed.connect(cb)
	_make_bouncy(b)
	return b

func _primary_button(t: String, cb: Callable) -> Button:
	var b := UF_ACTION_BUTTON_SCRIPT.new()
	b.text = t
	b.icon_kind = "report"
	b.icon_color = Color.WHITE
	b.arrow_color = Color.WHITE
	b.icon_size_dp = 36.0
	b.icon_texture = _load_texture(LUCIDE_FILE_PLUS_PATH)
	b.arrow_texture = _load_texture(LUCIDE_ARROW_RIGHT_PATH)
	b.custom_minimum_size.y = _dp(57)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(b, 16)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _style(BLUE, BLUE, 15, 0))
	b.add_theme_stylebox_override("hover", _style(BLUE, BLUE, 15, 0))
	b.add_theme_stylebox_override("pressed", _style(BLUE, BLUE, 15, 0))
	b.add_theme_stylebox_override("disabled", _style(BLUE, BLUE, 15, 0))
	b.pressed.connect(cb)
	_make_bouncy(b)
	return b

func _secondary_button(t: String, cb: Callable) -> Button:
	var b := UF_ACTION_BUTTON_SCRIPT.new()
	b.text = t
	b.icon_kind = "person"
	b.icon_color = TEXT
	b.arrow_color = TEXT
	b.icon_size_dp = 36.0
	b.icon_texture = _load_texture(LUCIDE_USER_ROUND_PATH)
	b.arrow_texture = _load_texture(LUCIDE_ARROW_RIGHT_PATH)
	b.custom_minimum_size.y = _dp(56)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(b, 16)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", TEXT)
	b.add_theme_color_override("font_pressed_color", TEXT)
	b.add_theme_stylebox_override("normal", _style(Color.WHITE, TEXT, 15, 2))
	b.add_theme_stylebox_override("hover", _style(Color.WHITE, TEXT, 15, 2))
	b.add_theme_stylebox_override("pressed", _style(Color.WHITE, TEXT, 15, 2))
	b.pressed.connect(cb)
	_make_bouncy(b)
	return b

func _lock_action_button(button: Button) -> void:
	if not is_instance_valid(button):
		return
	button.disabled = true
	button.modulate.a = 1.0
	button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	button.focus_mode = Control.FOCUS_NONE
	_apply_continue_button_visual(button, false)

func _back_button() -> Button:
	var b := UF_ICON_CIRCLE_BUTTON_SCRIPT.new()
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.icon_texture = _load_texture(LUCIDE_BACK_PATH)
	b.icon_color = BLUE
	b.circle_color = Color.WHITE
	b.icon_scale = 0.42
	b.circle_ratio = 1.0
	b.custom_minimum_size = Vector2(_dp(50), _dp(50))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.z_index = 100
	b.add_theme_stylebox_override("normal", _transparent_style())
	b.add_theme_stylebox_override("hover", _transparent_style())
	b.add_theme_stylebox_override("pressed", _transparent_style())
	b.add_theme_stylebox_override("focus", _transparent_style())
	_make_bouncy(b)
	return b

func _menu_button() -> Button:
	var b := UF_ICON_CIRCLE_BUTTON_SCRIPT.new()
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.icon_texture = _load_texture(LUCIDE_MENU_PATH)
	b.icon_color = BLUE
	b.circle_color = Color.WHITE
	b.icon_scale = 0.50
	b.circle_ratio = 1.0
	b.custom_minimum_size = Vector2(_dp(50), _dp(50))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.z_index = 100
	b.add_theme_stylebox_override("normal", _transparent_style())
	b.add_theme_stylebox_override("hover", _transparent_style())
	b.add_theme_stylebox_override("pressed", _transparent_style())
	b.add_theme_stylebox_override("focus", _transparent_style())
	_make_bouncy(b)
	return b

func _popular_categories_panel() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", _dp(10))
	var title := _section("Categorii populare")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", _sp(16))
	box.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", _dp(8))
	grid.add_theme_constant_override("v_separation", _dp(8))
	box.add_child(grid)
	grid.add_child(_popular_category_card("Instalații", LUCIDE_PLUG_PATH, TEAL_DARK, Color("#E9FCFD")))
	grid.add_child(_popular_category_card("Electric", LUCIDE_BOLT_PATH, Color("#FFC43D"), Color("#FFF6DB")))
	grid.add_child(_popular_category_card("Zugrăveli", LUCIDE_PAINT_PATH, Color("#4F83D9"), Color("#EEF5FF")))
	grid.add_child(_popular_category_card("Centrală", LUCIDE_FLAME_PATH, TEAL_DARK, Color("#E9FCFD")))
	return box

func _popular_category_card(t: String, icon_path: String, icon_color: Color, bubble_color: Color) -> Button:
	var b := UF_CATEGORY_ICON_BUTTON_SCRIPT.new()
	b.title = t
	b.icon_texture = _load_texture(icon_path)
	b.icon_color = icon_color
	b.bubble_color = bubble_color
	b.toggle_mode = false
	b.custom_minimum_size.y = _dp(104)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.focus_mode = Control.FOCUS_NONE
	_apply_font(b, 12)
	b.add_theme_stylebox_override("normal", _style(CARD, BORDER, 18, 2))
	b.add_theme_stylebox_override("hover", _style(CARD, BORDER, 18, 2))
	b.add_theme_stylebox_override("focus", _style(CARD, BORDER, 18, 2))
	b.add_theme_stylebox_override("pressed", _style(CARD, BORDER, 18, 2))
	return b

func _problem_category_card(t: String, icon_path: String, icon_color: Color, bubble_color: Color) -> Button:
	var b := UF_CATEGORY_ICON_BUTTON_SCRIPT.new()
	b.title = t
	b.icon_texture = _load_texture(icon_path)
	b.icon_color = icon_color
	b.bubble_color = bubble_color
	b.toggle_mode = true
	b.custom_minimum_size.y = _dp(104)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(b, 11)
	b.add_theme_stylebox_override("normal", _style(CARD, BORDER, 14, 2))
	b.add_theme_stylebox_override("hover", _style(CARD, BORDER, 14, 2))
	b.add_theme_stylebox_override("focus", _style(CARD, BORDER, 14, 2))
	b.add_theme_stylebox_override("pressed", _style(Color.WHITE, BLUE, 14, 3))
	_make_bouncy(b)
	return b

func _wide_icon_option(t: String, icon_path: String) -> Button:
	var b := UF_WIDE_ICON_OPTION_BUTTON_SCRIPT.new()
	b.title = t
	b.icon_texture = _load_texture(icon_path)
	b.toggle_mode = true
	b.custom_minimum_size.y = _dp(52)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(b, 11)
	b.add_theme_stylebox_override("normal", _style(CARD, BORDER, 13, 2))
	b.add_theme_stylebox_override("hover", _style(CARD, BORDER, 13, 2))
	b.add_theme_stylebox_override("focus", _style(CARD, BORDER, 13, 2))
	b.add_theme_stylebox_override("pressed", _style(Color.WHITE, BLUE, 13, 3))
	_make_bouncy(b)
	return b

func _pill_icon(t: String, icon_path: String, selected: bool) -> Button:
	var b := UF_PILL_ICON_BUTTON_SCRIPT.new()
	b.title = t
	b.icon_texture = _load_texture(icon_path)
	b.toggle_mode = true
	b.button_pressed = selected
	b.custom_minimum_size = Vector2(_dp(78), _dp(50))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_font(b, 9)
	_apply_pill_icon_style(b)
	b.toggled.connect(func(_pressed: bool) -> void:
		_apply_pill_icon_style(b)
		b.queue_redraw()
	)
	_make_bouncy(b)
	return b

func _apply_pill_icon_style(b: Button) -> void:
	b.add_theme_stylebox_override("normal", _transparent_style())
	b.add_theme_stylebox_override("hover", _transparent_style())
	b.add_theme_stylebox_override("focus", _transparent_style())
	b.add_theme_stylebox_override("pressed", _transparent_style())

func _mini_chip(t: String, icon_path: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size.y = _dp(46)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", _style(Color(0.95, 0.99, 1.0, 0.92), Color("#D6EEF8"), 16, 1))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", _dp(6))
	p.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(_dp(24), _dp(24))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.modulate = TEXT
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	row.add_child(icon)
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_font(l, 10)
	l.add_theme_color_override("font_color", TEXT)
	row.add_child(l)
	return p

func _upload_card(t: String, _icon_path: String = "") -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size.y = _dp(42)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_font(b, 13)

	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _style(FIX_GREEN, FIX_GREEN, 12, 0))
	b.add_theme_stylebox_override("hover", _style(FIX_GREEN.lightened(0.06), FIX_GREEN.lightened(0.06), 12, 0))
	b.add_theme_stylebox_override("pressed", _style(FIX_GREEN.darkened(0.08), FIX_GREEN.darkened(0.08), 12, 0))
	b.add_theme_stylebox_override("focus", _style(FIX_GREEN, FIX_GREEN, 12, 0))

	_make_bouncy(b)
	return b

func _media_preview_stack() -> Control:
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", _dp(6))

	_media_carousel_scroll = ScrollContainer.new()
	var preview_size := _media_preview_size()
	_media_carousel_scroll.custom_minimum_size = Vector2(preview_size, preview_size)
	_media_carousel_scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_media_carousel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_media_carousel_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_media_carousel_scroll.follow_focus = false
	_media_carousel_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_media_carousel_scroll.gui_input.connect(_on_media_carousel_input)
	_hide_media_carousel_scrollbar()
	outer.add_child(_media_carousel_scroll)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 0)
	_media_carousel_scroll.add_child(row)

	var media := _selected_media()
	if media.is_empty():
		_media_page_index = 0
		var empty_card := _media_preview_card({}, -1)
		empty_card.custom_minimum_size = Vector2(preview_size, preview_size)
		row.add_child(empty_card)
		return outer

	_media_page_index = clampi(_media_page_index, 0, media.size() - 1)
	for i in range(media.size()):
		var item: Variant = media[i]
		var card := _media_preview_card(item, i)
		card.custom_minimum_size = Vector2(preview_size, preview_size)
		row.add_child(card)

	outer.add_child(_media_dots(media.size()))
	call_deferred("_restore_media_carousel_position")
	return outer

func _media_preview_size() -> int:
	return min(_content_width(), _dp(260))

func _hide_media_carousel_scrollbar() -> void:
	if not is_instance_valid(_media_carousel_scroll):
		return
	var hbar := _media_carousel_scroll.get_h_scroll_bar()
	if hbar == null:
		return
	hbar.visible = false
	hbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbar.custom_minimum_size = Vector2.ZERO
	hbar.modulate = Color(1, 1, 1, 0)

func _on_media_carousel_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed:
			call_deferred("_snap_media_carousel_to_nearest")
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed:
			call_deferred("_snap_media_carousel_to_nearest")

func _restore_media_carousel_position() -> void:
	if not is_instance_valid(_media_carousel_scroll):
		return
	_hide_media_carousel_scrollbar()
	var bar := _media_carousel_scroll.get_h_scroll_bar()
	if bar == null:
		return
	bar.value = float(_media_page_index * max(1, _media_preview_size()))
	_update_media_dots()
	if not bar.value_changed.is_connected(_on_media_carousel_value_changed):
		bar.value_changed.connect(_on_media_carousel_value_changed)

func _on_media_carousel_value_changed(value: float) -> void:
	var page_width: float = max(1.0, float(_media_preview_size()))
	_media_page_index = clampi(int(round(value / page_width)), 0, max(0, _selected_media().size() - 1))
	_update_media_dots()

func _snap_media_carousel_to_nearest() -> void:
	if not is_instance_valid(_media_carousel_scroll):
		return
	var count := _selected_media().size()
	if count <= 0:
		return
	var bar := _media_carousel_scroll.get_h_scroll_bar()
	if bar == null:
		return
	var page_width: float = max(1.0, float(_media_preview_size()))
	_media_page_index = clampi(int(round(float(bar.value) / page_width)), 0, count - 1)
	var target := float(_media_page_index) * page_width
	var tween := create_tween()
	tween.tween_property(bar, "value", target, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_update_media_dots()

func _media_dots(count: int) -> HBoxContainer:
	_media_carousel_dots.clear()
	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dots.add_theme_constant_override("separation", _dp(5))
	for i in range(count):
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(_dp(7), _dp(7))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_theme_stylebox_override("panel", _frame_style(Color("#B8C8D8"), Color("#B8C8D8"), 50, 0))
		dots.add_child(dot)
		_media_carousel_dots.append(dot)
	_update_media_dots()
	return dots

func _update_media_dots() -> void:
	for i in range(_media_carousel_dots.size()):
		var dot := _media_carousel_dots[i]
		if not is_instance_valid(dot):
			continue
		var active := i == _media_page_index
		dot.custom_minimum_size = Vector2(_dp(18 if active else 7), _dp(7))
		dot.add_theme_stylebox_override("panel", _frame_style(FIX_GREEN if active else Color("#B8C8D8"), FIX_GREEN if active else Color("#B8C8D8"), 50, 0))

func _rounded_media_image(texture: Texture2D, side: int, radius_px: int, border_width_px: int) -> ColorRect:
	var image := ColorRect.new()
	image.set_anchors_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.color = Color.WHITE
	var material := ShaderMaterial.new()
	material.shader = _rounded_image_shader()
	material.set_shader_parameter("image_texture", texture)
	material.set_shader_parameter("rect_size", Vector2(side, side))
	material.set_shader_parameter("radius_px", float(radius_px))
	material.set_shader_parameter("border_width_px", float(border_width_px))
	material.set_shader_parameter("border_color", BLUE)
	material.set_shader_parameter("bg_color", SOFT)
	image.material = material
	return image

func _rounded_image_shader() -> Shader:
	if _rounded_image_shader_cache != null:
		return _rounded_image_shader_cache
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D image_texture;
uniform vec4 border_color : source_color = vec4(0.01, 0.16, 0.43, 1.0);
uniform vec4 bg_color : source_color = vec4(0.91, 0.99, 0.99, 1.0);
uniform vec2 rect_size = vec2(100.0, 100.0);
uniform float radius_px = 18.0;
uniform float border_width_px = 3.0;

float rounded_box(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * rect_size;
	float d = rounded_box(p, rect_size * 0.5, radius_px);
	float alpha = 1.0 - smoothstep(0.0, 1.0, d);
	vec4 sampled = texture(image_texture, UV);
	vec4 base = mix(bg_color, sampled, sampled.a);
	float border_mask = step(-border_width_px, d);
	COLOR = mix(base, border_color, border_mask) * alpha;
}
"""
	_rounded_image_shader_cache = shader
	return _rounded_image_shader_cache

func _media_preview_card(item: Variant, index: int) -> Control:
	var preview_wrap := Control.new()
	var preview_size := _media_preview_size()
	preview_wrap.custom_minimum_size = Vector2(preview_size, preview_size)
	preview_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_wrap.mouse_filter = Control.MOUSE_FILTER_PASS
	var tex: Texture2D = null
	var kind := _media_kind_from_item(item)
	if kind == "photo":
		tex = _texture_from_base64_image(_media_base64_from_item(item), _media_mime_from_item(item))
	elif item is Dictionary:
		var thumbnail_base64 := str((item as Dictionary).get("thumbnail_base64", ""))
		tex = _texture_from_base64_image(thumbnail_base64, str((item as Dictionary).get("thumbnail_mime_type", "image/png")))
	if tex != null:
		preview_wrap.add_child(_rounded_media_image(tex, preview_size, _dp(18), _dp(3)))
	else:
		var panel := PanelContainer.new()
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.clip_contents = true
		panel.add_theme_stylebox_override("panel", _frame_style(SOFT, BLUE, 18, 3))
		preview_wrap.add_child(panel)
		panel.add_child(_missing_media_label("Nicio imagine disponibila"))
	if index >= 0:
		var action := UF_ICON_CIRCLE_BUTTON_SCRIPT.new()
		action.mouse_filter = Control.MOUSE_FILTER_STOP
		action.icon_texture = _load_texture(LUCIDE_X_PATH)
		action.icon_color = BLUE
		action.circle_color = Color.WHITE
		action.icon_scale = 0.66
		action.circle_ratio = 1.0
		action.custom_minimum_size = Vector2(_dp(46), _dp(46))
		action.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		action.offset_left = -_dp(54)
		action.offset_right = -_dp(8)
		action.offset_top = _dp(8)
		action.offset_bottom = _dp(54)
		action.z_index = 50
		action.add_theme_stylebox_override("normal", _transparent_style())
		action.add_theme_stylebox_override("hover", _transparent_style())
		action.add_theme_stylebox_override("pressed", _transparent_style())
		action.add_theme_stylebox_override("focus", _transparent_style())
		action.pressed.connect(func() -> void: _remove_media_item(index))
		_make_bouncy(action)
		preview_wrap.add_child(action)
	return preview_wrap

func _missing_media_label(text: String) -> Label:
	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color("#6A7C91"))
	_apply_font(label, 15)
	return label

func _make_bouncy(button: Button) -> void:
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.pivot_offset = button.custom_minimum_size * 0.5
	button.minimum_size_changed.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	button.button_down.connect(func() -> void: _bounce_to(button, Vector2(0.955, 0.955), 0.10, Tween.TRANS_SINE, Tween.EASE_OUT))
	button.button_up.connect(func() -> void: _bounce_to(button, Vector2.ONE, 0.28, Tween.TRANS_BACK, Tween.EASE_OUT))
	button.mouse_exited.connect(func() -> void: _bounce_to(button, Vector2.ONE, 0.22, Tween.TRANS_BACK, Tween.EASE_OUT))

func _bounce_to(control: Control, target: Vector2, duration: float, trans: Tween.TransitionType, ease_type: Tween.EaseType) -> void:
	if not is_instance_valid(control):
		return
	var tween := create_tween()
	tween.tween_property(control, "scale", target, duration).set_trans(trans).set_ease(ease_type)

func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = _dp(h)
	return c

func _transparent_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 1, 1, 0.0)
	s.border_color = Color(1, 1, 1, 0.0)
	s.set_border_width_all(0)
	s.set_corner_radius_all(0)
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	return s

func _style(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(_dp(width))
	s.set_corner_radius_all(_dp(radius))
	s.content_margin_left = _dp(14)
	s.content_margin_right = _dp(14)
	s.content_margin_top = _dp(9)
	s.content_margin_bottom = _dp(9)
	return s

func _frame_style(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var s := _style(bg, border, radius, width)
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	return s

func _build_top_hit_buttons() -> void:
	_back_hit = _top_hit_button(_go_back, _back)
	_phone.add_child(_back_hit)
	_menu_hit = _top_hit_button(_toggle_menu, _menu)
	_phone.add_child(_menu_hit)

func _top_hit_button(cb: Callable, visual_button: Button) -> Button:
	var b := Button.new()
	b.text = ""
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", _transparent_style())
	b.add_theme_stylebox_override("hover", _transparent_style())
	b.add_theme_stylebox_override("pressed", _transparent_style())
	b.add_theme_stylebox_override("focus", _transparent_style())
	b.button_down.connect(func() -> void:
		if is_instance_valid(visual_button):
			_bounce_to(visual_button, Vector2(0.90, 0.90), 0.10, Tween.TRANS_SINE, Tween.EASE_OUT)
	)
	b.button_up.connect(func() -> void:
		if is_instance_valid(visual_button):
			_bounce_to(visual_button, Vector2.ONE, 0.28, Tween.TRANS_BACK, Tween.EASE_OUT)
	)
	b.mouse_exited.connect(func() -> void:
		if is_instance_valid(visual_button):
			_bounce_to(visual_button, Vector2.ONE, 0.22, Tween.TRANS_BACK, Tween.EASE_OUT)
	)
	b.pressed.connect(cb)
	return b

func _sync_top_hit_buttons() -> void:
	_sync_one_top_hit(_back_hit, _back)
	_sync_one_top_hit(_menu_hit, _menu)

func _sync_one_top_hit(hit: Button, visual: Button) -> void:
	if not is_instance_valid(hit) or not is_instance_valid(visual):
		return
	var visible_state := visual.visible and visual.is_visible_in_tree()
	hit.visible = visible_state
	hit.disabled = not visible_state
	if not visible_state:
		return
	var rect := visual.get_global_rect()
	var extra := _dp(10)
	var hit_rect := rect.grow(extra)
	hit.global_position = hit_rect.position
	hit.size = hit_rect.size
	hit.z_index = 600

func _build_menu_overlay() -> void:
	_menu_overlay = Control.new()
	_menu_overlay.name = "MenuOverlay"
	_menu_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_overlay.visible = false
	_menu_overlay.modulate.a = 0.0
	_menu_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phone.add_child(_menu_overlay)
	var dim := ColorRect.new()
	dim.color = Color(1, 1, 1, 0.48)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close_menu()
		elif event is InputEventScreenTouch and event.pressed:
			_close_menu()
	)
	_menu_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.name = "MenuCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "MenuPanel"
	panel.custom_minimum_size = Vector2(_dp(306), 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.pivot_offset = Vector2(_dp(153), _dp(124))
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.96), BLUE, 24, 2))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _dp(16))
	margin.add_theme_constant_override("margin_right", _dp(16))
	margin.add_theme_constant_override("margin_top", _dp(16))
	margin.add_theme_constant_override("margin_bottom", _dp(16))
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", _dp(9))
	margin.add_child(box)
	var title := _section("Meniu")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _sp(18))
	box.add_child(title)
	box.add_child(_center_text("Navigare rapidă prin aplicație", 11))
	box.add_child(_gap(2))
	box.add_child(_menu_option("Acasă", func(): _navigate_to(0)))
	box.add_child(_menu_option("Logout", _request_logout))
	box.add_child(_secondary_button("Închide", _close_menu))

func _request_logout() -> void:
	_close_menu()
	logout_requested.emit()

func _menu_option(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = _dp(44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(b, 13)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", TEXT)
	b.add_theme_color_override("font_pressed_color", TEXT)
	b.add_theme_stylebox_override("normal", _style(SOFT, BORDER, 14, 1))
	b.add_theme_stylebox_override("hover", _style(SOFT, BORDER, 14, 1))
	b.add_theme_stylebox_override("pressed", _style(Color.WHITE, BLUE, 14, 3))
	b.pressed.connect(cb)
	_make_bouncy(b)
	return b

func _toggle_menu() -> void:
	if _menu_open:
		_close_menu()
	else:
		_open_menu()

func _open_menu() -> void:
	if not is_instance_valid(_menu_overlay):
		return
	_menu_open = true
	_menu_overlay.visible = true
	_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_overlay.modulate.a = 0.0
	var panel := _menu_overlay.get_node_or_null("MenuCenter/MenuPanel") as Control
	if panel != null:
		panel.scale = Vector2(0.92, 0.92)
		panel.modulate.a = 0.0
		panel.pivot_offset = panel.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_menu_overlay, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if panel != null:
		tween.tween_property(panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(panel, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _close_menu() -> void:
	if not _menu_open or not is_instance_valid(_menu_overlay):
		return
	_menu_open = false
	var panel := _menu_overlay.get_node_or_null("MenuCenter/MenuPanel") as Control
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_menu_overlay, "modulate:a", 0.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if panel != null:
		tween.tween_property(panel, "scale", Vector2(0.96, 0.96), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(_menu_overlay):
			_menu_overlay.visible = false
			_menu_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
