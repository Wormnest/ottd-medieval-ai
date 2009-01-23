class Vehicles
{
	constructor();
	
	function AddVehiclesToRoute(cargo, depot, firstStation, secondStation);
	function CheckForNegativeIncome();
	function SellInDepot();
	function CheckForVehiclesNeeded();
	function CheckOldVehicles();
}

function Vehicles::AddVehiclesToRoute(cargo, depot, fakeFirstStation, fakeSecondStation)
{
	local firstStation = Tile();
		firstStation.SetAttribs(AIRoad.GetRoadStationFrontTile(fakeFirstStation.location));
	local secondStation = Tile();
		secondStation.SetAttribs(AIRoad.GetRoadStationFrontTile(fakeSecondStation.location));	

	local vehcileList = AIEngineList(AIVehicle.VT_ROAD)
	
	vehcileList.Valuate(AIEngine.GetCargoType)
	vehcileList.KeepValue(cargo)
	vehcileList.Valuate(AIEngine.GetCapacity)
	vehcileList.KeepTop(1)
	local adjTiles = GetAdjacentTiles(firstStation.location, false)
	adjTiles.Valuate(AITile.IsStationTile)
	adjTiles.KeepValue(1)
	local firstStation = adjTiles.Begin()
	adjTiles = GetAdjacentTiles(secondStation.location, false)
	adjTiles.Valuate(AITile.IsStationTile)
	adjTiles.KeepValue(1)
	local secondStation = adjTiles.Begin();
	
	local numVehicles = AITile.GetDistanceManhattanToTile(firstStation, secondStation)/10;
	if(numVehicles < 2) { 
		numVehicles += 2
	}
	
	if(AICargo.IsFreight(cargo))
	{
		for(local i = 0; i < numVehicles * 2; i++)
		{
			AILog.Info("i: " + i + ", numVehicles: " + numVehicles);
			local currVehicle = AIVehicle.BuildVehicle(depot, vehcileList.Begin());
			AIOrder.AppendOrder(currVehicle, firstStation, AIOrder.AIOF_FULL_LOAD_ANY);
			AIOrder.AppendOrder(currVehicle, secondStation, AIOrder.AIOF_NONE);
			AIVehicle.StartStopVehicle(currVehicle);
		}
		return;
	}
	
	for(local i = 0; i < numVehicles/2; i++) 
	{
		local currVehicle = AIVehicle.BuildVehicle(depot, vehcileList.Begin());
		AIOrder.AppendOrder(currVehicle, firstStation, AIOrder.AIOF_NONE);
		AIOrder.AppendOrder(currVehicle, secondStation, AIOrder.AIOF_NONE);
		AIVehicle.StartStopVehicle(currVehicle);
		
		currVehicle = AIVehicle.BuildVehicle(depot, vehcileList.Begin());
		AIOrder.AppendOrder(currVehicle, secondStation, AIOrder.AIOF_NONE);
		AIOrder.AppendOrder(currVehicle, firstStation, AIOrder.AIOF_NONE);
		AIVehicle.StartStopVehicle(currVehicle);
	}
}

function Vehicles::CheckForNegativeIncome()
{
	local negativeVehicles = AIVehicleList();
	negativeVehicles.Valuate(AIVehicle.GetProfitLastYear);
	negativeVehicles.KeepBelowValue(-200);
	negativeVehicles.Valuate(AIVehicle.GetAge);
	negativeVehicles.KeepAboveValue(200);
	for(local i = negativeVehicles.Begin(); negativeVehicles.HasNext(); i = negativeVehicles.Next()) 
	{
		local stations = AIStationList_Vehicle(i);
		local vehicles = AIVehicleList_Station(stations.Begin());
		if(vehicles.Count() > 1)
			AIVehicle.SendVehicleToDepot(i);
	}
}

function Vehicles::CheckOldVehicles()
{
	local oldVehicles = AIVehicleList();
	oldVehicles.Valuate(AIVehicle.GetAgeLeft);
	oldVehicles.KeepBelowValue(356);
	for(local i = oldVehicles.Begin(); oldVehicles.HasNext(); i = oldVehicles.Next())
	{
		AIVehicle.SendVehicleToDepot(i);
	}
}

function Vehicles::SellInDepot()
{
	local vehiclesInDepot = AIVehicleList();
	vehiclesInDepot.Valuate(AIVehicle.IsStoppedInDepot);
	vehiclesInDepot.KeepValue(1);
	for(local i = vehiclesInDepot.Begin(); vehiclesInDepot.HasNext(); i = vehiclesInDepot.Next()) {
		AIVehicle.SellVehicle(i);
	}
}

