class MedievalAI extends AIController 
{  
	constructor();
  
    function Start();
	function Stop();
	function Save();
	
	function KeepFlatSlopes(slopedTiles);
	function HandleEvents();
	
	constructor() 
	{
		require("Pathfinding.nut");
		require("Vehicles.nut");
		require("Buses.nut");
		require("Trucks.nut");
	}
}

function MedievalAI::Save()
{
	local table = {};
	return table;
}

function MedievalAI::Start()
{
	this.Sleep(1);
	
	//NAME COMPANY
	if (!AICompany.SetName("MedievalAI #1")) 
	{
		local i = 2;
		while(!AICompany.SetName("MedievalAI #" + i))
			i++;
	}
		
	//REMOVE SIGNS
	for(local i = 0; i < AISign.GetMaxSignID() -1; i++) {
		AISign.RemoveSign(i);
	}
	
	//INITALIZE AI
	AILog.Info("MedievalAI, now 99% fat free");
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
	
	local balance = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
	local loan = AICompany.GetLoanAmount();
	local maxLoan = AICompany.GetMaxLoanAmount();
	local loanNeeded = false;
		
	local date = AIDate.GetCurrentDate();
	
	local gameSettings = Settings();
	
	//CHECK FOR BUILD ON SLOPES
	if(AIGameSettings.IsValid("construction.build_on_slopes") && AIGameSettings.GetValue("construction.build_on_slopes")) {
		AILog.Info("Can Build on Slopes");
		gameSettings.buildSlopes = true;
	}
	
	//BUILD INITIAL ROUTE
	//Trucks.BuildTruckRoute();
	Buses.BuildBusRoute();
	
	//MAIN LOOP
	for(;;) 
	{
		local balance = GetBalance();
		local loan = AICompany.GetLoanAmount();
		local maxLoan = AICompany.GetMaxLoanAmount();
		
		//GET LOAN
		if(loanNeeded || balance < 20000) 
		{
			Loan();
		}

		//PAYBACK LOAN
		while(balance >= 50000)
		{
			AICompany.SetLoanAmount(loan - 10000);
			balance = GetBalance();
			loan = AICompany.GetLoanAmount();
		}

		if(AIDate.GetCurrentDate() - 30 >= date) 
		{
			date = AIDate.GetCurrentDate();
			
			Vehicles.CheckForNegativeIncome();
			Vehicles.CheckOldVehicles();
			Vehicles.SellInDepot();
			
			(balance > 10000) ? Vehicles.CheckForVehiclesNeeded() : loanNeeded = true;
			
			if(AIBase.RandRange(2) == 0)
			{
				(balance > 30000) ?	Buses.BuildBusRoute() : loanNeeded = true;
			}
			else
			{
				(balance > 30000) ?	Trucks.BuildTruckRoute() : loanNeeded = true;
			}	
		}
		MedievalAI.HandleEvents();
	}
}

function MedievalAI::HandleEvents()
{
	while(AIEventController.IsEventWaiting())
	{
		local event = AIEventController.GetNextEvent();
		switch(event.GetEventType())
		{
			case AIEvent.AI_ET_ENGINE_PREVIEW:
				local eventResponse = AIEventEnginePreview.Convert(event);
				eventResponse.AcceptPreview();
				AILog.Info("Accepted offer to trial the " + eventResponse.GetName());
				break;
		}
	}
}


