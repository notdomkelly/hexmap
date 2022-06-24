extends Node2D


func _on_LaunchHexWaveCollapseBtn_pressed():
	get_tree().change_scene("res://scenes/HexWaveCollapseGen.tscn")


func _on_LaunchHexPNoiseBtn_pressed():
	get_tree().change_scene("res://scenes/HexNoiseGen.tscn")
