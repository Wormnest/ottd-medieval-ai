class MedievalAI extends AIController 
{  
	constructor();
  
    function Start();
	function Stop();
	
	function BuildInterCityRoute();
	function KeepFlatSlopes(slopedTiles);
}

function MedievalAI::BuildInterCityRoute(cargos)
{
	AILog.Info("Starting Route");
	local townUsing = Node()
	townUsing = Towns.FindPassTown(500, null, false);
	local firstStop = Towns.BuildPassStation(-5, 5, townUsing, cargos);
	local otherTown = Towns.FindPassTown(null, townUsing, false);
	local secondStop = Towns.BuildPassStation(-5, 5, otherTown, cargos);
	if(Roads.BuildRoads(firstStop, secondStop)) {
		local depot = Towns.BuildDepot(secondStop.location)
		Vehicles.AddVehiclesToRoute(cargos, depot, firstStop, secondStop);
	}
	AILog.Info("Route Finished");
}

function MedievalAI::KeepFlatSlopes(slopedTiles)
{
	slopedTiles.Valuate(AITile.GetSlope);
	slopedTiles.RemoveValue(AITile.SLOPE_W);
	slopedTiles.RemoveValue(AITile.SLOPE_S);
	slopedTiles.RemoveValue(AITile.SLOPE_E);
	slopedTiles.RemoveValue(AITile.SLOPE_N);
	slopedTiles.RemoveValue(AITile.SLOPE_STEEP);
	slopedTiles.RemoveValue(AITile.SLOPE_NW);
	slopedTiles.RemoveValue(AITile.SLOPE_SW);
	slopedTiles.RemoveValue(AITile.SLOPE_SE);
	slopedTiles.RemoveValue(AITile.SLOPE_NE);
	slopedTiles.RemoveValue(AITile.SLOPE_EW);
	slopedTiles.RemoveValue(AITile.SLOPE_NS);
	slopedTiles.RemoveValue(AITile.SLOPE_STEEP_W);
	slopedTiles.RemoveValue(AITile.SLOPE_STEEP_S);
	slopedTiles.RemoveValue(AITile.SLOPE_STEEP_E);
	slopedTiles.RemoveValue(AITile.SLOPE_STEEP_N);
	slopedTiles.RemoveValue(AITile.SLOPE_INVALID);
	return slopedTiles;
}

class Cargos
{
	cargoList = null
	passengers = null
	
	constructor() {
		cargoList = AICargoList();
		passengers = null
		for(local cargo = cargoList.Begin(); cargoList.HasNext(); cargo = cargoList.Next()) {
			if(AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS)) {
				passengers = cargo
				break;
			}
		}
		if(passengers == null) {AILog.Info("Passengers aren't a cargo!")}
	}
}

class Routes
{
	routes = null
	numRoutes = null
	constructor() {
		routes = []
		numRoutes = 0
	}
	
	function AddStationToRoute(station);
}

function Routes::AddStationToRoute(station)
{

}

class Vehicles
{
	constructor();
	
	function AddVehiclesToRoute(depot, firstStation, secondStation);
}

