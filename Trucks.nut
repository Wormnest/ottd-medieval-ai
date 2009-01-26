class Trucks
{
	constructor()	
	function BuildTruckRoute()
	function BuildTruckStation(industryUsing, cargo, start);
	function FindDepot(town);
	function IsIndustryOccupied(industry);	
}

function Trucks::BuildTruckRoute()
{
	//INITALIZE INDUSTRYS
	local rawIndustryList = AIIndustryList();
	local rawIndustryTypes = AIIndustryTypeList();
	local secondaryIndustryTypes = AIIndustryTypeList();
	
	rawIndustryList.Valuate(AIIndustry.IsBuiltOnWater);
	rawIndustryList.KeepValue(0);
	if(rawIndustryList.Count() > 0)
		AILog.Info(AIIndustry.GetName(rawIndustryList.Begin()));
		
	else
	{
		AILog.Error("No industries found, aborting");
		return false;
	}
		
	AILog.Info("Num. Industries: " + rawIndustryList.Count());
	rawIndustryTypes.Valuate(AIIndustryType.IsRawIndustry);
	rawIndustryTypes.KeepValue(1);
	secondaryIndustryTypes.Valuate(AIIndustryType.IsRawIndustry);
	secondaryIndustryTypes.KeepValue(0);
	rawIndustryList.Valuate(AIIndustry.GetIndustryType);
	for(local i = secondaryIndustryTypes.Begin(); secondaryIndustryTypes.HasNext(); i = secondaryIndustryTypes.Next())
	{
		rawIndustryList.RemoveValue(i);
	}
	
	AILog.Info("Num. of Raw Industries: " + rawIndustryList.Count());

	//KEEP FREIGHT CARGOS, DON'T TRANSPORT PAX/MAIL
	local cargoList = AICargoList();
	cargoList.Valuate(AICargo.IsFreight);
	cargoList.KeepValue(1);

	for(local i = secondaryIndustryTypes.Begin(); secondaryIndustryTypes.HasNext(); i = secondaryIndustryTypes.Next())
	{
		local secondaryCargos = AIIndustryType.GetProducedCargo(i);
		cargoList.RemoveList(secondaryCargos);
	}
	
	cargoList.Valuate(AICargo.GetCargoIncome, 20, 200)
	cargoList.KeepTop(3);
	cargoList.Valuate(AIBase.RandItem);
	cargoList.KeepTop(1);
	local cargoInUse = cargoList.Begin();
	AILog.Info("Transporting " + AICargo.GetCargoLabel(cargoInUse));
	rawIndustryList = AIIndustryList_CargoProducing(cargoInUse);
	rawIndustryList.Valuate(AIIndustry.GetAmountOfStationsAround);
	rawIndustryList.KeepValue(0);
	rawIndustryList.Valuate(AIIndustry.GetLastMonthProduction, cargoInUse);
	rawIndustryList.KeepTop(1);
	AILog.Info("Taking " + AICargo.GetCargoLabel(cargoInUse) + " from " + AIIndustry.GetName(rawIndustryList.Begin()));
	local startTile = AIIndustry.GetLocation(rawIndustryList.Begin());
	local acceptingIndustryList = AIIndustryList_CargoAccepting(cargoInUse);
	AILog.Info("Count: " + acceptingIndustryList.Count());
	acceptingIndustryList.Valuate(AIIndustry.GetAmountOfStationsAround);
	acceptingIndustryList.KeepValue(0);

	local industry = null;
	for(local i = acceptingIndustryList.Begin(); acceptingIndustryList.HasNext(); i = acceptingIndustryList.Next())
	{
		AILog.Info("Finding industry to transport to...");
		local length = AIIndustry.GetDistanceManhattanToTile(i, startTile);
		if(length > 20 && length < 150)
		{
			industry = i;
			break;
		}
	}
	if(industry == null)
	{
		AILog.Info("Couldn't find suitable industry.");
		return false;
	}
	else
	{
		AILog.Info("Taking cargo to " + AIIndustry.GetName(industry));
		local startStation = Trucks.BuildTruckStation(startTile, cargoInUse, true)
		if(!startStation)
			return false;
		AILog.Info("Built first station");
		local endStation = Trucks.BuildTruckStation(AIIndustry.GetLocation(industry), cargoInUse, false)
		if(!endStation)
			return false;
		AILog.Info("Built second station");
		Paths.FindPath(startStation, endStation, true);
		local depot = BuildRoadDepot(startStation.location);
		Vehicles.AddVehiclesToRoute(cargoInUse, depot, startStation, endStation);
	}
}