function BuildRoadDepot(depotLocation)
{
	local townTileList = AITileList();
	for(local i = 1;; i ++) 
	{
		townTileList.AddRectangle(depotLocation - AIMap.GetTileIndex(i, i), depotLocation + AIMap.GetTileIndex(i, i));
		townTileList.Valuate(AITile.IsBuildable)
		townTileList.KeepValue(1)
		townTileList.Valuate(function (tile) 
		{
			local adjTiles = AITileList();
			adjTiles.AddTile(tile - AIMap.GetTileIndex(1,0));
			adjTiles.AddTile(tile - AIMap.GetTileIndex(0,1));
			adjTiles.AddTile(tile - AIMap.GetTileIndex(-1,0));
			adjTiles.AddTile(tile - AIMap.GetTileIndex(0,-1));
			for(local j = adjTiles.Begin(); adjTiles.HasNext(); j = adjTiles.Next())
			{
				if(AIRoad.IsDriveThroughRoadStationTile(j))
					return 0;
			}
			return 1;
		})
		townTileList.KeepValue(1);
		townTileList.Valuate(AIRoad.GetNeighbourRoadCount);
		townTileList.KeepAboveValue(0);
		townTileList.Valuate(function (tile) 
		{
			switch(AITile.GetSlope(tile)) {
				case AITile.SLOPE_FLAT:
					return 0;
			
				default:
					return 1;
			}
		})
		townTileList.KeepValue(0); 
		townTileList.Valuate(GetAdjacentTiles, true);
		townTileList.KeepValue(0);
		if(!townTileList.IsEmpty()) 
		{
			depotLocation = townTileList.Begin();
			break;
		}
	}
	
	local adjacentTiles = GetAdjacentTiles(depotLocation, false)
	local isDepotBuilt = false
	for(local i = adjacentTiles.Begin(); adjacentTiles.HasNext(); i = adjacentTiles.Next()) {
		if(AIRoad.IsRoadTile(i) && !isDepotBuilt && AITile.GetSlope(i) == AITile.SLOPE_FLAT) {
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

function Loan()
{
	while(AICompany.GetLoanAmount() < AICompany.GetMaxLoanAmount())
	{
		AICompany.SetLoanAmount(AICompany.GetLoanAmount() + 10000);
	}
}

function GetBalance()
{
	return AICompany.GetBankBalance(AICompany.COMPANY_SELF);
}
	
function GetAdjacentTiles(currNode, flat)
{
	local adjTiles = AITileList();
	adjTiles.AddTile(currNode - AIMap.GetTileIndex(1,0));
	adjTiles.AddTile(currNode - AIMap.GetTileIndex(0,1));
	adjTiles.AddTile(currNode - AIMap.GetTileIndex(-1,0));
	adjTiles.AddTile(currNode - AIMap.GetTileIndex(0,-1));
	if(flat)
	{
		adjTiles.Valuate(AITile.GetSlope);
		adjTiles.KeepValue(AITile.SLOPE_FLAT);
		adjTiles.Valuate(AIRoad.IsRoadTile);
		adjTiles.KeepValue(1);
		if(adjTiles.IsEmpty())
		{
			return 1;
		}
		return 0
	}	
	//AILog.Error(AIError.GetLastErrorString());
	if(adjTiles.Count() == 0)
	{
		AILog.Info("adjTiles:C - " + adjTiles.Count());
		AILog.Info("Valid? " + AIMap.IsValidTile(currNode))
		Sleep(100);
	}
	
	adjTiles.Valuate(AITown.GetLocation);
	//AILog.Error(AIError.GetLastErrorString() + ", TOWN");
	return adjTiles;		
}

function KeepFlatTile()
{
	
}

function GetBuildableAdjacentTiles(currTile, direction)
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
			
	switch(currTile.slope)
	{
		case AITile.SLOPE_FLAT:
		case AITile.SLOPE_NWS:
		case AITile.SLOPE_WSE:
		case AITile.SLOPE_SEN:
		case AITile.SLOPE_ENW:
			if(NE_TILE.slope != AITile.SLOPE_ELEVATED && NE_TILE.slope != AITile.SLOPE_INVALID)
			{
				adjTiles.AddTile(NE_TILE.location);
			}
			if(SW_TILE.slope != AITile.SLOPE_ELEVATED && SW_TILE.slope != AITile.SLOPE_INVALID)
			{
				adjTiles.AddTile(SW_TILE.location);
			}
			if(NW_TILE.slope != AITile.SLOPE_ELEVATED && NW_TILE.slope != AITile.SLOPE_INVALID)
			{
				adjTiles.AddTile(NW_TILE.location);
			}
			if(SE_TILE.slope != AITile.SLOPE_ELEVATED && SE_TILE.slope != AITile.SLOPE_INVALID)
			{
				adjTiles.AddTile(SE_TILE.location);
			}
			break;
		
		case AITile.SLOPE_NS:	
		case AITile.SLOPE_EW:
			switch(direction)
			{
				case Paths.NE:
					adjTiles.AddTile(SW_TILE.location);
					adjTiles.AddTile(NW_TILE.location);
					adjTiles.AddTile(SE_TILE.location);
					break;
				case Paths.SE:
					adjTiles.AddTile(NW_TILE.location);
					adjTiles.AddTile(NE_TILE.location);
					adjTiles.AddTile(SW_TILE.location);
					break;
				case Paths.NW:
					adjTiles.AddTile(SE_TILE.location);
					adjTiles.AddTile(NE_TILE.location);
					adjTiles.AddTile(SW_TILE.location);
					break;
				case Paths.SW:
					adjTiles.AddTile(NE_TILE.location);
					adjTiles.AddTile(NW_TILE.location);
					adjTiles.AddTile(SE_TILE.location);
					break;
			}
			
		case AITile.SLOPE_STEEP_N:
			switch(direction)
			{
				case Paths.NE:
					adjTiles.AddTile(SW_TILE.location);
					break;
				case Paths.SE:
					adjTiles.AddTile(NW_TILE.location);
					break;
				case Paths.NW:
					adjTiles.AddTile(SE_TILE.location);
					break;
				case Paths.SW:
					adjTiles.AddTile(NE_TILE.location);
					break;
			}	
			
		case AITile.SLOPE_STEEP_E:
			switch(direction)
			{
				case Paths.NE:
					adjTiles.AddTile(SW_TILE.location);
					break;
				case Paths.SE:
					adjTiles.AddTile(NW_TILE.location);
					break;
				case Paths.NW:
					adjTiles.AddTile(SE_TILE.location);
					break;
				case Paths.SW:
					adjTiles.AddTile(NE_TILE.location);
					break;
			}	
			
		case AITile.SLOPE_STEEP_S:
			switch(direction)
			{
				case Paths.NE:
					adjTiles.AddTile(SW_TILE.location);
					break;
				case Paths.SE:
					adjTiles.AddTile(NW_TILE.location);
					break;
				case Paths.NW:
					adjTiles.AddTile(SE_TILE.location);
					break;
				case Paths.SW:
					adjTiles.AddTile(NE_TILE.location);
					break;
			}	
			
		case AITile.SLOPE_STEEP_W:
			switch(direction)
			{
				case Paths.NE:
					adjTiles.AddTile(SW_TILE.location);
					break;
				case Paths.SE:
					adjTiles.AddTile(NW_TILE.location);
					break;
				case Paths.NW:
					adjTiles.AddTile(SE_TILE.location);
					break;
				case Paths.SW:
					adjTiles.AddTile(NE_TILE.location);
					break;
			}	
			
		case AITile.SLOPE_NW:
			switch(direction)
			{
				case Paths.SE:
					adjTiles.AddTile(NW_TILE.location);
					break;
				case Paths.NW:
					adjTiles.AddTile(NE_TILE.location);
					adjTiles.AddTile(SE_TILE.location);
					adjTiles.AddTile(SW_TILE.location);
					break;
				case Paths.NE:
					adjTiles.AddTile(SW_TILE.location);
					adjTiles.AddTile(NW_TILE.location);
					break;
				case Paths.SW:
					adjTiles.AddTile(NE_TILE.location);
					adjTiles.AddTile(NW_TILE.location);
					break;
			}
			break;
		case AITile.SLOPE_SW:
			switch(direction)
			{
				case Paths.SW:
					adjTiles.AddTile(NE_TILE.location);
					adjTiles.AddTile(NW_TILE.location);
					adjTiles.AddTile(SE_TILE.location);
					break;
					
				case Paths.NE:
					adjTiles.AddTile(SW_TILE.location);
					break;
					
				case Paths.SE:
					adjTiles.AddTile(NW_TILE.location);
					adjTiles.AddTile(SW_TILE.location);
					break;
					
				case Paths.NW:
					adjTiles.AddTile(SW_TILE.location);
					adjTiles.AddTile(SE_TILE.location);
					break;
			}
			break;
		case AITile.SLOPE_SE:
			switch(direction)
			{
				case Paths.SW:
					adjTiles.AddTile(NE_TILE.location);
					adjTiles.AddTile(SE_TILE.location);
					break;
					
				case Paths.NE:
					adjTiles.AddTile(SW_TILE.location);
					adjTiles.AddTile(SE_TILE.location);
					break;
					
				case Paths.SE:
					adjTiles.AddTile(NW_TILE.location);
					adjTiles.AddTile(NE_TILE.location);
					adjTiles.AddTile(SW_TILE.location);
					break;
					
				case Paths.NW:
					adjTiles.AddTile(SE_TILE.location);
					break;
			}
			break;
		case AITile.SLOPE_NE:
			switch(direction)
			{
				case Paths.SW:
					adjTiles.AddTile(NE_TILE.location);
					break;
					
				case Paths.NE:
					adjTiles.AddTile(SW_TILE.location);
					adjTiles.AddTile(NW_TILE.location);
					adjTiles.AddTile(SE_TILE.location);
					break;
					
				case Paths.SE:
					adjTiles.AddTile(NW_TILE.location);
					adjTiles.AddTile(NE_TILE.location);
					break;
					
				case Paths.NW:
					adjTiles.AddTile(SE_TILE.location);
					adjTiles.AddTile(NE_TILE.location);
					break;
			}
			break;
			
		case AITile.SLOPE_N:
			switch(direction)
			{
				case Paths.NE:
					adjTiles.AddTile(NW_TILE.location);
					adjTiles.AddTile(SW_TILE.location);
					break;
					
				case Paths.NW:
					adjTiles.AddTile(NE_TILE.location);
					adjTiles.AddTile(SE_TILE.location);
					break;
						
				case Paths.SE:
					adjTiles.AddTile(NW_TILE.location);
					break;
					
				case Paths.SW:
					adjTiles.AddTile(NE_TILE.location);
					break;
			}
			break;
		case AITile.SLOPE_E:
			switch(direction)
			{
				case Paths.NE:
					adjTiles.AddTile(SE_TILE.location);
					adjTiles.AddTile(SW_TILE.location);
					break;
					
				case Paths.NW:
					adjTiles.AddTile(SE_TILE.location);
					break;
					
				case Paths.SE:
					adjTiles.AddTile(NW_TILE.location);
					adjTiles.AddTile(NE_TILE.location);
					break;
					
				case Paths.SW:
					adjTiles.AddTile(NE_TILE.location);
					break;
			}
			break;
		case AITile.SLOPE_S:
			switch(direction)
			{
				case Paths.NE:
					adjTiles.AddTile(SW_TILE.location);
					break;
					
				case Paths.NW:
					adjTiles.AddTile(SE_TILE.location);
					break;
					
				case Paths.SE:
					adjTiles.AddTile(NW_TILE.location);
					adjTiles.AddTile(SE_TILE.location);
					break;
					
				case Paths.SW:
					adjTiles.AddTile(NE_TILE.location);
					adjTiles.AddTile(SE_TILE.location);
					break;
			}
			break;
		case AITile.SLOPE_W:
			switch(direction)
			{
				case Paths.NE:
					adjTiles.AddTile(SW_TILE.location);
					break;
					
				case Paths.NW:
					adjTiles.AddTile(SE_TILE.location);
					adjTiles.AddTile(SW_TILE.location);
					break;
					
				case Paths.SE:
					adjTiles.AddTile(NW_TILE.location);
					break;
					
				case Paths.SW:
					adjTiles.AddTile(NE_TILE.location);
					adjTiles.AddTile(NW_TILE.location);
					break;
			}
			break		
			
		default:
			AILog.Error("Slope not supported");
			AISign.BuildSign(currTile.location, "Unknown Slope!");
	}
	return adjTiles;		
}

class Settings
{
	buildSlopes = false
	constructor() {
		buildSlopes = false
	}
}

