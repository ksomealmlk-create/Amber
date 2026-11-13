extends RefCounted
# سجل المراحل + الحالة المشتركة بين الشاشات (العالم/المرحلة الحاليان).
# يقرأ المراحل من scripts/levels/data_wN.gd (مولَّدة من Dart بواسطة tools/export_all.py).

const W1 = preload("res://scripts/levels/data_w1.gd")
const W2 = preload("res://scripts/levels/data_w2.gd")
const W3 = preload("res://scripts/levels/data_w3.gd")

static var world: int = 1
static var index: int = 1

static func has_level(w: int, i: int) -> bool:
	return w >= 1 and w <= 3 and i >= 1 and i <= 10

static func get_level(w: int, i: int) -> Dictionary:
	match w:
		1: return W1.LEVELS[i - 1]
		2: return W2.LEVELS[i - 1]
		3: return W3.LEVELS[i - 1]
	return W1.LEVELS[0]

static func current() -> Dictionary:
	return get_level(world, index)

# ينتقل للمرحلة التالية؛ يعيد false إن لم توجد
static func advance() -> bool:
	var w := world
	var i := index + 1
	if i > 10:
		w += 1
		i = 1
	if not has_level(w, i):
		return false
	world = w
	index = i
	return true
