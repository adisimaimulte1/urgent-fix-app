extends Node

signal auth_started
signal auth_succeeded(user: Dictionary)
signal auth_failed(message: String)
signal session_validated(user: Dictionary)
signal session_invalid(message: String)
signal signed_out

const FirebaseConfig := preload("res://app/scripts/firebase/FirebaseConfig.gd")
const SESSION_PATH := "user://urgentfix_firebase_session.json"

var _http: HTTPRequest
var current_user: Dictionary = {}
var _pending_mode := ""
var last_auth_mode := ""

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 20.0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	_load_session()

func is_signed_in() -> bool:
	return not current_user.is_empty() and str(current_user.get("idToken", "")) != "" and str(current_user.get("localId", "")) != ""

func id_token() -> String:
	return str(current_user.get("idToken", ""))

func uid() -> String:
	return str(current_user.get("localId", ""))

func email() -> String:
	return str(current_user.get("email", ""))

func validate_current_session() -> void:
	if _http == null:
		session_invalid.emit("Serviciul Firebase Auth nu este inițializat.")
		return
	if not is_signed_in():
		session_invalid.emit("Nu există o sesiune salvată validă local.")
		return
	if not FirebaseConfig.is_configured():
		session_invalid.emit("FirebaseConfig.gd nu este completat cu API_KEY și PROJECT_ID.")
		return
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		session_invalid.emit("Există deja o cerere de autentificare în curs.")
		return
	_pending_mode = "session_validate"
	auth_started.emit()
	var body := JSON.stringify({"idToken": id_token()})
	var err := _http.request(FirebaseConfig.AUTH_LOOKUP_URL % FirebaseConfig.API_KEY, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if err != OK:
		session_invalid.emit("Nu am putut verifica sesiunea Firebase: %s" % str(err))

func sign_up(email_value: String, password_value: String) -> void:
	_send_auth_request("signup", FirebaseConfig.AUTH_SIGN_UP_URL % FirebaseConfig.API_KEY, email_value, password_value)

func sign_in(email_value: String, password_value: String) -> void:
	_send_auth_request("signin", FirebaseConfig.AUTH_SIGN_IN_URL % FirebaseConfig.API_KEY, email_value, password_value)

func sign_out() -> void:
	current_user.clear()
	last_auth_mode = ""
	if FileAccess.file_exists(SESSION_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_PATH))
	signed_out.emit()

func _send_auth_request(mode: String, url: String, email_value: String, password_value: String) -> void:
	if _http == null:
		auth_failed.emit("Serviciul Firebase Auth nu este inițializat.")
		return
	if not FirebaseConfig.is_configured():
		auth_failed.emit("FirebaseConfig.gd nu este completat cu API_KEY și PROJECT_ID.")
		return
	if email_value.strip_edges() == "" or password_value.length() < 6:
		auth_failed.emit("Email invalid sau parolă prea scurtă. Firebase cere minim 6 caractere.")
		return
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		auth_failed.emit("Există deja o cerere de autentificare în curs.")
		return
	_pending_mode = mode
	auth_started.emit()
	var body := JSON.stringify({"email": email_value.strip_edges(), "password": password_value, "returnSecureToken": true})
	var err := _http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if err != OK:
		auth_failed.emit("Nu am putut porni cererea Firebase: %s" % str(err))

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var mode := _pending_mode
	if result != HTTPRequest.RESULT_SUCCESS:
		_emit_request_error(mode, "Conexiunea către Firebase a eșuat. Verifică internetul și încearcă din nou.")
		return
	var raw := body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(raw)
	if response_code < 200 or response_code >= 300:
		_emit_request_error(mode, _friendly_auth_error(parsed, response_code))
		return
	if not (parsed is Dictionary):
		_emit_request_error(mode, "Răspuns Firebase invalid.")
		return
	if mode == "session_validate":
		_handle_session_lookup(parsed as Dictionary)
		return
	last_auth_mode = mode
	current_user = (parsed as Dictionary).duplicate(true)
	_save_session()
	auth_succeeded.emit(current_user)

func _handle_session_lookup(parsed: Dictionary) -> void:
	var users: Variant = parsed.get("users", [])
	if not (users is Array) or (users as Array).is_empty():
		_clear_invalid_session("Sesiunea salvată nu mai este validă.")
		return
	var user_data: Variant = (users as Array)[0]
	if not (user_data is Dictionary):
		_clear_invalid_session("Răspuns Firebase invalid pentru sesiunea salvată.")
		return
	var server_uid := str((user_data as Dictionary).get("localId", ""))
	if server_uid == "" or server_uid != uid():
		_clear_invalid_session("UID-ul sesiunii nu mai este valid.")
		return
	if str((user_data as Dictionary).get("email", "")) != "":
		current_user["email"] = str((user_data as Dictionary).get("email", current_user.get("email", "")))
	last_auth_mode = "session"
	_save_session()
	session_validated.emit(current_user.duplicate(true))

func _emit_request_error(mode: String, message: String) -> void:
	if mode == "session_validate":
		_clear_invalid_session(message)
	else:
		auth_failed.emit(message)

func _clear_invalid_session(message: String) -> void:
	current_user.clear()
	last_auth_mode = ""
	if FileAccess.file_exists(SESSION_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_PATH))
	session_invalid.emit(message)

func _friendly_auth_error(parsed: Variant, response_code: int = 0) -> String:
	var code := "UNKNOWN_ERROR"
	if parsed is Dictionary:
		var error_data: Variant = parsed.get("error", {})
		if error_data is Dictionary:
			code = str(error_data.get("message", code))
	match code:
		"EMAIL_EXISTS": return "Există deja un cont cu emailul acesta."
		"EMAIL_NOT_FOUND", "INVALID_LOGIN_CREDENTIALS": return "Emailul sau parola nu sunt corecte."
		"INVALID_PASSWORD": return "Parola nu este corectă."
		"USER_DISABLED": return "Contul este dezactivat în Firebase."
		"INVALID_EMAIL": return "Emailul nu este valid."
		"WEAK_PASSWORD : Password should be at least 6 characters", "WEAK_PASSWORD": return "Parola trebuie să aibă cel puțin 6 caractere."
		"TOO_MANY_ATTEMPTS_TRY_LATER": return "Prea multe încercări. Încearcă din nou puțin mai târziu."
		_:
			if response_code == 0:
				return "Firebase Auth: %s" % code
			return "Firebase Auth %d: %s" % [response_code, code]

func _save_session() -> void:
	var file := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(current_user, "\t"))

func _load_session() -> void:
	if not FileAccess.file_exists(SESSION_PATH):
		return
	var file := FileAccess.open(SESSION_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and str(parsed.get("idToken", "")) != "":
		current_user = parsed.duplicate(true)
		last_auth_mode = "session"
