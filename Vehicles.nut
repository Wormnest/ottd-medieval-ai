class Vehicles
{
	constructor();
	
	function AddVehiclesToRoute(depot, firstStation, secondStation);
	function CheckForNegativeIncome();
	function SellInDepot();
	function CheckForVehiclesNeeded(cargos);
}

function Vehicles::AddVehiclesToRoute(passCargo, depot, fakeFirstStation, fakeSecondStation)
{
	local firstStation = Tile();
		firstStation.SetAttribs(AIRoad.GetRoadStationFrontTile(fakeFirstStation.location));
	local secondStation = Tile();
		secondStation.SetAttribs(AIRoad.GetRoadStationFrontTile(fakeSecondStation.location));	

	local busList = AIEngineList(AIVehicle.VEHICLE_ROAD)
	
	busList.Valuate(AIEngine.GetCargoType)
	busList.KeepValue(passCargo.passengers)
	busList.Valuate(AIEngine.GetPrice)
	busList.KeepBottom(1)
	local adjTiles = GetAdjacentTiles(firstStation.location)
	adjTiles.Valuate(AITile.IsStationTile)
	adjTiles.KeepValue(1)
	local firstStation = adjTiles.Begin()
	adjTiles = GetAdjacentTiles(secondStation.location)
	adjTiles.Valuate(AITile.IsStationTile)
	adjTiles.KeepValue(1)
	local secondStation = adjTiles.Begin();
	
	local numBuses = AITile.GetDistanceManhattanToTile(firstStation, secondStation)/10
	if(numBuses < 2) { 
		numBuses += 2
	}
	
	for(local i = 0; i < numBuses/2; i++) {
		local currVehicle = AIVehicle.BuildVehicle(depot, busList.Begin())
		AIOrder.AppendOrder(currVehicle, firstStation, AIOrder.AIOF_NONE)
		AIOrder.AppendOrder(currVehicle, secondStation, AIOrder.AIOF_NONE)
		AIVehicle.StartStopVehicle(currVehicle)
		
		currVehicle = AIVehicle.BuildVehicle(depot, busList.Begin())
		AIOrder.AppendOrder(currVehicle, secondStation, AIOrder.AIOF_NONE)
		AIOrder.AppendOrder(currVehicle, firstStation, AIOrder.AIOF_NONE)
		AIVehicle.StartStopVehicle(currVehicle)
	}
}

function Vehicles::CheckForNegativeIncome()
{
	AILog.Info("Checking for unprofitable vehicles...");
	local negativeVehicles = AIVehicleList();
	negativeVehicles.Valuate(AIVehicle.GetProfitLastYear);
	negativeVehicles.KeepBelowValue(0);
	for(local i = negativeVehicles.Begin(); negativeVehicles.HasNext(); i = negativeVehicles.Next()) {
		AIVehicle.SendVehicleToDepot(i);
	}
}

function Vehicles::SellInDepot()
{
	AILog.Info("Selling vehicles...");
	local vehiclesInDepot = AIVehicleList();
	vehiclesInDepot.Valuate(AIVehicle.IsStoppedInDepot);
	vehiclesInDepot.KeepValue(1);
	for(local i = vehiclesInDepot.Begin(); vehiclesInDepot.HasNext(); i = vehiclesInDepot.Next()) {
		AIVehicle.SellVehicle(i);
	}
}

function Vehicles::CheckForVehiclesNeeded(cargos)
{
	local busList = AIEngineList(AIVehicle.VEHICLE_ROAD)
	
	busList.Valuate(AIEngine.GetCargoType)
	busList.KeepValue(cargos.passengers)
	busList.Valuate(AIEngine.GetPrice)
	busList.KeepBottom(1)
	local passStations = AIStationList(AIStation.STATION_BUS_STOP);
	//AILog.Info("Pass Count: " + passStations.Count());

	if(!passStations.IsEmpty()) {
		for(local i = passStations.Begin(); passStations.HasNext(); i = passStations.Next()) {
			if(AIStation.GetCargoWaiting(i, cargos.passengers) >= 100 || AIStation.GetCargoRating(i, cargos.passengers) < 60) { 
				local balance = AICompany.GetBankBalance(AICompany.MY_COMPANY);
				local loan = AICompany.GetLoanAmount();
				local maxLoan = AICompany.GetMaxLoanAmount();
				AILog.Info("Station needs updating: " + AIStation.GetName(i)); 
				local depotList = AITileList()
				depotList.AddRectangle(AIStation.GetLocation(i) - AIMap.GetTileIndex(5, 5), AIStation.GetLocation(i) + AIMap.GetTileIndex(5, 5));
				//AILog.Info("Count : " + depotList.Count());
				//AISign.BuildSign(AIStation.GetLocation(i), "Count: " + depotList.Count());
				depotList.Valuate(AIRoad.IsRoadDepotTile);
				//AILog.Info("depotList: " + depotList.Begin());
				depotList.KeepValue(1);
				if(depotList.IsEmpty()) {
					AILog.Info("Building a depot");
					local depotLocation = Towns.BuildDepot(AIStation.GetLocation(i));
					AILog.Info(AIError.GetLastErrorString());
					Sleep(10);
					if(AIRoad.IsRoadDepotTile(depotLocation)) {AILog.Info("There IS a depot!")}
					local vehiclesAtStation = AIVehicleList_Station(i);
					if(balance < 5000) {
						if(loan == maxLoan) {
							return false;
						}
						if(loan + 10000 <= maxLoan) {
							AICompany.SetLoanAmount(loan + 10000)
						}
						else {
							return false;
						}
					}
					local newVehicle = AIVehicle.CloneVehicle(depotLocation, vehiclesAtStation.Begin(), true);
					AILog.Info(AIError.GetLastErrorString());
					AIVehicle.StartStopVehicle(newVehicle);
					AILog.Info(AIError.GetLastErrorString());
				}
				else {
					AILog.Info("Count: " + depotList.Count());
					if(AIRoad.IsRoadDepotTile(depotList.Begin())) {AILog.Info("There IS a depot!")}
					depotList.Valuate(AITown.GetLocation);
					local vehiclesAtStation = AIVehicleList_Station(i);
					if(balance < 5000) {
						if(loan == maxLoan) {
							return false;
						}
						if(loan + 10000 <= maxLoan) {
							AICompany.SetLoanAmount(loan + 10000)
						}
						else {
							return false;
						}
					}
					local newVehicle = AIVehicle.CloneVehicle(depotList.Begin(), vehiclesAtStation.Begin(), true);
					AILog.Info(AIError.GetLastErrorString());
					AIVehicle.StartStopVehicle(newVehicle);
					AILog.Info(AIError.GetLastErrorString());
				}
			}
		}
	}
}
