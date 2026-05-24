extends ScrollContainer
class_name UFKeyboardAwareScroll

@export var extra_padding := 18
@export var focus_margin := 14
@export var reset_duration := 0.28
@export var keep_content_screen_sized := true
@export var reset_scroll_when_keyboard_hidden := false
@export var reset_frames_after_keyboard_hidden := 2

var bottom_spacer: Control
var _largest_viewport_height := 0.0
var _last_keyboard_overlap := -1
var _keyboard_was_visible := false
var _reset_tween: Tween
var _pending_reset_frames := 0
var _locked_keyboard_padding := false
var _pending_clear_padding := false

func _ready() -> void:
	follow_focus = false
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	set_process(true)
	_largest_viewport_height = get_viewport_rect().size.y
	_keyboard_was_visible = _keyboard_visible()
	_update_content_minimum_height()
	_update_keyboard_padding()

func set_bottom_spacer(spacer: Control) -> void:
	bottom_spacer = spacer
	_update_keyboard_padding()

func _process(_delta: float) -> void:
	follow_focus = false
	_update_content_minimum_height()
	_update_keyboard_padding()
	_handle_keyboard_state()
	_scroll_focused_control_into_safe_area()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_largest_viewport_height()
		_update_content_minimum_height()
		_update_keyboard_padding()
		call_deferred("_handle_keyboard_state")
		call_deferred("_scroll_focused_control_into_safe_area")

func _update_largest_viewport_height() -> void:
	var viewport_height := get_viewport_rect().size.y
	if viewport_height > _largest_viewport_height:
		_largest_viewport_height = viewport_height

func _update_content_minimum_height() -> void:
	_update_largest_viewport_height()
	if not keep_content_screen_sized or get_child_count() <= 0:
		return

	var target_height := maxf(_largest_viewport_height, get_viewport_rect().size.y)
	var content := get_child(0)
	if content is Control:
		var content_control := content as Control
		content_control.custom_minimum_size.y = maxf(content_control.custom_minimum_size.y, target_height)

		if content_control.get_child_count() > 0:
			var first := content_control.get_child(0)
			if first is Control:
				var first_control := first as Control
				first_control.custom_minimum_size.y = maxf(first_control.custom_minimum_size.y, target_height)

func _update_keyboard_padding() -> void:
	_update_largest_viewport_height()

	var overlap := _keyboard_overlap_px()
	if overlap == _last_keyboard_overlap:
		return
	_last_keyboard_overlap = overlap

	if overlap > 0:
		_locked_keyboard_padding = false
		_pending_clear_padding = false
		_set_bottom_padding(float(overlap + extra_padding))
		call_deferred("_scroll_focused_control_into_safe_area")
		return

	if _locked_keyboard_padding:
		return

	if _keyboard_was_visible and reset_scroll_when_keyboard_hidden:
		_locked_keyboard_padding = true
		_pending_clear_padding = true
		return

	_clear_bottom_padding()

func _handle_keyboard_state() -> void:
	var keyboard_visible_now := _keyboard_visible()

	if keyboard_visible_now:
		_keyboard_was_visible = true
		_pending_reset_frames = 0
		_locked_keyboard_padding = false
		_pending_clear_padding = false
		if _reset_tween != null:
			_reset_tween.kill()
			_reset_tween = null
		return

	if _keyboard_was_visible:
		_pending_reset_frames = reset_frames_after_keyboard_hidden
		_keyboard_was_visible = false
		if reset_scroll_when_keyboard_hidden and scroll_vertical > 0:
			_locked_keyboard_padding = true
			_pending_clear_padding = true
			_set_bottom_padding(float(scroll_vertical + extra_padding))

	if not reset_scroll_when_keyboard_hidden:
		if _pending_clear_padding:
			_clear_bottom_padding()
		return

	if _pending_reset_frames > 0:
		_pending_reset_frames = maxi(0, _pending_reset_frames - 1)
		return

	if scroll_vertical != 0 and _reset_tween == null:
		_animate_scroll_reset()
	elif scroll_vertical == 0 and _pending_clear_padding:
		_finish_keyboard_reset()

func _keyboard_visible() -> bool:
	if _raw_keyboard_height_px() > 0:
		return true

	var viewport_height := get_viewport_rect().size.y
	return _largest_viewport_height > 0.0 and viewport_height < _largest_viewport_height - 4.0

func _keyboard_overlap_px() -> int:
	var keyboard_height := _raw_keyboard_height_px()
	var viewport_height := get_viewport_rect().size.y
	var viewport_was_resized := _largest_viewport_height > 0.0 and viewport_height < _largest_viewport_height - 4.0
	if viewport_was_resized:
		return 0
	return keyboard_height

func _raw_keyboard_height_px() -> int:
	if DisplayServer.has_method("virtual_keyboard_get_height"):
		return maxi(0, int(DisplayServer.virtual_keyboard_get_height()))
	return 0

func _scroll_focused_control_into_safe_area() -> void:
	if not is_inside_tree() or not _keyboard_visible():
		return

	var focused := get_viewport().gui_get_focus_owner()
	if not (focused is Control):
		return

	var focused_control := focused as Control
	if focused_control == self or not is_ancestor_of(focused_control):
		return

	if _reset_tween != null:
		_reset_tween.kill()
		_reset_tween = null

	var scroll_rect := get_global_rect()
	var focus_rect := focused_control.get_global_rect()
	var overlap := _keyboard_overlap_px()
	var safe_top := scroll_rect.position.y + float(focus_margin)
	var safe_bottom := scroll_rect.end.y - float(overlap) - float(focus_margin)
	if safe_bottom <= safe_top:
		safe_bottom = scroll_rect.end.y - float(focus_margin)

	if focus_rect.end.y > safe_bottom:
		scroll_vertical += int(ceil(focus_rect.end.y - safe_bottom))
	elif focus_rect.position.y < safe_top:
		scroll_vertical -= int(ceil(safe_top - focus_rect.position.y))

func _animate_scroll_reset() -> void:
	if _reset_tween != null:
		_reset_tween.kill()
		_reset_tween = null

	if scroll_vertical == 0:
		_finish_keyboard_reset()
		return

	_reset_tween = create_tween()
	_reset_tween.set_trans(Tween.TRANS_CUBIC)
	_reset_tween.set_ease(Tween.EASE_OUT)
	_reset_tween.tween_property(self, "scroll_vertical", 0, reset_duration)
	_reset_tween.finished.connect(_on_reset_tween_finished)

func _on_reset_tween_finished() -> void:
	_reset_tween = null
	if not _keyboard_visible():
		scroll_vertical = 0
		set_deferred("scroll_vertical", 0)
		_finish_keyboard_reset()

func _finish_keyboard_reset() -> void:
	_locked_keyboard_padding = false
	_pending_clear_padding = false
	_clear_bottom_padding()

func _set_bottom_padding(value: float) -> void:
	if is_instance_valid(bottom_spacer):
		bottom_spacer.custom_minimum_size.y = maxf(0.0, value)

func _clear_bottom_padding() -> void:
	_set_bottom_padding(0.0)
