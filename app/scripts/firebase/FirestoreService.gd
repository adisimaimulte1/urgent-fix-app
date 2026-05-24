extends Node

signal user_profile_loaded(profile: Dictionary)
signal user_profile_saved(profile: Dictionary)
signal requests_loaded(requests: Array)
signal request_saved(request: Dictionary)
signal requests_saved(requests: Array)
signal firestore_failed(message: String)

const FirebaseConfig := preload("res://app/scripts/firebase/FirebaseConfig.gd")

var _http: HTTPRequest
var _mode := ""
var _pending_request: Dictionary = {}
var _pending_requests: Array = []
var _pending_profile: Dictionary = {}
var _id_token := ""

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 25.0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

func set_id_token(token: String) -> void:
	_id_token = token

func load_user_profile(uid: String) -> void:
	if not _can_request():
		return
	_mode = "load_user_profile"
	_pending_profile.clear()
	var url := "%s/users/%s" % [FirebaseConfig.firestore_base_url(), uid.uri_encode()]
	_send(url, HTTPClient.METHOD_GET, "")

func save_user_profile(profile: Dictionary) -> void:
	if not _can_request():
		return
	var uid := str(profile.get("uid", ""))
	if uid == "":
		firestore_failed.emit("Profilul nu are UID.")
		return
	_mode = "save_user_profile"
	_pending_profile = profile.duplicate(true)
	var url := "%s/users/%s" % [FirebaseConfig.firestore_base_url(), uid.uri_encode()]
	_send(url, HTTPClient.METHOD_PATCH, JSON.stringify({"fields": _to_firestore_fields(_pending_profile)}))

func load_requests() -> void:
	if not _can_request():
		return
	_mode = "load_requests"
	_pending_request.clear()
	_pending_requests.clear()
	var url := "%s/requests" % FirebaseConfig.firestore_base_url()
	_send(url, HTTPClient.METHOD_GET, "")

func save_request(request_data: Dictionary) -> void:
	if not _can_request():
		return
	var request_id := str(request_data.get("id", "REQ-%d" % Time.get_unix_time_from_system())).uri_encode()
	_mode = "save_request"
	_pending_request = request_data.duplicate(true)
	var url := "%s/requests/%s" % [FirebaseConfig.firestore_base_url(), request_id]
	_send(url, HTTPClient.METHOD_PATCH, JSON.stringify({"fields": _to_firestore_fields(request_data)}))

func save_requests(requests: Array) -> void:
	_pending_requests = requests.duplicate(true)
	if _pending_requests.is_empty():
		requests_saved.emit([])
		return
	_save_requests_at_index(0)

func _save_requests_at_index(index: int) -> void:
	if index >= _pending_requests.size():
		requests_saved.emit(_pending_requests.duplicate(true))
		return
	if not (_pending_requests[index] is Dictionary):
		_save_requests_at_index(index + 1)
		return
	_mode = "save_requests:%d" % index
	_pending_request = (_pending_requests[index] as Dictionary).duplicate(true)
	var request_id := str(_pending_request.get("id", "REQ-%d" % Time.get_unix_time_from_system())).uri_encode()
	var url := "%s/requests/%s" % [FirebaseConfig.firestore_base_url(), request_id]
	_send(url, HTTPClient.METHOD_PATCH, JSON.stringify({"fields": _to_firestore_fields(_pending_request)}))

func _can_request() -> bool:
	if not FirebaseConfig.is_configured():
		firestore_failed.emit("FirebaseConfig.gd nu este completat.")
		return false
	if _id_token.strip_edges() == "":
		firestore_failed.emit("Nu există sesiune Firebase Auth activă.")
		return false
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return false
	return true

