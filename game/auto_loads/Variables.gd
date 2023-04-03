extends Node

# Used for input remapping and control displays
var user_keys := PoolStringArray([
	"pause",
	"interact",
	"up",
	"left",
	"down",
	"right"
])

# Used for formatting strings to display the correct key.
var input_format := {}

var rng := RandomNumberGenerator.new()

var hints := {}

var restarted := false

var played_boss := false
