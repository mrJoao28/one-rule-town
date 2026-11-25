--!strict

export type PlayerData = {
	Coins: number,
	Wins: number,
	RoundsPlayed: number,
	BestWinStreak: number,
	CurrentWinStreak: number,
	LastDailyWin: string,
	ReviveCredits: number,
	OwnedCosmetics: { [string]: boolean },
	EquippedCosmetic: string,
	ProcessedReceipts: { string },
	DataVersion: number,
}

export type RuleContext = {
	MapService: any,
	GetAlivePlayers: () -> { Player },
	IsAlive: (Player) -> boolean,
	Eliminate: (Player, string) -> (),
	BroadcastEffect: (string, any?) -> (),
	Active: boolean,
	StartedAt: number,
}

return nil