func _send(url: String, method: HTTPClient.Method, body: String) -> void:
	var headers := PackedStringArray(["Content-Type: application/json", "Authorization: Bearer %s" % _id_token])
	var err := _http.request(url, headers, method, body)
	if err != OK:
		firestore_failed.emit("Nu am putut porni cererea Firestore: %s" % str(err))

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var raw := body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(raw)
	if response_code == 404 and _mode == "load_user_profile":
		user_profile_loaded.emit({})
		return
	if response_code < 200 or response_code >= 300:
		firestore_failed.emit(_friendly_firestore_error(parsed, response_code))
		return
	if _mode == "load_user_profile":
		var profile := _parse_single_document(parsed)
		user_profile_loaded.emit(profile)
		return
	if _mode == "save_user_profile":
		user_profile_saved.emit(_pending_profile.duplicate(true))
		return
	if _mode == "load_requests":
		var requests := _parse_requests_list(parsed)
		requests_loaded.emit(requests)
		return
	if _mode == "save_request":
		request_saved.emit(_pending_request.duplicate(true))
		return
	if _mode.begins_with("save_requests:"):
		var index := int(_mode.get_slice(":", 1))
		call_deferred("_save_requests_at_index", index + 1)

func _parse_single_document(parsed: Variant) -> Dictionary:
	if parsed is Dictionary:
		var fields: Variant = parsed.get("fields", {})
		if fields is Dictionary:
			return _from_firestore_fields(fields)
	return {}

func _parse_requests_list(parsed: Variant) -> Array:
	var output: Array = []
	if not (parsed is Dictionary):
		return output
	var docs: Variant = parsed.get("documents", [])
	if not (docs is Array):
		return output
	for doc in docs:
		if doc is Dictionary:
			var fields: Variant = doc.get("fields", {})
			if fields is Dictionary:
				var request := _from_firestore_fields(fields)
				if request is Dictionary and not request.is_empty():
					output.append(request)
	output.sort_custom(func(a: Variant, b: Variant) -> bool:
		return str((b as Dictionary).get("created_at", "")) < str((a as Dictionary).get("created_at", ""))
	)
	return output

func _to_firestore_fields(data: Dictionary) -> Dictionary:
	var fields := {}
	for key in data.keys():
		fields[str(key)] = _to_firestore_value(data[key])
	return fields

func _to_firestore_value(value: Variant) -> Dictionary:
	match typeof(value):
		TYPE_BOOL:
			return {"booleanValue": value}
		TYPE_INT:
			return {"integerValue": str(value)}
		TYPE_FLOAT:
			return {"doubleValue": value}
		TYPE_ARRAY:
			var arr := []
			for item in value:
				arr.append(_to_firestore_value(item))
			return {"arrayValue": {"values": arr}}
		TYPE_DICTIONARY:
			return {"mapValue": {"fields": _to_firestore_fields(value)}}
		TYPE_NIL:
			return {"nullValue": null}
		_:
			return {"stringValue": str(value)}

func _from_firestore_fields(fields: Dictionary) -> Dictionary:
	var out := {}
	for key in fields.keys():
		out[str(key)] = _from_firestore_value(fields[key])
	return out

func _from_firestore_value(value: Variant) -> Variant:
	if not (value is Dictionary):
		return value
	var data := value as Dictionary
	if data.has("stringValue"):
		return str(data["stringValue"])
	if data.has("integerValue"):
		return int(data["integerValue"])
	if data.has("doubleValue"):
		return float(data["doubleValue"])
	if data.has("booleanValue"):
		return bool(data["booleanValue"])
	if data.has("nullValue"):
		return null
	if data.has("arrayValue"):
		var arr: Array = []
		var array_data: Variant = data["arrayValue"]
		if array_data is Dictionary:
			var values: Variant = array_data.get("values", [])
			if values is Array:
				for item in values:
					arr.append(_from_firestore_value(item))
		return arr
	if data.has("mapValue"):
		var map_data: Variant = data["mapValue"]
		if map_data is Dictionary:
			var fields: Variant = map_data.get("fields", {})
			if fields is Dictionary:
				return _from_firestore_fields(fields)
	return {}

func _friendly_firestore_error(parsed: Variant, response_code: int) -> String:
	var code := "HTTP_%d" % response_code
	if parsed is Dictionary:
		var error_data: Variant = parsed.get("error", {})
		if error_data is Dictionary:
			code = str(error_data.get("message", code))
	return "Firestore: %s" % code
