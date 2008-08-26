class Towns
{
	constructor()	
	function FindPassTown(above, near, occupied);
	function BuildPassStation(rectStart, rectEnd, townUsing, cargos);
	function BuildDepot(startTile);
}

function Towns::FindPassTown(above, near, occupied)
{
	local townList = AITownList();
	local townTileList = AITileList();
	
	if(above != null && near != null) {
		townList.Valuate(AITown.GetPopulation);
		townList.KeepAboveValue(above);
		townList.Valuate(AIBase.RandItem);	
		townList.KeepTop(10);
		townList.Valuate(AITown.GetLocation)
		townList.RemoveValue(near.location);
		for(local i = townList.Begin(); townList.HasNext(); i = townList.Next()) {
			townTileList.AddRectangle(AITown.GetLocation(i) - AIMap.GetTileIndex(5, 5), AITown.GetLocation(i) + AIMap.GetTileIndex(5, 5));
			townTileList.Valuate(AITile.IsStationTile);
			townTileList.KeepValue(1);
			if(townTileList.Count() > (AITown.GetPopulation(i) / 400)) {
				//AILog.Info("Occupied: " + AITown.GetName(i))
		 		townList.RemoveValue(AITown.GetLocation(i));
			}
			townTileList = AITileList();			
		}
		townList.Valuate(AITown.GetDistanceManhattanToTile, near.location)
		townList.KeepBottom(1)
	}
	else if(above != null) {
		townList.Valuate(AITown.GetPopulation);
		townList.KeepAboveValue(above);
		townList.Valuate(AIBase.RandItem);	
		townList.KeepTop(10);
		townList.Valuate(AITown.GetLocation)
		for(local i = townList.Begin(); townList.HasNext(); i = townList.Next()) {
			townTileList.AddRectangle(AITown.GetLocation(i) - AIMap.GetTileIndex(5, 5), AITown.GetLocation(i) + AIMap.GetTileIndex(5, 5));
			townTileList.Valuate(AITile.IsStationTile);
			townTileList.KeepValue(1);
			if(townTileList.Count() > (AITown.GetPopulation(i) / 400)) {
				//AILog.Info("Occupied: " + AITown.GetName(i))
		 		townList.RemoveValue(AITown.GetLocation(i));
			}
			townTileList = AITileList();					
		}
	}
	else if(near != null) {
		townList.Valuate(AITown.GetLocation)
		townList.RemoveValue(near.location)
		for(local i = townList.Begin(); townList.HasNext(); i = townList.Next()) {
			townTileList.AddRectangle(AITown.GetLocation(i) - AIMap.GetTileIndex(5, 5), AITown.GetLocation(i) + AIMap.GetTileIndex(5, 5));
			townTileList.Valuate(AITile.IsStationTile);
			townTileList.KeepValue(1);
			if(townTileList.Count() > (AITown.GetPopulation(i) / 400)) {
				//AILog.Info("Occupied: " + AITown.GetName(i))
		 		townList.RemoveValue(AITown.GetLocation(i));
			}
			townTileList = AITileList();			
		}
		townList.Valuate(AITown.GetDistanceManhattanToTile, near.location)
		townList.KeepBottom(1)
	}
	
	if(townList.IsEmpty()) {
		//AILog.Warning("No suitable towns found.");
		return false;
	}

	else {
		local townFound = Tile()
		townFound.location = AITown.GetLocation(townList.Begin())
		AILog.Info("Building in: " + AITown.GetName(townList.Begin()) + " (" + townList.Begin() + ")")
		return townFound;
	}
}

function Towns::BuildPassStation(rectStart, rectEnd, townUsing, cargos)
{
	local stationRadius = AIStation.GetCoverageRadius(AIStation.STATION_BUS_STOP);
	local stationOffset = AIMap.GetTileIndex(stationRadius, stationRadius)
	local townList = AITownList();
	local townTileList = AITileList();
	townTileList.AddRectangle(townUsing.location - AIMap.GetTileIndex(rectStart, rectStart), townUsing.location - AIMap.GetTileIndex(rectEnd, rectEnd));
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
	townTileList.Valuate(AIRoad.GetNeighbourRoadCount);
	townTileList.KeepAboveValue(0);
	townTileList.Valuate(AITile.IsStationTile);
	for(local i = townTileList.Begin(); townTileList.HasNext(); i = townTileList.Next()) {
		if(i == 1) {
			townTileList.RemoveRectangle(i - stationOffset, i + stationOffset);
		}
	}
	townTileList.Valuate(AITile.GetCargoAcceptance, cargos.passengers, 1, 1, stationRadius);
	townTileList.KeepTop(1);
	local randTile = Tile();
	townTileList.Valuate(AIBase.RandItem);
	randTile.location = townTileList.Begin();
	local adjacentTiles = GetAdjacentTiles(randTile.location);
	local isStationBuilt = false;
	local thisStation = Tile();
	for(local i = adjacentTiles.Begin(); adjacentTiles.HasNext(); i = adjacentTiles.Next()) {
		if(AIRoad.IsRoadTile(i) && !isStationBuilt) {
			AIRoad.BuildRoad(townTileList.Begin(), i);
			AITile.DemolishTile(townTileList.Begin());
			while(!AIRoad.BuildRoadStation(townTileList.Begin(), i, false, false, false)) {
				AILog.Warning(AIError.GetLastErrorString());
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
	return thisStation;
}

function Towns::BuildDepot(depotLocation)
{
	local townTileList = AITileList();
	for(local i = 1;; i ++) {
		townTileList.AddRectangle(depotLocation - AIMap.GetTileIndex(i, i), depotLocation + AIMap.GetTileIndex(i, i));
		townTileList.Valuate(AITile.IsBuildable)
		townTileList.KeepValue(1)
		townTileList.Valuate(AIRoad.GetNeighbourRoadCount)
		townTileList.KeepAboveValue(0)
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
		if(!townTileList.IsEmpty()) {
			depotLocation = townTileList.Begin()
			AILog.Info("Found Depot Location: " + townTileList.Begin())
			break;
		}
	}
	
	local adjacentTiles = GetAdjacentTiles(depotLocation)
	local isDepotBuilt = false
	for(local i = adjacentTiles.Begin(); adjacentTiles.HasNext(); i = adjacentTiles.Next()) {
		if(AIRoad.IsRoadTile(i) && !isDepotBuilt) {
			AILog.Info("Building a depot")
			AIRoad.BuildRoad(townTileList.Begin(), i);
			AITile.DemolishTile(townTileList.Begin());
			if(!AIRoad.BuildRoadDepot(townTileList.Begin(), i)) {
				AILog.Info(AIError.GetLastErrorString())
			}
			isDepotBuilt = true
		}
	}
	return townTileList.Begin()
}
