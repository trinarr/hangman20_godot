extends Node

#
# -------------------------
# SETTINGS
# -------------------------
#

var language: String = "en"
var difficulty: int = 0

#
# -------------------------
# CURRENT GAME
# -------------------------
#

var current_theme: int = 0
var current_word_index: int = -1

var mistakes: int = 0
var max_mistakes: int = 6

#
# -------------------------
# PLAYER
# -------------------------
#

var coins: int = 0

#
# -------------------------
# STATISTICS
# -------------------------
#

var progress: Array[ThemeProgress] = []

#
# -------------------------
# INITIALIZATION
# -------------------------
#

func _ready():
	reset_game()


func reset_game():

	current_theme = 0
	current_word_index = -1

	mistakes = 0
