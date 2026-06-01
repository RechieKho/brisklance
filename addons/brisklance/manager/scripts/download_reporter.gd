extends Timer
class_name DownloadReporter

var node_http_request : HTTPRequest

static func start_report(
	p_http_request: HTTPRequest,
	p_wait_time := 0.5
) -> DownloadReporter:
	var reporter := DownloadReporter.new()
	reporter.node_http_request = p_http_request
	reporter.ignore_time_scale = true
	reporter.autostart = true
	reporter.wait_time = p_wait_time
	reporter.one_shot = false
	p_http_request.add_sibling(reporter)
	return reporter

func print_downloaded_bytes() -> void:
	if not node_http_request: return
	var downloaded_bytes := node_http_request.get_downloaded_bytes()
	print("Downloaded bytes: ", downloaded_bytes)


func _on_self_timeout() -> void:
	print_downloaded_bytes()

func _on_node_http_request_request_completed(
	_p_result: int,
	_p_response_code: int,
	_p_headers: PackedStringArray,
	_p_body: PackedByteArray
) -> void:
	print_downloaded_bytes()
	queue_free()

func _ready() -> void:
	timeout.connect(_on_self_timeout)
	node_http_request.request_completed.connect(_on_node_http_request_request_completed)
