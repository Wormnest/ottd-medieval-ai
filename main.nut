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
	if (!AICompany.SetCompanyName("MedievalAI")) {
		local i = 2;
		while (!AICompany.SetCompanyName("MedievalAI #" + i)) {
			i = i + 1;
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
		townUsing = Towns.FindPassTown(1000, null, false);
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
			if(Pathfinding.FindPath(firstStop, secondStop)) {
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

function KeepFlatSlopes(slopedTiles)
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

class Settings
{
	buildSlopes = false
	constructor() {
		buildSlopes = false
	}
}

