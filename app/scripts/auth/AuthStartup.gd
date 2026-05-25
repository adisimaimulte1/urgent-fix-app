extends Control

const FIREBASE_AUTH_GATE_SCRIPT := preload("res://app/scripts/firebase/FirebaseAuthGate.gd")
const FIREBASE_AUTH_SERVICE_SCRIPT := preload("res://app/scripts/firebase/FirebaseAuthService.gd")
const FIRESTORE_SERVICE_SCRIPT := preload("res://app/scripts/firebase/FirestoreService.gd")
const UF_LOADING_SPINNER_SCRIPT := preload("res://app/scripts/ui/UFLoadingSpinner.gd")
const MAIN_APP_SCENE_PATH := "res://app/scenes/Main.tscn"

var _auth_gate: Control
var _auth_service: Node
var _firestore_service: Node
var _app_font: Font
var _scale := 1.0
var _current_profile: Dictionary = {}
var _pending_auth_profile: Dictionary = {}
var _pending_final_profile: Dictionary = {}
var _pending_profile_save := false
var _auth_busy := false
var _loading_overlay: Control

func _enter_tree() -> void:
	RenderingServer.set_default_clear_color(Color.WHITE)

func _ready() -> void:
	_load_font_if_available()
	_compute_scale()
	_start_auth_flow()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_compute_scale()
		if is_instance_valid(_auth_gate) and _auth_gate.has_method("setup"):
			_auth_gate.call("setup", _scale, _app_font)

func _compute_scale() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		_scale = 1.0
		return
	var raw_scale := minf(viewport_size.x / 390.0, viewport_size.y / 844.0)
	_scale = clampf(raw_scale, 0.86, 2.65)

func _load_font_if_available() -> void:
	var system_font := SystemFont.new()
	system_font.font_names = PackedStringArray(["Arial", "Roboto", "Noto Sans", "Helvetica", "Sans Serif"])
	system_font.font_weight = 800
	system_font.allow_system_fallback = true
	_app_font = system_font

func _start_auth_flow() -> void:
	_clear_children()
	_ensure_auth_service()
	_ensure_firestore_service()
	call_deferred("_choose_initial_screen")

func _ensure_auth_service() -> void:
	if is_instance_valid(_auth_service):
		return
	_auth_service = FIREBASE_AUTH_SERVICE_SCRIPT.new()
	_auth_service.name = "FirebaseAuthService"
	add_child(_auth_service)
	_auth_service.auth_started.connect(_on_auth_started)
	_auth_service.auth_succeeded.connect(_on_auth_succeeded)
	_auth_service.auth_failed.connect(_on_auth_failed)
	if _auth_service.has_signal("session_validated"):
		_auth_service.session_validated.connect(_on_session_validated)
	if _auth_service.has_signal("session_invalid"):
		_auth_service.session_invalid.connect(_on_session_invalid)
	_auth_service.signed_out.connect(_on_signed_out)

func _ensure_firestore_service() -> void:
	if is_instance_valid(_firestore_service):
		return
	_firestore_service = FIRESTORE_SERVICE_SCRIPT.new()
	_firestore_service.name = "FirestoreService"
	add_child(_firestore_service)
	_firestore_service.user_profile_loaded.connect(_on_user_profile_loaded)
	_firestore_service.user_profile_saved.connect(_on_user_profile_saved)
	_firestore_service.firestore_failed.connect(_on_firestore_failed)

func _choose_initial_screen() -> void:
	if not is_instance_valid(_auth_service):
		_show_auth_gate()
		return
	if _auth_service.has_method("is_signed_in") and bool(_auth_service.call("is_signed_in")):
		_show_loading_overlay()
		if _auth_service.has_method("validate_current_session"):
			_auth_service.call("validate_current_session")
		else:
			_on_session_invalid("Sesiunea nu poate fi verificată.")
	else:
		_show_auth_gate()

func _show_auth_gate() -> void:
	for child in get_children():
		if child != _auth_service and child != _firestore_service:
			child.queue_free()
	_loading_overlay = null
	_ensure_auth_service()
	_ensure_firestore_service()

	_auth_gate = FIREBASE_AUTH_GATE_SCRIPT.new()
	_auth_gate.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_auth_gate)
	_auth_gate.login_requested.connect(_on_login_requested)
	_auth_gate.register_requested.connect(_on_register_requested)

	if _auth_gate.has_method("setup"):
		_auth_gate.call("setup", _scale, _app_font)

func _on_login_requested(email: String, password: String, account_type: String) -> void:
	if _auth_busy:
		return
	_pending_auth_profile = {
		"email": email.strip_edges(),
		"account_type": _normalize_account_type(account_type),
		"auth_mode": "login"
	}
	_set_gate_status("", false)
	_show_loading_overlay()
	_auth_service.sign_in(email, password)

