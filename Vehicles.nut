class Vehicles
{
	constructor();
	
	function AddVehiclesToRoute(cargo, depot, firstStation, secondStation);
	function CheckForNegativeIncome();
	function SellInDepot();
	function CheckForVehiclesNeeded(cargos);
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
		for(local i = 0; i < numVehicles*3; i++)
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

function Vehicles::CheckForVehiclesNeeded(cargo)
{
	AILog.Info("Checking Vehicles: " + AICargo.GetCargoLabel(cargo));
	local vehicleList = AIEngineList(AIVehicle.VT_ROAD);
	
	vehicleList.Valuate(AIEngine.GetCargoType);
	vehicleList.KeepValue(cargo);
	vehicleList.Valuate(AIEngine.GetCapacity);
	vehicleList.KeepTop(1);
	AILog.Info("Vehicle Count: " + vehicleList.Count());
	
	local stationList = AIStationList(AIStation.STATION_TRUCK_STOP);
	stationList.Valuate(AIStation.GetCargoWaiting, cargo);
	stationList.KeepAboveValue(130);
	AILog.Info("Station Count: " + stationList.Count());
	for(local i = stationList.Begin(); stationList.HasNext(); i = stationList.Next())
	{
		local depotLocation = Buses.FindDepot(AIStation.GetLocation(i))
		if(depotLocation == false) 
		{
			AILog.Info("Building a depot");
			depotLocation = BuildRoadDepot(AIStation.GetLocation(i));
		}
		local stationVehicles = AIVehicleList_Station(i);
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
			return;
		}
		else
		{
			local vehiclesNeeded = AIStation.GetCargoWaiting(i, cargo) / 130;	
			AILog.Info(vehiclesNeeded + "");
			for(local i = 0; i < vehiclesNeeded; i++)
					{
						local newVehicle = AIVehicle.BuildVehicle(depotLocation, vehicleList.Begin());
						AILog.Info(AIError.GetLastErrorString());
						AIOrder.ShareOrders(newVehicle, stationVehicles.Begin());
						AIVehicle.StartStopVehicle(newVehicle);	
					}
		}
	}
}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	// local passStations = AIStationList(AIStation.STATION_BUS_STOP);

	// if(!passStations.IsEmpty()) 
	// {
		// for(local i = passStations.Begin(); passStations.HasNext(); i = passStations.Next()) 
		// {
			// if(AIStation.GetCargoWaiting(i, cargos.passengers) >= 150 || AIStation.GetCargoRating(i, cargos.passengers) < 50) 
			// { 
				// local balance = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
				// local loan = AICompany.GetLoanAmount();
				// local maxLoan = AICompany.GetMaxLoanAmount();
				// AILog.Info("Station needs updating: " + AIStation.GetName(i)); 
				// local depotLocation = Bus.FindDepot(AIStation.GetLocation(i))
				// if(depotLocation == false) 
				// {
					// AILog.Info("Building a depot");
					// depotLocation = BuildRoadDepot(AIStation.GetLocation(i));
				// }
					
				// local stationVehicles = AIVehicleList_Station(i);
				// local vehicleStations = AIStationList_Vehicle(stationVehicles.Begin());
				
				// local iter = vehicleStations.Begin();
				// local distStationOne = iter;
				// iter = vehicleStations.Next();
				// local distStationTwo = iter;
				// distStationOne = AIStation.GetLocation(distStationOne);
				// distStationTwo = AIStation.GetLocation(distStationTwo);
				// local stationDistance = AITile.GetDistanceManhattanToTile(distStationOne, distStationTwo);		
				
				// if(balance < 5000) 
				// {
					// if(loan == maxLoan) 
					// {
						// return false;
					// }
					// if(loan + 10000 <= maxLoan) 
					// {	
						// AICompany.SetLoanAmount(loan + 10000)
					// }
					// else 
					// {
						// return false;
					// }
				// }
				
				// if(stationDistance / stationVehicles.Count() >= 2)
				// {
					// local numBuses = AIStation.GetCargoWaiting(i, cargos.passengers) / 150;
					// if(AIStation.GetCargoRating(i, cargos.passengers) < 50)
					// {
						// numBuses++;
					// }
					// AILog.Info("Attempting to add " + numBuses + " buses to a route");
					// local newVehicle = null;
					
					// for(local i = 0; i < numBuses; i++)
					// {
						// newVehicle = AIVehicle.BuildVehicle(depotLocation, vehcileList.Begin());
						// AILog.Info(AIError.GetLastErrorString());
						// AIOrder.ShareOrders(newVehicle, stationVehicles.Begin());
						// AIVehicle.StartStopVehicle(newVehicle);	
					// }
				// }
				// else
				// {
					// AILog.Error("Building Extra Station");
					// local adjTiles = GetAdjacentTiles(AIStation.GetLocation(i), false);
					// adjTiles.Valuate(GetAdjacentTiles, true);
					// adjTiles.KeepValue(0);
					// adjTiles.Valuate(AIRoad.IsRoadTile);
					// adjTiles.KeepValue(0);
					// adjTiles.Valuate(AIRoad.GetNeighbourRoadCount);
					// adjTiles.KeepAboveValue(0);
					// adjTiles.Valuate(function (tile)
					// {
						// local testMode = AITestMode();
						// local costs = AIAccounting();
						// AITile.DemolishTile(node.tile.location, node.parentNode.tile.location);
						// return costs.GetCosts();
					// })
					// adjTiles.KeepBottom(1);
					// local adjToNew = GetAdjacentTiles(adjTiles.Begin(), false);
					// local isStationBuilt = false;
					// for(local i = adjToNew.Begin(); adjToNew.HasNext(); i = adjToNew.Next()) 
					// {
						// if(AIRoad.IsRoadTile(i) && !isStationBuilt) {
							// AITile.DemolishTile(adjTiles.Begin());
							// AIRoad.BuildRoad(adjTiles.Begin(), i);
							// AITile.DemolishTile(adjTiles.Begin());
							// while(!AIRoad.BuildRoadStation(adjTiles.Begin(), i, false, false, true)) {
								// Sleep(100);
								// switch (AIError.GetLastError()) {
								// case AIError.ERR_AREA_NOT_CLEAR:
									// AITile.DemolishTile(adjTiles.Begin());
									// break;
								// default:
								// }
							// }
							//thisStation.SetAttribs(adjTiles.Begin());
							// isStationBuilt = true
						// }
					// }
				// }
			// }
		// }
	// }
// }
