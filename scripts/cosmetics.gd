class_name Cosmetics
## Everything the crumb shop sells. Ids are saved, so don't rename them.

const HATS := [
	{"id": "none", "name": "no hat", "cost": 0},
	{"id": "bow", "name": "bow", "cost": 30},
	{"id": "party", "name": "party hat", "cost": 50},
	{"id": "beanie", "name": "beanie", "cost": 75},
	{"id": "flower", "name": "flower", "cost": 75},
	{"id": "shades", "name": "shades", "cost": 100},
	{"id": "chef", "name": "chef hat", "cost": 125},
	{"id": "tophat", "name": "top hat", "cost": 150},
	{"id": "headphones", "name": "headphones", "cost": 175},
	{"id": "crown", "name": "crown", "cost": 250},
]

const COLORS := [
	{"id": "classic", "name": "classic", "cost": 0, "body": Color("e09c94"), "belly": Color("e0b494")},
	{"id": "mint", "name": "mint", "cost": 25, "body": Color("9cd894"), "belly": Color("f8f8f8")},
	{"id": "lemon", "name": "lemon", "cost": 25, "body": Color("e0dc9c"), "belly": Color("e0b494")},
	{"id": "sky", "name": "sky", "cost": 40, "body": Color("94b4d8"), "belly": Color("f8f8f8")},
	{"id": "lilac", "name": "lilac", "cost": 40, "body": Color("bc94d8"), "belly": Color("dc94d4")},
	{"id": "bubblegum", "name": "bubblegum", "cost": 60, "body": Color("dc94d4"), "belly": Color("f8f8f8")},
	{"id": "peach", "name": "peach", "cost": 60, "body": Color("e0b494"), "belly": Color("e0dc9c")},
	{"id": "ghost", "name": "ghost", "cost": 90, "body": Color("d8d4d8"), "belly": Color("f8f8f8")},
	{"id": "teal", "name": "teal", "cost": 120, "body": Color("009c8c"), "belly": Color("9cd894")},
]


static func find(list: Array, id: String) -> Dictionary:
	for item in list:
		if item.id == id:
			return item
	return list[0]
