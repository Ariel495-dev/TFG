# StatsUtils.gd — Autoload
extends Node

func stat_progression(level: int) -> float:
	return pow(1.08, level)
