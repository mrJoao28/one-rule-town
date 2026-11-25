--!strict

local Config = {
	GameName = "One Rule Town",
	MinimumPlayers = 1,
	MaximumPlayers = 12,
	TargetTownPopulation = 6,
	IntermissionDuration = 8,
	FirstIntermissionDuration = 18,
	RuleRevealDuration = 6,
	RoundDuration = 45,
	ResultsDuration = 7,
	RuleCheckInterval = 0.1,
	ReviveCutoffSeconds = 10,
	DataStoreName = "OneRuleTown_PlayerData_v1",
	AutoSaveInterval = 60,

	Rewards = {
		Participation = 5,
		Survival = 25,
		SoloSurvivorBonus = 50,
		FirstWinToday = 50,
	},

	Monetization = {
		-- IDs from the One Rule Town Creator Dashboard.
		DeveloperProducts = {
			Revive = { Id = 3734973315, Amount = 1 },
			TokensSmall = { Id = 3734973609, Amount = 250 },
			TokensMedium = { Id = 3734973663, Amount = 750 },
			TokensLarge = { Id = 3734973705, Amount = 2000 },
		},
		GamePasses = {
			VIP = 2095886806,
			DoubleTokens = 2093448848,
		},
	},

	Cosmetics = {
		Default = {
			DisplayName = "No Effect",
			Price = 0,
			Color = Color3.fromRGB(255, 255, 255),
			Effect = "None",
		},
		BlueTrail = {
			DisplayName = "Town Blue Trail",
			Price = 100,
			Color = Color3.fromRGB(62, 170, 255),
			Effect = "Trail",
		},
		PinkTrail = {
			DisplayName = "Bubblegum Trail",
			Price = 175,
			Color = Color3.fromRGB(255, 111, 189),
			Effect = "Trail",
		},
		GoldTrail = {
			DisplayName = "Golden Rule Trail",
			Price = 300,
			Color = Color3.fromRGB(255, 204, 51),
			Effect = "Trail",
		},
		MayorAura = {
			DisplayName = "Mayor Aura",
			Price = 500,
			Color = Color3.fromRGB(212, 54, 68),
			Effect = "Highlight",
		},
		VIPGold = {
			DisplayName = "VIP Gold Aura",
			Price = 0,
			Color = Color3.fromRGB(255, 225, 92),
			Effect = "Highlight",
			RequiresVIP = true,
		},
	},
}

return table.freeze(Config)