function Vehicles::CheckForVehiclesNeeded()
{
	AILog.Info("Checking if there are extra road vehicles needed");
	
	local cargoList = AICargoList();
	
	
	local vehicleList = AIList();
	local stationList = AIList();
	
	for(local i = cargoList.Begin(); cargoList.HasNext(); i = cargoList.Next())
	{
		vehicleList = AIEngineList(AIVehicle.VT_ROAD);
	
		vehicleList.Valuate(AIEngine.GetCargoType);
		vehicleList.KeepValue(i);
		vehicleList.Valuate(AIEngine.GetCapacity);
		vehicleList.KeepTop(1);
		
		if(AICargo.HasCargoClass(i, AICargo.CC_PASSENGERS))
		{
			stationList = AIStationList(AIStation.STATION_BUS_STOP);
		}
		
		else
		{
			stationList = AIStationList(AIStation.STATION_TRUCK_STOP);
		}
		
		stationList.Valuate(AIStation.GetCargoWaiting, i);
		stationList.KeepAboveValue(130);
		AILog.Info(AICargo.GetCargoLabel(i) + " Station Count: " + stationList.Count());
		for(local j = stationList.Begin(); stationList.HasNext(); j = stationList.Next())
		{
			local depotLocation = Buses.FindDepot(AIStation.GetLocation(j))
			if(depotLocation == false) 
			{
				AILog.Info("Building a depot");
				depotLocation = BuildRoadDepot(AIStation.GetLocation(j));
			}
			local stationVehicles = AIVehicleList_Station(j);
			local vehicleStations = AIStationList_Vehicle(stationVehicles.Begin());
			local iter = vehicleStations.Begin();
			local stationOne = iter;
			iter = vehicleStations.Next();
			local stationTwo = iter;
			stationOne = AIStation.GetLocation(stationOne);
			stationTwo = AIStation.GetLocation(stationTwo);
			local stationDistance = AITile.GetDistanceManhattanToTile(stationOne, stationTwo);	
			if(stationDistance / stationVehicles.Count() < 2)
			{
				AILog.Info("Building Extra Station");
				local adjTiles = GetAdjacentTiles(AIStation.GetLocation(i), false);
				adjTiles.Valuate(GetAdjacentTiles, true);
				adjTiles.KeepValue(0);
				adjTiles.Valuate(AIRoad.IsRoadTile);
				adjTiles.KeepValue(0);
				adjTiles.Valuate(AIRoad.GetNeighbourRoadCount);
				adjTiles.KeepAboveValue(0);
				local lowestCost = -1;
				local keepTile = AITileList();
				for(local demolishTest = adjTiles.Begin(); adjTiles.HasNext(); demolishTest = adjTiles.Next())
				{
					local testMode = AITestMode();
					local costs = AIAccounting();
					AITile.DemolishTile(demolishTest);
					if(costs.GetCosts() < lowestCost || lowestCost == -1)
					{
						lowestCost = costs.GetCosts();
						keepTile.KeepValue(demolishTest);
					}
				}
				adjTiles.Clear()
				adjTiles.AddList(keepTile);
				// adjTiles.Valuate(function (tile)
				// {
					// local testMode = AITestMode();
					// local costs = AIAccounting();
					// AITile.DemolishTile(tile);
					// return costs.GetCosts();
				// })
				//adjTiles.KeepBottom(1);
				local adjToNew = GetAdjacentTiles(adjTiles.Begin(), false);
				local isStationBuilt = false;
				for(local k = adjToNew.Begin(); adjToNew.HasNext(); k = adjToNew.Next()) 
				{
					if(AIRoad.IsRoadTile(k) && !isStationBuilt) 
					{
						AITile.DemolishTile(adjTiles.Begin());
						AIRoad.BuildRoad(adjTiles.Begin(), k);
						AITile.DemolishTile(adjTiles.Begin());
						while(!AIRoad.BuildRoadStation(adjTiles.Begin(), k, false, false, true)) 
						{
							Sleep(100);
							switch (AIError.GetLastError()) 
							{
								case AIError.ERR_AREA_NOT_CLEAR:
								AITile.DemolishTile(adjTiles.Begin());
								break;
								default:
							}
						}
						thisStation.SetAttribs(adjTiles.Begin());
						isStationBuilt = true
					}
				}
			}
			else
			{
				local vehiclesNeeded = AIStation.GetCargoWaiting(j, i) / 130;
				local vehiclesCanAfford = 0;
		
				local vehiclePrice = AIEngine.GetPrice(vehicleList.Begin());
				AILog.Info(AIEngine.GetName(vehicleList.Begin()) + "");
				//AILog.Info(AIError.GetLastErrorString());
				AILog.Info("Vehicles needed: " + vehiclesNeeded + ", Total cost: $" + vehiclePrice * vehiclesNeeded);
				AILog.Info("Can build max. of " + GetBalance() / vehiclePrice + " vehicles");
				vehiclesCanAfford = GetBalance() / vehiclePrice;
				AILog.Info("Balance: $" + GetBalance());

				if(vehiclesCanAfford < vehiclesNeeded)
						Loan();
					
				AILog.Info("Balance: $" + GetBalance());
				
				for(local l = 0; l < vehiclesNeeded; l++)
				{
					local newVehicle = AIVehicle.BuildVehicle(depotLocation, vehicleList.Begin());
					//AILog.Info(AIError.GetLastErrorString());
					AIOrder.ShareOrders(newVehicle, stationVehicles.Begin());
					AIVehicle.StartStopVehicle(newVehicle);	
				}
			}
		}
	}
}