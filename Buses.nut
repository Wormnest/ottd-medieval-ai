class Buses
{
	constructor()	
	function FindPassTown(above, near, occupied);
	function BuildPassStation(rectStart, rectEnd, townUsing, passengers);
	function FindDepot(town);
	function IsTownOccupied(townList);
	function BuildBusRoute();
}

function Buses::BuildBusRoute()
{
	AILog.Info("Planning Bus Route");
	
	//FIND PASSENGER CARGO
	local cargoList = AICargoList();
	cargoList.Valuate(AICargo.HasCargoClass, AICargo.CC_PASSENGERS);
	cargoList.KeepValue(1);
	local cargos = cargoList.Begin();
	
	//INITALIZE VARIABLES
	local depot = null;
	local townUsing = false;
	local otherTown = false;
	local routeBuilt = false;
	local searchRadius = 8
	local counter = 0;
	local retries = 5;
	
	//FIND TOWNS TO USE
	while(counter < retries) 
	{ 
		if(!townUsing)
		{
			townUsing = Buses.FindPassTown(200, null, false);
		}
		else
		{
			otherTown = Buses.FindPassTown(200, townUsing, false);
			if(otherTown != false)
			{
				break;
			}
		}
		counter++;
		if(counter == retries)
		{
				return false;
		}
	}

	//BUILD BUS STOPS IN EACH TOWN
	local firstStop = Buses.BuildPassStation(-searchRadius, searchRadius, townUsing, cargos);
	if(!firstStop)
		return false;
	AILog.Info("Built first stop: " + AIStation.GetName(AIStation.GetStationID(firstStop.location)));
	local secondStop = Buses.BuildPassStation(-searchRadius, searchRadius, otherTown, cargos);
	if(!secondStop)
		return false;
	AILog.Info("Built second stop: " + AIStation.GetName(AIStation.GetStationID(secondStop.location)));
	
	//FIND PATH BETWEEN STATIONS
	if(Paths.FindPath(firstStop, secondStop, false)) 
	{ 
		//FIND/BUILD DEPOT
		depot = Buses.FindDepot(secondStop.location);
		if(!depot)
		{
			depot = BuildRoadDepot(secondStop.location);
		}
		//ADD VEHICLES TO ROUTE
		Vehicles.AddVehiclesToRoute(cargos, depot, firstStop, secondStop);
		AILog.Info("Route completed");
	}
	else
	{
		AILog.Info("Couldn't find path. Cleaning up and aborting.");
		AITile.DemolishTile(firstStop.location);
		AITile.DemolishTile(secondStop.location);
	}
}

function Buses::IsTownOccupied(townList)
{
	local townTileList = AITileList();
	
	townList.Valuate(AITown.GetLocation)
	for(local i = townList.Begin(); townList.HasNext(); i = townList.Next()) 
	{
		townTileList.AddRectangle(AITown.GetLocation(i) - AIMap.GetTileIndex(8, 8), AITown.GetLocation(i) + AIMap.GetTileIndex(8, 8));
		townTileList.Valuate(AITile.IsStationTile);
		townTileList.KeepValue(1);
		townTileList.Valuate(AITile.GetOwner);
		townTileList.KeepValue(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF));
		if(townTileList.Count() > (AITown.GetPopulation(i) / 350)) 
		{
			AILog.Warning("Occupied: " + AITown.GetName(i))
			townList.RemoveValue(AITown.GetLocation(i));
		}
		townTileList.Clear();					
	}
	return townList;
}

function Buses::FindDepot(townLocation)
{
	local townTileList = AITileList();
	townTileList.AddRectangle(townLocation - AIMap.GetTileIndex(5, 5), townLocation + AIMap.GetTileIndex(5, 5));
	townTileList.Valuate(AIRoad.IsRoadDepotTile);
	townTileList.KeepValue(1);
	townTileList.Valuate(AITile.GetOwner);
	townTileList.KeepValue(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF));
	if(!townTileList.IsEmpty())
	{
		return townTileList.Begin();
	}
	else
	{
		return false;
	}
}