func _on_register_requested(email: String, password: String, account_type: String, profile_data: Dictionary) -> void:
	if _auth_busy:
		return
	_pending_auth_profile = profile_data.duplicate(true)
	_pending_auth_profile["email"] = email.strip_edges()
	_pending_auth_profile["account_type"] = _normalize_account_type(account_type)
	_pending_auth_profile["auth_mode"] = "register"
	_pending_auth_profile["created_at"] = Time.get_datetime_string_from_system()
	_set_gate_status("", false)
	_show_loading_overlay()
	_auth_service.sign_up(email, password)

func _on_session_validated(user: Dictionary) -> void:
	_auth_busy = false
	var profile := {
		"uid": str(user.get("localId", "")),
		"email": str(user.get("email", "")),
		"auth_mode": "session",
		"id_token": str(user.get("idToken", ""))
	}
	if profile["uid"] == "" or profile["id_token"] == "":
		_on_session_invalid("Sesiunea salvată nu are UID valid.")
		return
	_load_saved_profile(profile)

func _on_session_invalid(_message: String) -> void:
	_auth_busy = false
	_hide_loading_overlay()
	_pending_auth_profile.clear()
	_show_auth_gate()

func _on_auth_started() -> void:
	_auth_busy = true
	_show_loading_overlay()

func _on_auth_succeeded(user: Dictionary) -> void:
	_auth_busy = false
	var profile := _pending_auth_profile.duplicate(true)
	profile["uid"] = str(user.get("localId", ""))
	profile["email"] = str(user.get("email", profile.get("email", "")))
	profile["id_token"] = str(user.get("idToken", ""))
	if profile["uid"] == "" or profile["id_token"] == "":
		_on_auth_failed("Firebase nu a returnat UID sau token valid.")
		return
	_set_gate_status("", false)
	_show_loading_overlay()
	if str(profile.get("auth_mode", "")) == "register":
		_save_new_user_profile(profile)
	else:
		_load_saved_profile(profile)

func _on_auth_failed(message: String) -> void:
	_auth_busy = false
	_hide_loading_overlay()
	_set_gate_status(message, true)

func _on_signed_out() -> void:
	_auth_busy = false
	_hide_loading_overlay()
	_pending_auth_profile.clear()
	_show_auth_gate()


