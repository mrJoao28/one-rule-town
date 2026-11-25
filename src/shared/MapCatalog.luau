--!strict

-- Every map keeps the same rule landmarks so voting never makes a rule impossible.
local MapCatalog = {
	{ Name = "Sunny Square", Theme = "Plaza", FeaturedRule = "StayInTheLight" },
	{ Name = "Festival Night", Theme = "Festival", FeaturedRule = "FreezeOnBell" },
	{ Name = "Market Rush", Theme = "Market", FeaturedRule = "FindTheYellowSpot" },
}

return table.freeze(MapCatalog)