function Buses::FindPassTown(above, near, occupied)
{
	local townList = AITownList();
	
	if(!occupied)
	{
		townList = Buses.IsTownOccupied(townList);
	}
	
	if(above != null && near != null) 
	{
		townList.Valuate(AITown.GetPopulation);
		townList.KeepAboveValue(above);
		// townList.Valuate(AIBase.RandItem);	
		townList.KeepTop(10);
		townList.Valuate(AITown.GetLocation)
		townList.RemoveValue(near.location);
		townList.Valuate(AITown.GetDistanceManhattanToTile, near.location)
		townList.KeepBottom(1)
	}
	
	else if(above != null) 
	{
		townList.Valuate(AITown.GetPopulation);
		townList.KeepAboveValue(above);
		townList.Valuate(AIBase.RandItem);	
		townList.KeepTop(1);
	}
	
	else if(near != null) 
	{
		townList.Valuate(AITown.GetLocation)
		townList.RemoveValue(near.location)
		townList.Valuate(AITown.GetDistanceManhattanToTile, near.location)
		townList.KeepBottom(1)
	}
	
	if(townList.IsEmpty()) 
	{
		AILog.Warning("No suitable towns found.");
		return false;
	}

	else 
	{
		local townFound = Tile()
		townFound.SetAttribs(AITown.GetLocation(townList.Begin()));
		AILog.Info("Building in: " + AITown.GetName(townList.Begin()) + " (" + townList.Begin() + ")")
		return townFound;
	}
}

function Buses::BuildPassStation(rectStart, rectEnd, townUsing, passengers)
{
	local townList = AITownList();
	local townTileList = AITileList();
	townTileList.AddRectangle(townUsing.location - AIMap.GetTileIndex(rectStart, rectStart), townUsing.location - AIMap.GetTileIndex(rectEnd, rectEnd));
	local stationRadius = AIStation.GetCoverageRadius(AIStation.STATION_BUS_STOP);
	
	for(local i = townTileList.Begin(); townTileList.HasNext(); i = townTileList.Next()) 
	{
		if(AITile.IsStationTile(i)) 
		{
			townTileList.RemoveRectangle(i - AIMap.GetTileIndex(stationRadius, stationRadius), i + AIMap.GetTileIndex(stationRadius, stationRadius));	
		}
	}
	townTileList.Valuate(AIRoad.IsRoadTile);
	townTileList.KeepValue(0);
	//townTileList.Valuate(AITile.IsBuildable);
	//townTileList.KeepValue(1);
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
	//AILog.Info("Count: " + townTileList.Count());
	townTileList.KeepValue(0);
	//AILog.Info("Count: " + townTileList.Count());	
	townTileList.Valuate(AIRoad.GetNeighbourRoadCount);
	townTileList.KeepAboveValue(0);
	//AILog.Info("Count: " + townTileList.Count());	
	townTileList.Valuate(GetAdjacentTiles, true);
	//AILog.Info("Count: " + townTileList.Count());
	townTileList.KeepValue(0);
	//AILog.Info("Count: " + townTileList.Count());
	townTileList.Valuate(AITile.GetCargoProduction, passengers, 1, 1, stationRadius);
	townTileList.KeepAboveValue(4);
	townTileList.Valuate(AITile.GetCargoAcceptance, passengers, 1, 1, stationRadius);
	townTileList.KeepAboveValue(7);
	townTileList.KeepTop(1);
	local flat = false;
	local randTile = Tile();
	randTile.SetAttribs(townTileList.Begin());
	local adjacentTiles = AITileList();
	while(!flat)
	{	
		adjacentTiles = GetAdjacentTiles(randTile.location, false);
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
		if(!adjacentTiles.IsEmpty())
		{
			flat = true;
		}
		randTile.SetAttribs(townTileList.Next());
	}
	local isStationBuilt = false;
	local thisStation = Tile();
	//AILog.Info("5");
	for(local i = adjacentTiles.Begin(); adjacentTiles.HasNext(); i = adjacentTiles.Next()) {
		if(AIRoad.IsRoadTile(i) && !isStationBuilt) {
			AITile.DemolishTile(townTileList.Begin());
			AIRoad.BuildRoad(townTileList.Begin(), i);
			AITile.DemolishTile(townTileList.Begin());
		//	AILog.Info("5a");
			while(!AIRoad.BuildRoadStation(townTileList.Begin(), i, false, false, false)) 
			{		
				Sleep(100);
				//AILog.Info("5b");
				//AILog.Error(AIError.GetLastErrorString());
				switch (AIError.GetLastError()) {
				case AIError.ERR_AREA_NOT_CLEAR:
					if(!AITile.DemolishTile(townTileList.Begin()))
					{
						AILog.Info("Abandoning Route");
						return false;
					}
					AILog.Warning(AIError.GetLastErrorString());
					break;
				case AIError.ERR_OWNED_BY_ANOTHER_COMPANY:
					AILog.Info("Somebody beat me to it!");
					return false;
				default:
					AILog.Info("Abandoning Route");
					return false;
				}
			}
			if(townTileList.IsEmpty())
				return false;
				
			thisStation.SetAttribs(townTileList.Begin());
			isStationBuilt = true
		}
	}
	AILog.Info("6");
	AILog.Warning(AIError.GetLastErrorString());
	return thisStation;
}

