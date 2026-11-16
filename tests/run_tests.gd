extends SceneTree

## Test runner for headless execution

var test_classes: Array = [
	"res://tests/test_player.gd",
	"res://tests/test_inventory.gd",
	"res://tests/test_combat.gd",
	"res://tests/test_survival.gd",
	"res://tests/test_zombie_ai.gd",
	"res://tests/test_save_load.gd",
	"res://tests/test_missions.gd",
]

var current_test_index: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var test_results: Array[Dictionary] = []

func _init() -> void:
	# Run as headless
	pass

func _ready() -> void:
	print("=== LAST NIGHT Test Suite ===")
	print("Godot Version: " + Engine.get_version_info()["string"])
	print("Running " + str(test_classes.size()) + " test modules...")
	print("")
	_run_next_test()

func _run_next_test() -> void:
	if current_test_index >= test_classes.size():
		_print_summary()
		quit(failed_tests)
		return
	
	var test_path = test_classes[current_test_index]
	print("Running: " + test_path)
	
	var test_script = load(test_path)
	if test_script:
		var test_instance = test_script.new()
		test_instance.run_tests().then(_on_test_completed.bind(test_path))
	else:
		print("  ERROR: Could not load test script")
		failed_tests += 1
		current_test_index += 1
		_run_next_test()

func _on_test_completed(test_path: String, result: Dictionary) -> void:
	var passed = result.get("passed", 0)
	var failed = result.get("failed", 0)
	var tests = result.get("tests", [])
	
	passed_tests += passed
	failed_tests += failed
	
	test_results.append({
		"module": test_path,
		"passed": passed,
		"failed": failed,
		"tests": tests
	})
	
	print("  Passed: " + str(passed) + ", Failed: " + str(failed))
	print("")
	
	current_test_index += 1
	_run_next_test()

func _print_summary() -> void:
	print("=== TEST SUMMARY ===")
	print("Total Modules: " + str(test_classes.size()))
	print("Total Passed: " + str(passed_tests))
	print("Total Failed: " + str(failed_tests))
	print("")
	
	for result in test_results:
		print("Module: " + result["module"])
		for test in result["tests"]:
			var status = "PASS" if test["passed"] else "FAIL"
			print("  [" + status + "] " + test["name"])
			if not test["passed"] and test.has("error"):
				print("    Error: " + test["error"])
		print("")

# Base test class
class TestBase:
	var passed: int = 0
	var failed: int = 0
	var tests: Array[Dictionary] = []
	
	func assert_true(condition: bool, name: String, error: String = "") -> void:
		if condition:
			passed += 1
			tests.append({"name": name, "passed": true})
		else:
			failed += 1
			tests.append({"name": name, "passed": false, "error": error})
	
	func assert_false(condition: bool, name: String, error: String = "") -> void:
		assert_true(not condition, name, error)
	
	func assert_equal(actual: Variant, expected: Variant, name: String) -> void:
		var success = actual == expected
		var error = ""
		if not success:
			error = "Expected: " + str(expected) + ", Got: " + str(actual)
		assert_true(success, name, error)
	
	func assert_not_equal(actual: Variant, expected: Variant, name: String) -> void:
		var success = actual != expected
		var error = ""
		if not success:
			error = "Values should not be equal: " + str(actual)
		assert_true(success, name, error)
	
	func get_results() -> Dictionary:
		return {
			"passed": passed,
			"failed": failed,
			"tests": tests
		}