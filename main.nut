class MedievalAI extends AIController 
{  
	constructor();
  
    function Start();
	function Stop();
	
	function BuildInterCityRoute();
	function KeepFlatSlopes(slopedTiles);
	
	constructor() {
		require("Pathfinding.nut");
		require("Roads.nut");
		require("Vehicles.nut");
		require("Towns.nut");
	}
}

function MedievalAI::Start()
{
	this.Sleep(1);
	//NAME COMPANY
	if (!AICompany.SetCompanyName("MedievalAI the 1st")) {
		if (!AICompany.SetCompanyName("MedievalAI the 2nd")) {
			if (!AICompany.SetCompanyName("MedievalAI the 3rd")) {
				if (!AICompany.SetCompanyName("MedievalAI the 4th")) {
					if (!AICompany.SetCompanyName("MedievalAI the 5th")) {
						if (!AICompany.SetCompanyName("MedievalAI the 6th")) {
							if (!AICompany.SetCompanyName("MedievalAI the 7th")) {
								if (!AICompany.SetCompanyName("MedievalAI the 8th")) {
									AICompany.SetCompanyName("Default Name, All others taken")
								}
							}
						}
					}
				}
			}
		}
	}
	//REMOVE SIGNS
	for(local i = 0; i < AISign.GetMaxSignID() -1; i++) {
		AISign.RemoveSign(i);
	}
	//START AI
	AILog.Info("Welcome to MedievalAI, enjoy your stay!");
	local balance = AICompany.GetBankBalance(AICompany.MY_COMPANY);
	local loan = AICompany.GetLoanAmount();
	local maxLoan = AICompany.GetMaxLoanAmount();
	local loanNeeded = false;
	AICompany.SetLoanAmount(0);
	local myCargos = Cargos();
	local gameSettings = Settings();
	local date = AIDate.GetCurrentDate();
	local newDate = 0;
	//CHECK FOR BUILD ON SLOPES
	if(AIGameSettings.IsValid("construction.build_on_slopes") && AIGameSettings.GetValue("construction.build_on_slopes")) {
		AILog.Info("Can Build on Slopes");
		gameSettings.buildSlopes = true;
	}
	//MAIN LOOP
	for(;;) {
		balance = AICompany.GetBankBalance(AICompany.MY_COMPANY);
		loan = AICompany.GetLoanAmount();
		maxLoan = AICompany.GetMaxLoanAmount();
		//GET LOAN
		if(loanNeeded && loan != maxLoan) {
			AILog.Info("Loaning Money")
			AICompany.SetLoanAmount(loan + 10000);
			loanNeeded = false;
		}
		//AILog.Info("Balance: " + balance + ", Loan: " + loan + ", Max Loan: " + maxLoan);
		//PAYBACK LOAN
		if(balance > (loan - 100000)) {
			AILog.Info("Paying Back Loan");
			if(balance > (loan - 50000)) {
				if(balance > loan) {
					AICompany.SetLoanAmount(0);
				}
				else {
					AICompany.SetLoanAmount(loan - 50000);
				}
			}
			else {
				AICompany.SetLoanAmount(loan - 100000);
			}
		}
		newDate = AIDate.GetCurrentDate()
		if(newDate - 30 > date) {
			AILog.Info("Managing Vehicles");
			date = newDate;
			Vehicles.CheckForNegativeIncome();
			Vehicles.SellInDepot();
			(balance > 5000) ? Vehicles.CheckForVehiclesNeeded(myCargos) : loanNeeded = true;
		}
	
		(balance > 20000) ?	MedievalAI.BuildInterCityRoute(myCargos) : loanNeeded = true;
	}
}

function MedievalAI::BuildInterCityRoute(cargos)
{
	AILog.Info("Starting Route");
	local townUsing = false;
	local otherTown = false;
	local routeBuilt = false;
	local counter = 0;
	local retries = 3;
	while(townUsing == false && counter < retries) { 
		townUsing = Towns.FindPassTown(20, null, false);
		counter++;
	}
	if(townUsing != false) {
		counter = 0;
		local firstStop = Towns.BuildPassStation(-5, 5, townUsing, cargos);
		while(otherTown == false && counter < retries) {
			otherTown = Towns.FindPassTown(10, townUsing, false);
			counter++;
		}
		if(otherTown != false) {
			local secondStop = Towns.BuildPassStation(-5, 5, otherTown, cargos);
			if(Paths.FindPath(firstStop, secondStop)) { 
				local depot = Towns.BuildDepot(secondStop.location)
				Vehicles.AddVehiclesToRoute(cargos, depot, firstStop, secondStop);
			}
			AILog.Info("Route Finished");
			return true
		}
	}
	Sleep(30);
	return false;

	AILog.Info("Route Finished");
}

function KeepFlatSlopes(tile)
{
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
	
function GetAdjacentTiles(currNode)
{
	local adjTiles = AITileList();
	adjTiles.AddTile(currNode - AIMap.GetTileIndex(1,0));
	adjTiles.AddTile(currNode - AIMap.GetTileIndex(0,1));
	adjTiles.AddTile(currNode - AIMap.GetTileIndex(-1,0));
	adjTiles.AddTile(currNode - AIMap.GetTileIndex(0,-1));
	adjTiles.Valuate(AITown.GetLocation);
	return adjTiles;		
}

function GetBuildableAdjacentTiles(currTile)
{
	local adjTiles = AITileList();
	local NE_TILE = Tile();
		NE_TILE.SetAttribs(currTile.location - AIMap.GetTileIndex(1,0));
	local SW_TILE = Tile();
		SW_TILE.SetAttribs(currTile.location + AIMap.GetTileIndex(1,0));
	local NW_TILE = Tile();
		NW_TILE.SetAttribs(currTile.location - AIMap.GetTileIndex(0,1));
	local SE_TILE = Tile();
		SE_TILE.SetAttribs(currTile.location + AIMap.GetTileIndex(0,1));

	// switch(currTile.slope)
	// {
		// case AITile.SLOPE_FLAT:
		// case AITile.SLOPE_NWS:
		// case AITile.SLOPE_WSE:
		// case AITile.SLOPE_SEN:
		// case AITile.SLOPE_ENW:
			adjTiles.AddTile(NE_TILE.location);
			adjTiles.AddTile(SW_TILE.location);
			adjTiles.AddTile(NW_TILE.location);
			adjTiles.AddTile(SE_TILE.location);
			// break;
		
		// case AITile.SLOPE_NW:
			// adjTiles.AddTile(NW_TILE.location);
			// adjTiles.AddTile(SE_TILE.location);
			// break;
		// case AITile.SLOPE_SW:
			// adjTiles.AddTile(NE_TILE.location);
			// adjTiles.AddTile(SW_TILE.location);
			// break;
		// case AITile.SLOPE_SE:
			// adjTiles.AddTile(NW_TILE.location);
			// adjTiles.AddTile(SE_TILE.location);
			// break;
		// case AITile.SLOPE_NE:
			// adjTiles.AddTile(NE_TILE.location);
			// adjTiles.AddTile(SW_TILE.location);
			// break;

		// default:
			// AILog.Warning("Slope not supported");
	// }
	return adjTiles;		
}

class Settings
{
	buildSlopes = false
	constructor() {
		buildSlopes = false
	}
}