function Vehicles::AddVehiclesToRoute(passCargo, depot, firstStation, secondStation)
{
	local busList = AIEngineList(AIVehicle.VEHICLE_ROAD)
	
	busList.Valuate(AIEngine.GetCargoType)
	busList.KeepValue(passCargo.passengers)
	busList.Valuate(AIEngine.GetPrice)
	busList.KeepBottom(1)
	local adjTiles = Tile.GetAdjacentTiles(firstStation.location)
	adjTiles.Valuate(AITile.IsStationTile)
	adjTiles.KeepValue(1)
	local firstStation = adjTiles.Begin()
	adjTiles = Tile.GetAdjacentTiles(secondStation.location)
	adjTiles.Valuate(AITile.IsStationTile)
	adjTiles.KeepValue(1)
	local secondStation = adjTiles.Begin();
	
	local numBuses = AITile.GetDistanceManhattanToTile(firstStation, secondStation)/20
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

class Node
{
	prevNode = null;
	id = null;
	location = 0;
	g = 30;
	h = 0;
	f = 0;	
	
	constructor() {
		prevNode = null;
		id = null;
		location = 0;
		g = 30;
		h = 0;
		f = 0;		
	}
}

class BinaryHeap
{
	heap = null;
	
	constructor() {
		heap = [];
		/*False Entry - Index must start at 1*/
		heap.append(0)
	}
	
	function AddNodeToHeap(node, nextPos);
}

function BinaryHeap::AddNodeToHeap(node, nextPos)
{
	heap.append(node)
	if(nextPos > 1) {
		for(local theHole = nextPos; theHole > 1 && heap[theHole].f < heap[theHole/2].f; theHole /= 2) {
			local temp = Node()
			temp = heap[theHole];
			heap[theHole] = heap[theHole/2];
			heap[theHole/2] = temp;
		}
	}
}
	
class Tile
{
	constructor()
	function GetAdjacentTiles(currNode);
}

function Tile::GetAdjacentTiles(currNode)
{
	local adjTiles = AITileList();
	adjTiles.AddTile(currNode - AIMap.GetTileIndex(1,0));
	adjTiles.AddTile(currNode - AIMap.GetTileIndex(0,1));
	adjTiles.AddTile(currNode - AIMap.GetTileIndex(-1,0));
	adjTiles.AddTile(currNode - AIMap.GetTileIndex(0,-1));
	adjTiles.Valuate(AITown.GetLocation);
	return adjTiles;		
}

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
		for(local i = townList.Begin(); townList.HasNext(); i = townList.Next()) {
			townTileList.AddRectangle(AITown.GetLocation(i) - AIMap.GetTileIndex(5, 5), AITown.GetLocation(i) + AIMap.GetTileIndex(5, 5));
			townTileList.Valuate(AITile.IsStationTile);
			townTileList.KeepValue(1);
			if(!townTileList.IsEmpty()) {
				AILog.Info("Occupied: " + AITown.GetName(i))
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
			if(!townTileList.IsEmpty()) {
				AILog.Info("Occupied: " + AITown.GetName(i))
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
			if(!townTileList.IsEmpty()) {
				AILog.Info("Occupied: " + AITown.GetName(i))
		 		townList.RemoveValue(AITown.GetLocation(i));
			}
			townTileList = AITileList();			
		}
		townList.Valuate(AITown.GetDistanceManhattanToTile, near.location)
		townList.KeepBottom(1)
	}
	
	if(townList.IsEmpty()) {
		AILog.Warning("No suitable towns found.")
	}
	local townFound = Node()
	townFound.location = AITown.GetLocation(townList.Begin())
	AILog.Info("Building in: " + AITown.GetName(townList.Begin()))
	return townFound;
}

function Towns::BuildPassStation(rectStart, rectEnd, townUsing, cargos)
{
	local townList = AITownList();
	local townTileList = AITileList();
	townTileList.AddRectangle(townUsing.location - AIMap.GetTileIndex(rectStart, rectStart), townUsing.location - AIMap.GetTileIndex(rectEnd, rectEnd));
	townTileList.Valuate(AIRoad.IsRoadTile)
	townTileList.KeepValue(0)
	townTileList.Valuate(AITile.IsBuildable);
	townTileList.KeepValue(1);
	MedievalAI.KeepFlatSlopes(townTileList);
	townTileList.Valuate(AIRoad.GetNeighbourRoadCount)
	townTileList.KeepAboveValue(0)
	townTileList.Valuate(AITile.GetCargoAcceptance, cargos.passengers, 1, 1, AIStation.GetCoverageRadius (AIStation.STATION_BUS_STOP))
	townTileList.KeepTop(1);
	local randTile = Node()
	townTileList.Valuate(AIBase.RandItem);
	randTile.location = townTileList.Begin();
	local adjacentTiles = Tile.GetAdjacentTiles(randTile.location)
	local isStationBuilt = false
	local thisStation = Node()
	for(local i = adjacentTiles.Begin(); adjacentTiles.HasNext(); i = adjacentTiles.Next()) {
		if(AIRoad.IsRoadTile(i) && !isStationBuilt) {
			AIRoad.BuildRoad(townTileList.Begin(), i);
			AITile.DemolishTile(townTileList.Begin());
			while(!AIRoad.BuildRoadStation(townTileList.Begin(), i, false, false, false)) {
				AILog.Warning(AIError.GetLastErrorString());
				switch (AIError.GetLastError()) {
				case AIError.ERR_AREA_NOT_CLEAR:
					AISign.BuildSign(townTileList.Begin(), "HERE");
					AISign.BuildSign(i, "NO! HERE");
					AITile.DemolishTile(townTileList.Begin());
					break;
				default:
				}
			}
			thisStation.id = AIStation.GetStationID(i);
			thisStation.location = i;
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
		MedievalAI.KeepFlatSlopes(townTileList);
		if(!townTileList.IsEmpty()) {
			depotLocation = townTileList.Begin()
			AILog.Info("Found Depot Location: " + townTileList.Begin())
			break;
		}
	}
	
	local adjacentTiles = Tile.GetAdjacentTiles(depotLocation)
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

class Roads
{
	constructor()
	function BuildRoads(startTile, endTile);
}

function Roads::BuildRoads(startTile, endTile)
{
	AILog.Info("Route Calculating...");
	//AISign.BuildSign(startTile.location, "1st Stop")
	//AISign.BuildSign(endTile.location, "2nd Stop")
	local currHeight = AITile.GetHeight(startTile.location);
	local heightNeeded = AITile.GetHeight(endTile.location);
	local hillPenalty = 0;
	local canTurn = true;
	AISign.BuildSign(10, startTile.location + "");
	AISign.BuildSign(15, endTile.location + "");
	if(currHeight == heightNeeded) {
		hillPenalty = 100;
	}
	//AILog.Info(heightNeeded + "")
	if(startTile.location != endTile.location) {
		/*SIGNS*/
		AILog.Info("Start Tile: " + startTile.location + ", End Tile: " + endTile.location)
		/*VARIABLES*/
		local atEndTile = false
		local lowestHeur = Node();
		local closedList = AIList();
		local currNode = startTile; 
		currNode.prevNode = startTile;
		local binHeap = BinaryHeap();
		local nextPos = 1;
		/*START OF PATHFINDER*/
		closedList.AddItem(startTile.location, startTile.location)
		/*CHECK IF WE'RE AT END TILE*/
		while(!atEndTile) {
			local tilesAdjToTile = Tile.GetAdjacentTiles(currNode.location)
			/*CHECK ADJACENT TILES*/
			for(local i = tilesAdjToTile.Begin(); tilesAdjToTile.HasNext() && !atEndTile; i = tilesAdjToTile.Next()) {
				//AILog.Info("Current Height: " + currHeight)
				//AILog.Info("Height Needed: " + heightNeeded)
				/*IF TILE IS BUILDABLE*/
				if(AITile.IsBuildable(i) && !closedList.HasItem(i) || AIRoad.IsRoadTile(i) && !closedList.HasItem(i)) {
					/*INITIALISE NODE*/
					local node = Node();
					node.prevNode = currNode;
					node.location = i;
					//SLOPES - FLAT = 0, NE = 12,  SW = 3, N = 8, S = 2, W = 1, E = 4, NW = 9, SE = 6 
					//AILog.Info(AITile.GetSlope(i) + "")
					if(AITile.GetSlope(i) != 0 && AITile.GetSlope(i) != 7 && AITile.GetSlope(i) != 11 && AITile.GetSlope(i) != 13 && AITile.GetSlope(i) != 14) {
						//AILog.Info(AITile.GetSlope(i) + " <-- Slope")
						if(i - AIMap.GetTileIndex(1, 0) == currNode.location) { //From the right
							//AILog.Info("From the right")
							if(AITile.GetSlope(i) == 4 || AITile.GetSlope(i) == 8 || AITile.GetSlope(i) == 12) { //Going Down
								//AILog.Info("Going down")
								if(currHeight < heightNeeded) {
									//AILog.Info("Less than")
									node.g += hillPenalty;
									currHeight--
									
								} else if(currHeight > heightNeeded) {
									//AILog.Info("More than")
									node.g -= hillPenalty;
									currHeight--
								}
								else {
									//AILog.Info("Equal to")
									node.g += hillPenalty;
								}
							}
							if(AITile.GetSlope(i) == 1 || AITile.GetSlope(i) == 2 || AITile.GetSlope(i) == 3) { //Going Up
								//AILog.Info("Going up")
								if(currHeight < heightNeeded) {
									//AILog.Info("Less than")
									node.g -= hillPenalty;
									currHeight++
								} else if(currHeight > heightNeeded) {
									//AILog.Info("More than")
									node.g += hillPenalty;
									currHeight++
								}
								else {
									//AILog.Info("Equal to")
									node.g += hillPenalty;
								}
							}
						}
						else if(i - AIMap.GetTileIndex(0, 1) == currNode.location) { //From the top
							//AILog.Info("From the top")
							if(AITile.GetSlope(i) == 2 || AITile.GetSlope(i) == 4 || AITile.GetSlope(i) == 6) { //Going up
								if(currHeight < heightNeeded) {
									//AILog.Info("Less than")
									node.g -= hillPenalty;
								} else if(currHeight > heightNeeded) {
									//AILog.Info("More than")
									node.g += hillPenalty;
								}
								else {
									//AILog.Info("Equal to")
									node.g += hillPenalty;
								}
							}
							if(AITile.GetSlope(i) == 1 || AITile.GetSlope(i) == 8 || AITile.GetSlope(i) == 9) { //Going down
								if(currHeight < heightNeeded) {
									//AILog.Info("Less than")
									node.g += hillPenalty;
								} else if(currHeight > heightNeeded) {
									//AILog.Info("More than")
									node.g -= hillPenalty;
								}
								else {
									//AILog.Info("Equal to")
									node.g += hillPenalty;
								}		
							}
						}					
						else if(i - AIMap.GetTileIndex(-1, 0) == currNode.location) { //From the left
							//AILog.Info("From the left")
							if(AITile.GetSlope(i) == 4 || AITile.GetSlope(i) == 8 || AITile.GetSlope(i) == 12) { //Going up
								//AILog.Info("Going up")
								if(currHeight < heightNeeded) {
									//AILog.Info("Less than")
									node.g -= hillPenalty;
								} else if(currHeight > heightNeeded) {
									//AILog.Info("More than")
									node.g += hillPenalty;
								}
								else {
									//AILog.Info("Equal to")
									node.g += hillPenalty;
								}
							}
							if(AITile.GetSlope(i) == 1 || AITile.GetSlope(i) == 2 || AITile.GetSlope(i) == 3) { //Going down
								//AILog.Info("Going down")
								if(currHeight < heightNeeded) {
									//AILog.Info("Less than")
									node.g += hillPenalty;
								} else if(currHeight > heightNeeded) {
									//AILog.Info("More than")
									node.g -= hillPenalty;
								}
								else {
									//AILog.Info("Equal to")
									node.g += hillPenalty;
								}
							}
						}
						else if(i - AIMap.GetTileIndex(0, -1) == currNode.location) { //From the bottom
							if(AITile.GetSlope(i) == 2 || AITile.GetSlope(i) == 4 || AITile.GetSlope(i) == 6) { //Going down
								if(currHeight < heightNeeded) {
									node.g += hillPenalty;
								} else if(currHeight > heightNeeded) {
									node.g -= hillPenalty;
								}
								else {
									//AILog.Info("Equal to")
									node.g += hillPenalty;
								}
							}
							if(AITile.GetSlope(i) == 1 || AITile.GetSlope(i) == 8 || AITile.GetSlope(i) == 9) { //Going up
								if(currHeight < heightNeeded) {
									node.g -= hillPenalty;
								} else if(currHeight > heightNeeded) {
									node.g += hillPenalty;
								}
								else {
									//AILog.Info("Equal to")
									node.g += hillPenalty;
								}		
							}
						}
						else {AILog.Info("Retard Slope")}
					}
					if(AIRoad.IsRoadTile(i)) {
						node.g -= 20;
					}
					node.h = AITile.GetDistanceManhattanToTile(i, endTile.location) * 10;
					node.f = node.g + node.h
					//AISign.BuildSign(i, node.f + "")
					if(node.h == 0) {
						atEndTile = true
					}
					else if(currNode.prevNode != null) {
						/*ADD TO BINARY HEAP*/
						binHeap.AddNodeToHeap(node, nextPos)
						nextPos++;
						/*SIGNS*/
					}
				}
				else {
					canTurn = true;
				}
			}
			if(!atEndTile) {
				for(local i = 1; i < binHeap.heap.len(); i++) {
					if(lowestHeur.f != binHeap.heap[i].f && !closedList.HasItem(binHeap.heap[i].location)) {
						lowestHeur = binHeap.heap[i];
						break;
					}
				}
			}
			if(!closedList.HasItem(lowestHeur.location)) {
				closedList.AddItem(lowestHeur.location, lowestHeur.location);
			}
			currHeight = AITile.GetHeight(currNode.location)
			if(!atEndTile && lowestHeur.prevNode != null) { 
				currNode = lowestHeur;
				currNode.prevNode = lowestHeur.prevNode
			}
		}
		/*END OF PATHFINDER*/	
		/*START OF ROAD BUILDING*/
		AILog.Info("Road Building...")
		AIRoad.BuildRoad(endTile.location, currNode.location)
		while(currNode.prevNode != null && currNode.location != startTile.location) {
			AIRoad.BuildRoad(currNode.location, currNode.prevNode.location);
			currNode = currNode.prevNode;
		}
		/*END OF ROAD BUILDING*/
	}
	else {return false};
	return true;
}

class Settings
{
	buildSlopes = false
	constructor() {
		buildSlopes = false
	}
}

function MedievalAI::Start()
{
	this.Sleep(1);
	if (!AICompany.SetCompanyName("MedievalAI")) {
		local i = 2;
		while (!AICompany.SetCompanyName("MedievalAI #" + i)) {
		i = i + 1;
		}
	}
	for(local i = 0; i < AISign.GetMaxSignID() -1; i++) {
		AISign.RemoveSign(i);
	}
	AILog.Info("Welcome to MedievalAI, enjoy your stay!");
	AILog.Info(AICompany.GetLoanInterval() + "");
	local loan = 1;
	AICompany.SetLoanAmount(loan);
	local myRoutes = Routes();
	local myCargos = Cargos();
	local gameSettings = Settings();
	
	if(AIGameSettings.IsValid("construction.build_on_slopes") && AIGameSettings.GetValue("construction.build_on_slopes")) {
		AILog.Info("Can Build on Slopes");
		gameSettings.buildSlopes = true;
	}
	for(;;) {
		local balance = AICompany.GetBankBalance(AICompany.MY_COMPANY);
		local loan = AICompany.GetLoanAmount();
		local maxLoan = AICompany.GetMaxLoanAmount();
		if(balance > 20000) {
			AILog.Info("Balance: " + balance + ", Loan: " + loan + ", Max Loan: " + maxLoan);
			MedievalAI.BuildInterCityRoute(myCargos);
		}
		else if(maxLoan != loan) {
			AILog.Info("Loaning Monies")
			AICompany.SetLoanAmount(loan + 10000);
		}
	}
}