function Trucks::BuildTruckStation(industryUsing, cargo, start)
{
	AILog.Info("Attempting to build truck station");
	local tileList = AITileList();
	tileList.AddRectangle(industryUsing - AIMap.GetTileIndex(-8, -8), industryUsing - AIMap.GetTileIndex(8, 8));
	local stationRadius = AIStation.GetCoverageRadius(AIStation.STATION_TRUCK_STOP);
	
	AILog.Info("Tile Count: " + tileList.Count());
	AISign.BuildSign(industryUsing, "Industry")
	
	if(start)
	{
		tileList.Valuate(AITile.GetCargoProduction, cargo, 1, 1, stationRadius);
		tileList.KeepAboveValue(0);
	}
	else
	{
		tileList.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, stationRadius);
		tileList.KeepAboveValue(7);
	}
	
	AILog.Info("Tile Count: " + tileList.Count());
	
	tileList.Valuate(AIRoad.IsRoadTile);
	tileList.KeepValue(0);
	
	AILog.Info("Tile Count: " + tileList.Count());
	
	tileList.Valuate(AITile.IsBuildable);
	tileList.KeepValue(1);
	
	AILog.Info("Tile Count: " + tileList.Count());
	
	tileList.Valuate(function (tile) {
		switch(AITile.GetSlope(tile)) {
			case AITile.SLOPE_FLAT:
			case AITile.SLOPE_NWS:
			case AITile.SLOPE_WSE:
			case AITile.SLOPE_SEN:
			case AITile.SLOPE_ENW:
				return 0;
			
			default:
				return 1;
		}
	})
		
	tileList.KeepValue(0);
	
	AILog.Info("Tile Count: " + tileList.Count());

	local randTile = Tile();
	randTile.SetAttribs(tileList.Begin())
	local adjacentTiles = GetAdjacentTiles(randTile.location, false);
	AILog.Info("aT:C(0) - " + adjacentTiles.Count());
	local tileInUse = "HEE";
	local tile;
	AILog.Info("Tile Count: " + tileList.Count());
	local foundTile = false;
	for(tile = tileList.Begin(); tileList.HasNext(); tile = tileList.Next())
	{
		//AILog.Info("Tile: " + tile)
		if(!foundTile)
		{
			adjacentTiles = AITileList();
			//AILog.Info("Tile: " + tile);
			//AISign.BuildSign(tile, "Tile: " + tile);
			//while(adjacentTiles.Count() < 3)
			//{
				randTile.SetAttribs(tile);
				adjacentTiles = GetAdjacentTiles(randTile.location, false);
				adjacentTiles.Valuate(AITile.IsBuildable);
				adjacentTiles.KeepValue(1);
				adjacentTiles.Valuate(function (tile) {
					switch(AITile.GetSlope(tile)) {
						case AITile.SLOPE_FLAT:
						case AITile.SLOPE_NWS:
						case AITile.SLOPE_WSE:
						case AITile.SLOPE_SEN:
						case AITile.SLOPE_ENW:
							return 0;
						
						default:
							return 1;
					}
				})
				adjacentTiles.KeepValue(0);
				if(adjacentTiles.Count() >= 3)
				{
					tileInUse = tile;
					foundTile = true;
					AISign.BuildSign(tileList.Begin(), "DTRS HERE");
				}
				//AILog.Info("aT:C(1) - " + adjacentTiles + ", Count: " + adjacentTiles.Count());
				//Sleep(100);
			//}
		}
	}
	AILog.Info("aT:C(2) - " + adjacentTiles.Count());
	if(adjacentTiles.Count() < 3)
		return false;
		
	local isStationBuilt = false;
	local thisStation = Tile();
	for(local i = adjacentTiles.Begin(); adjacentTiles.HasNext(); i = adjacentTiles.Next()) 
	{
		AILog.Info("New Adjacency...");
		if(AITile.IsBuildable(i) && !isStationBuilt) 
		{
			AILog.Info("Found a spot!");
			AITile.DemolishTile(tileInUse);
			AIRoad.BuildRoad(tileInUse, i);
			
			if(tileInUse - AIMap.GetTileIndex(1,0) == i)
			{
				AIRoad.BuildRoad(tileInUse, tileInUse + AIMap.GetTileIndex(1,0));
			}
			if(tileInUse + AIMap.GetTileIndex(1,0) == i)
			{
				AIRoad.BuildRoad(tileInUse, tileInUse - AIMap.GetTileIndex(1,0));
			}
			if(tileInUse - AIMap.GetTileIndex(0,1) == i)
			{
				AIRoad.BuildRoad(tileInUse, tileInUse + AIMap.GetTileIndex(0, 1));
			}
			if(tileInUse + AIMap.GetTileIndex(0,1) == i)
			{
				AIRoad.BuildRoad(tileInUse, tileInUse - AIMap.GetTileIndex(0, 1));
			}
			
			AITile.DemolishTile(tileInUse);
			
			while(!AIRoad.BuildRoadStation(tileInUse, i, true, true, false)) 
			{
				//AISign.BuildSign(tileList.Begin(), "HERE");
				AILog.Warning(AIError.GetLastErrorString());
				AILog.Info("Couldn't build station :(");
				Sleep(100);
				switch (AIError.GetLastError()) 
				{
					case AIError.ERR_AREA_NOT_CLEAR:
						if(!AITile.DemolishTile(tileInUse))
						{
							AILog.Info("Demolish error: " + AIError.GetLastErrorString());
							switch (AIError.GetLastError()) 
							{
								case AIError.ERR_OWNED_BY_ANOTHER_COMPANY:
								AILog.Info("Somebody beat me to it!");
								return false;
							}
						}
					case AIError.ERR_VEHICLE_IN_THE_WAY:
						break;
					case AIError.ERR_OWNED_BY_ANOTHER_COMPANY:
						AILog.Error("Somebody beat me to it!");
						return false;
					case AIError.ERR_LOCAL_AUTHORITY_REFUSES:
						AILog.Error("Town rating too low");
						return false;
					default:
						AILog.Warning(AIError.GetLastErrorString());
						AIRoad.BuildRoadDepot(tileInUse, i);
						AILog.Error(AIError.GetLastErrorString());
						AILog.Info(AIMap.IsValidTile(tileInUse) + ", Tile: " + tileInUse)
						AISign.BuildSign(tileInUse, tileInUse + "");
						AILog.Info(AIMap.IsValidTile(i) + ", Tile: " + i)
						AISign.BuildSign(i, i + "");
						break;
				}
			}
			
			local front = AIRoad.GetRoadStationFrontTile(tileInUse);
			local back = AIRoad.GetDriveThroughBackTile(tileInUse);
			
			if(tileInUse - AIMap.GetTileIndex(1,0) == front || tileInUse + AIMap.GetTileIndex(1,0) == front)
			{
				AIRoad.BuildRoad(tileInUse - AIMap.GetTileIndex(1,0), (tileInUse - AIMap.GetTileIndex(1,0)) - AIMap.GetTileIndex(0, 1));
				AIRoad.BuildRoad(tileInUse - AIMap.GetTileIndex(1,0), (tileInUse - AIMap.GetTileIndex(1,0)) + AIMap.GetTileIndex(0, 1));
				AIRoad.BuildRoad(tileInUse + AIMap.GetTileIndex(1,0), (tileInUse + AIMap.GetTileIndex(1,0)) - AIMap.GetTileIndex(0, 1));
				AIRoad.BuildRoad(tileInUse + AIMap.GetTileIndex(1,0), (tileInUse + AIMap.GetTileIndex(1,0)) + AIMap.GetTileIndex(0, 1));
				AIRoad.BuildRoad((tileInUse - AIMap.GetTileIndex(1,0)) - AIMap.GetTileIndex(0, 1), (tileInUse + AIMap.GetTileIndex(1,0)) - AIMap.GetTileIndex(0, 1));
				AIRoad.BuildRoad((tileInUse - AIMap.GetTileIndex(1,0)) + AIMap.GetTileIndex(0, 1), (tileInUse + AIMap.GetTileIndex(1,0)) + AIMap.GetTileIndex(0, 1));
			}

			if(tileInUse - AIMap.GetTileIndex(0,1) == front || tileInUse + AIMap.GetTileIndex(0,1) == front)
			{
				AIRoad.BuildRoad(tileInUse - AIMap.GetTileIndex(0,1), (tileInUse - AIMap.GetTileIndex(0,1)) - AIMap.GetTileIndex(1, 0));
				AIRoad.BuildRoad(tileInUse - AIMap.GetTileIndex(0,1), (tileInUse - AIMap.GetTileIndex(0,1)) + AIMap.GetTileIndex(1, 0));
				AIRoad.BuildRoad(tileInUse + AIMap.GetTileIndex(0,1), (tileInUse + AIMap.GetTileIndex(0,1)) - AIMap.GetTileIndex(1, 0));
				AIRoad.BuildRoad(tileInUse + AIMap.GetTileIndex(0,1), (tileInUse + AIMap.GetTileIndex(0,1)) + AIMap.GetTileIndex(1, 0));
				AIRoad.BuildRoad((tileInUse - AIMap.GetTileIndex(0,1)) - AIMap.GetTileIndex(1, 0), (tileInUse + AIMap.GetTileIndex(0,1)) - AIMap.GetTileIndex(1, 0));
				AIRoad.BuildRoad((tileInUse - AIMap.GetTileIndex(0,1)) + AIMap.GetTileIndex(1, 0), (tileInUse + AIMap.GetTileIndex(0,1)) + AIMap.GetTileIndex(1, 0));
			}
		
			thisStation.SetAttribs(tileInUse);
			isStationBuilt = true
		}
	}
	AILog.Warning("BuildTruckStation: " + AIError.GetLastErrorString());
	return thisStation;
}
