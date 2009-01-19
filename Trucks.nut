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
	
	AILog.Info("Num. Industries: " + rawIndustryList.Count());
	for(local i = rawIndustryList.Begin(); rawIndustryList.HasNext(); i = rawIndustryList.Next())
	{
		AILog.Info(AIIndustry.GetName(i));
	}
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
	local cargoInUse = cargoList.Begin();
	Vehicles.CheckForVehiclesNeeded(cargoInUse);
	AILog.Info(AICargo.GetCargoLabel(cargoInUse) + " is the most effective cargo to transport.");
	rawIndustryList = AIIndustryList_CargoProducing(cargoInUse);
	rawIndustryList.Valuate(AIIndustry.GetAmountOfStationsAround);
	rawIndustryList.KeepValue(0);
	rawIndustryList.Valuate(AIIndustry.GetLastMonthProduction, cargoInUse);
	rawIndustryList.KeepTop(1);
	AILog.Info("Taking " + AICargo.GetCargoLabel(cargoInUse) + " from " + AIIndustry.GetName(rawIndustryList.Begin()));
	local acceptingIndustryList = AIIndustryList_CargoAccepting(cargoInUse);
	AILog.Info("Count: " + acceptingIndustryList.Count());
	acceptingIndustryList.Valuate(AIIndustry.GetAmountOfStationsAround);
	acceptingIndustryList.KeepValue(0);
	local startTile = AIIndustry.GetLocation(rawIndustryList.Begin());
	local industry = null;
	for(local i = acceptingIndustryList.Begin(); acceptingIndustryList.HasNext(); i = acceptingIndustryList.Next())
	{
		AILog.Info("In the loop");
		local length = AIIndustry.GetDistanceManhattanToTile(i, startTile);
		if(length > 20 && length < 100)
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
		local startStation = Trucks.BuildTruckStation(startTile, cargoInUse, true);
		local endStation = Trucks.BuildTruckStation(AIIndustry.GetLocation(industry), cargoInUse, false);
		Paths.FindPath(startStation, endStation);
		local depot = BuildRoadDepot(startStation.location);
		Vehicles.AddVehiclesToRoute(cargoInUse, depot, startStation, endStation);
	}
}

function Trucks::BuildTruckStation(industryUsing, cargo, start)
{
	local townTileList = AITileList();
	townTileList.AddRectangle(industryUsing - AIMap.GetTileIndex(-4, -4), industryUsing - AIMap.GetTileIndex(4, 4));
	local stationRadius = AIStation.GetCoverageRadius(AIStation.STATION_TRUCK_STOP);
	

	townTileList.Valuate(AIRoad.IsRoadTile);
	townTileList.KeepValue(0);
	townTileList.Valuate(AITile.IsBuildable);
	townTileList.KeepValue(1);
	townTileList.Valuate(function (tile) {
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
	townTileList.KeepValue(0);
	
	if(start)
	{
		townTileList.Valuate(AITile.GetCargoProduction, cargo, 1, 1, stationRadius);
		townTileList.KeepAboveValue(0);
	}
	else
	{
		townTileList.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, stationRadius);
		townTileList.KeepAboveValue(7);
	}
	townTileList.KeepTop(1);
	//townTileList.Valuate(AITown.GetLocation);
	local randTile = Tile();
	
	randTile.SetAttribs(townTileList.Begin());
	local adjacentTiles = GetAdjacentTiles(randTile.location, false);
	local isStationBuilt = false;
	local thisStation = Tile();
	for(local i = adjacentTiles.Begin(); adjacentTiles.HasNext(); i = adjacentTiles.Next()) {
		if(AITile.IsBuildable(i) && !isStationBuilt) {
			AITile.DemolishTile(townTileList.Begin());
			AIRoad.BuildRoad(townTileList.Begin(), i);
			AITile.DemolishTile(townTileList.Begin());
			while(!AIRoad.BuildRoadStation(townTileList.Begin(), i, true, false, false)) {
				Sleep(100);
				switch (AIError.GetLastError()) {
				case AIError.ERR_AREA_NOT_CLEAR:
					AITile.DemolishTile(townTileList.Begin());
					break;
				default:
				}
			}
			thisStation.SetAttribs(townTileList.Begin());
			isStationBuilt = true
		}
	}
	AILog.Warning(AIError.GetLastErrorString());
	AILog.Info("This Station Location: " + thisStation.location);
	return thisStation;
}