func _show_loading_overlay() -> void:
	if is_instance_valid(_loading_overlay):
		_loading_overlay.move_to_front()
		return

	_loading_overlay = Control.new()
	_loading_overlay.name = "AuthLoadingOverlay"
	_loading_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_loading_overlay.z_index = 4096
	add_child(_loading_overlay)

	var white_blur := ColorRect.new()
	white_blur.name = "LoadingWhiteBlur"
	white_blur.set_anchors_preset(Control.PRESET_FULL_RECT)
	white_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	white_blur.color = Color.WHITE

	var blur_shader := Shader.new()
	blur_shader.code = """
shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount = 3.25;
uniform float white_mix = 0.42;
uniform float overlay_alpha = 0.72;

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * blur_amount;
	vec2 uv = SCREEN_UV;
	vec4 col = texture(screen_texture, uv) * 0.20;
	col += texture(screen_texture, uv + vec2(px.x, 0.0)) * 0.10;
	col += texture(screen_texture, uv - vec2(px.x, 0.0)) * 0.10;
	col += texture(screen_texture, uv + vec2(0.0, px.y)) * 0.10;
	col += texture(screen_texture, uv - vec2(0.0, px.y)) * 0.10;
	col += texture(screen_texture, uv + vec2(px.x, px.y)) * 0.10;
	col += texture(screen_texture, uv + vec2(-px.x, px.y)) * 0.10;
	col += texture(screen_texture, uv + vec2(px.x, -px.y)) * 0.10;
	col += texture(screen_texture, uv + vec2(-px.x, -px.y)) * 0.10;
	col.rgb = mix(col.rgb, vec3(1.0), white_mix);
	COLOR = vec4(col.rgb, overlay_alpha);
}
"""
	var blur_material := ShaderMaterial.new()
	blur_material.shader = blur_shader
	white_blur.material = blur_material
	_loading_overlay.add_child(white_blur)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_overlay.add_child(center)

	var spinner := UF_LOADING_SPINNER_SCRIPT.new()
	spinner.custom_minimum_size = Vector2(123, 123)
	spinner.line_width = 10.5
	spinner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	spinner.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(spinner)

	spinner.scale = Vector2(0.88, 0.88)
	spinner.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(spinner, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(spinner, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _hide_loading_overlay() -> void:
	if not is_instance_valid(_loading_overlay):
		_loading_overlay = null
		return
	_loading_overlay.queue_free()
	_loading_overlay = null

func _save_new_user_profile(profile: Dictionary) -> void:
	_ensure_firestore_service()
	var db_profile := _database_profile(profile)
	_pending_final_profile = db_profile.duplicate(true)
	_pending_final_profile["id_token"] = str(profile.get("id_token", ""))
	_pending_profile_save = true
	_firestore_service.set_id_token(str(profile.get("id_token", "")))
	_firestore_service.save_user_profile(db_profile)

func _load_saved_profile(profile: Dictionary) -> void:
	_ensure_firestore_service()
	_pending_final_profile = profile.duplicate(true)
	_pending_profile_save = false
	_firestore_service.set_id_token(str(profile.get("id_token", "")))
	_firestore_service.load_user_profile(str(profile.get("uid", "")))

func _on_user_profile_loaded(saved_profile: Dictionary) -> void:
	var merged := _pending_final_profile.duplicate(true)
	if not saved_profile.is_empty():
		for key in saved_profile.keys():
			if str(key) != "id_token":
				merged[key] = saved_profile[key]
	else:
		var token := str(_pending_final_profile.get("id_token", ""))
		merged = _database_profile(merged)
		_pending_final_profile = merged.duplicate(true)
		_pending_final_profile["id_token"] = token
		_pending_profile_save = true
		_firestore_service.set_id_token(token)
		_firestore_service.save_user_profile(merged)
		return

	merged["uid"] = str(_pending_final_profile.get("uid", merged.get("uid", "")))
	merged["email"] = str(_pending_final_profile.get("email", merged.get("email", "")))
	merged["id_token"] = str(_pending_final_profile.get("id_token", ""))
	if not merged.has("account_type") and bool(merged.get("is_company", false)):
		merged["account_type"] = "company"
	merged["account_type"] = _normalize_account_type(str(merged.get("account_type", "client")))
	merged["is_company"] = merged["account_type"] == "company"
	call_deferred("_on_authenticated", merged)

func _on_user_profile_saved(saved_profile: Dictionary) -> void:
	if not _pending_profile_save:
		return
	_pending_profile_save = false
	var profile := saved_profile.duplicate(true)
	if str(profile.get("id_token", "")) == "":
		profile["id_token"] = str(_pending_final_profile.get("id_token", ""))
	call_deferred("_on_authenticated", profile)

func _on_firestore_failed(message: String) -> void:
	_auth_busy = false
	_hide_loading_overlay()
	_set_gate_status(message, true)

func _database_profile(profile: Dictionary) -> Dictionary:
	var account_type := _normalize_account_type(str(profile.get("account_type", "client")))
	var out := profile.duplicate(true)
	out["uid"] = str(profile.get("uid", ""))
	out["email"] = str(profile.get("email", ""))
	out["account_type"] = account_type
	out["is_company"] = account_type == "company"
	out["updated_at"] = Time.get_datetime_string_from_system()
	if not out.has("created_at") or str(out.get("created_at", "")).strip_edges() == "":
		out["created_at"] = Time.get_datetime_string_from_system()
	out.erase("id_token")
	out.erase("auth_mode")
	out["display_name"] = str(profile.get("display_name", out.get("display_name", ""))).strip_edges()
	out["phone"] = str(profile.get("phone", out.get("phone", ""))).strip_edges()
	if account_type != "company":
		out.erase("company_name")
	else:
		var company_name := str(profile.get("company_name", out.get("company_name", out.get("display_name", "")))).strip_edges()
		out["company_name"] = company_name
		out["display_name"] = company_name if company_name != "" else str(out.get("display_name", "")).strip_edges()
	return out

func _on_main_logout_requested() -> void:
	_current_profile.clear()
	_pending_auth_profile.clear()
	_pending_final_profile.clear()
	_pending_profile_save = false
	if is_instance_valid(_auth_service):
		_auth_service.sign_out()
	else:
		_show_auth_gate()

func _normalize_account_type(value: String) -> String:
	var cleaned := value.strip_edges().to_lower()
	match cleaned:
		"user", "client", "customer":
			return "client"
		"company", "firma", "firmă", "provider":
			return "company"
		_:
			return "client"

func _set_gate_status(text: String, is_error: bool) -> void:
	if is_instance_valid(_auth_gate) and _auth_gate.has_method("set_status"):
		_auth_gate.call("set_status", text, is_error)

func _on_authenticated(profile: Dictionary) -> void:
	_current_profile = profile.duplicate(true)
	_load_main_app()

func _load_main_app() -> void:
	_clear_children()

	var packed_scene := load(MAIN_APP_SCENE_PATH)
	if not (packed_scene is PackedScene):
		packed_scene = load("res://app/scenes/MainApp.tscn")
	if not (packed_scene is PackedScene):
		push_error("Main app scene not found at: " + MAIN_APP_SCENE_PATH)
		return

	var main_app: Node = packed_scene.instantiate()
	add_child(main_app)

	if main_app.has_signal("logout_requested"):
		main_app.logout_requested.connect(_on_main_logout_requested)

	if main_app.has_method("set_auth_profile"):
		main_app.call("set_auth_profile", _current_profile)
	elif main_app.has_method("set_account_profile"):
		main_app.call("set_account_profile", _current_profile)
	else:
		main_app.set_meta("auth_profile", _current_profile)
		main_app.set_meta("account_type", str(_current_profile.get("account_type", "client")))

func _clear_children() -> void:
	for child in get_children():
		if child != _auth_service and child != _firestore_service:
			child.queue_free()
	_loading_overlay = null
