extends RefCounted

const API_KEY := "AIzaSyAtjQivji9p9tBNativPOJxQvKdrPoAetU"
const PROJECT_ID := "urgentfix-a6bab"
const DATABASE_ID := "(default)"

const AUTH_SIGN_UP_URL := "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=%s"
const AUTH_SIGN_IN_URL := "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=%s"
const AUTH_LOOKUP_URL := "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=%s"
const FIRESTORE_BASE_URL := "https://firestore.googleapis.com/v1/projects/%s/databases/%s/documents"

static func is_configured() -> bool:
	return API_KEY != "" and PROJECT_ID != "" and not API_KEY.begins_with("PASTE_") and not PROJECT_ID.begins_with("PASTE_")

static func firestore_base_url() -> String:
	return FIRESTORE_BASE_URL % [PROJECT_ID, DATABASE_ID]
