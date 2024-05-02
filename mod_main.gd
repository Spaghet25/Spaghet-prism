extends Node

const AUTHORNAME_MODNAME_DIR := "Spaghet-prism"
const AUTHORNAME_MODNAME_LOG_NAME := "Spaghet-prism:Main"

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""

@onready var modUtils = get_node("/root/ModLoader/ombrellus-modutils")

func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(AUTHORNAME_MODNAME_DIR)
	extensions_dir_path = mod_dir_path.path_join("extensions")
	
func _ready() -> void:
	ModLoaderLog.info("Ready!", AUTHORNAME_MODNAME_LOG_NAME)
	modUtils.addBossToPool(AUTHORNAME_MODNAME_DIR, "prism")
	modUtils.addBossToQueue(AUTHORNAME_MODNAME_DIR, "prism", 0)
