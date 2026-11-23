--!strict

local RuleCatalog = {
	HussHussCourt = {
		DisplayName = "HUSS HUSS! REACH THE COURT",
		Description = "Find the blue training court before twelve seconds pass.",
		Accent = Color3.fromRGB(255, 208, 66),
	},
	KeepMoving = {
		DisplayName = "KEEP MOVING",
		Description = "Stop for too long and the town will notice.",
		Accent = Color3.fromRGB(255, 197, 61),
	},
	DoNotJump = {
		DisplayName = "DO NOT JUMP",
		Description = "Keep both feet under control.",
		Accent = Color3.fromRGB(89, 184, 255),
	},
	DoNotTouchRed = {
		DisplayName = "DO NOT TOUCH RED",
		Description = "Red surfaces are forbidden.",
		Accent = Color3.fromRGB(239, 67, 75),
	},
	StayInTheLight = {
		DisplayName = "STAY IN THE LIGHT",
		Description = "The darkness gives you three seconds.",
		Accent = Color3.fromRGB(255, 234, 122),
	},
	DoNotGoInside = {
		DisplayName = "DO NOT GO INSIDE",
		Description = "The buildings are closed by order of the Mayor.",
		Accent = Color3.fromRGB(174, 112, 255),
	},
	StayNearSomeone = {
		DisplayName = "STAY NEAR SOMEONE",
		Description = "Do not remain alone for more than four seconds.",
		Accent = Color3.fromRGB(255, 130, 188),
	},
	FreezeOnBell = {
		DisplayName = "FREEZE WHEN THE BELL RINGS",
		Description = "Move during the bell and you are out.",
		Accent = Color3.fromRGB(91, 222, 190),
	},
	HoldSomethingBlue = {
		DisplayName = "HOLD SOMETHING BLUE",
		Description = "Find a blue object before time runs out.",
		Accent = Color3.fromRGB(45, 125, 255),
	},
	AvoidTheMayor = {
		DisplayName = "AVOID THE MAYOR",
		Description = "He is faster than he looks.",
		Accent = Color3.fromRGB(204, 46, 59),
	},
	FloorIsLava = {
		DisplayName = "THE FLOOR IS LAVA",
		Description = "Find high ground before the street heats up.",
		Accent = Color3.fromRGB(255, 111, 42),
	},
}

return table.freeze(RuleCatalog)

