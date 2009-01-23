class Paths
{
	MAX_TILE_COST = 400;
	NE = 1;
	SE = 2;
	NW = 3;
	SW = 4;
	
	function FindPath(startTile, endTile, truck);
	function BuildPath(startTile);
	function GetTilePenalties(node);
	function AddCostToRoute(node, routeCost);
	function GetDirection(node);
}

function Paths::GetDirection(node)
{
	//AISign.BuildSign(node.tile.location, "Node");
	//AISign.BuildSign(node.tile.location + AIMap.GetTileIndex(1,0), "SW");
	//AISign.BuildSign(node.tile.location - AIMap.GetTileIndex(1,0), "NE");
	//AISign.BuildSign(node.tile.location + AIMap.GetTileIndex(0,1), "SE");
	//AISign.BuildSign(node.tile.location - AIMap.GetTileIndex(0,1), "NW");
	
	if(node.tile.location - AIMap.GetTileIndex(1,0) == node.parentNode.tile.location)
	{
		return Paths.NE;
	}
	if(node.tile.location + AIMap.GetTileIndex(1,0) == node.parentNode.tile.location)
	{
		return Paths.SW;
	}
	if(node.tile.location - AIMap.GetTileIndex(0,1) == node.parentNode.tile.location)
	{
		return Paths.NW
	}
	if(node.tile.location + AIMap.GetTileIndex(0,1) == node.parentNode.tile.location)
	{
		return Paths.SE
	}
}

function Paths::GetTilePenalties(node)
{
	if(AIRoad.IsRoadTile(node.tile.location))
	{
		node.g -= 200;
	}
	local startPiece = node.parentNode;
	if (startPiece.parentNode != null)
	{
		if(AITile.GetDistanceSquareToTile(startPiece.parentNode.tile.location, node.tile.location) == 4)
		{
			node.g -= 200;
		}
	}
	{
		local testMode = AITestMode()
		local costs = AIAccounting()
		AIRoad.BuildRoad(node.tile.location, node.parentNode.tile.location);
		node.g += costs.GetCosts();
	}
}

function Paths::AddCostToRoute(node, routeCost)
{
	local testMode = AITestMode()
	local costs = AIAccounting()
	AIRoad.BuildRoad(node.tile.location, node.parentNode.tile.location);
	routeCost += costs.GetCosts();
	return routeCost;
}

function Paths::FindPath(startTile, endTile, truck)
{
	AILog.Info("Path starts at: " + AIStation.GetName(AIStation.GetStationID(startTile.location)) + " Station");
	AILog.Info("Path finishes at: " + AIStation.GetName(AIStation.GetStationID(endTile.location)) + " Station");
	local isPathBuilt = false;
	local lastSlope = AITile.SLOPE_INVALID;
	local hasTurned = false;
	local currentDirection = null;
	local routeCost = 0;
	local closedList = AITileList();
	local binaryHeap = [];
	binaryHeap.append(0);
	//AILog.Info(binaryHeap.len() - 1 + "");
	local lowestHeur = Node();
		lowestHeur.tile.SetAttribs(AIRoad.GetRoadStationFrontTile(startTile.location));
		AISign.BuildSign(AIRoad.GetRoadStationFrontTile(startTile.location), "Front");
		lowestHeur.h = AITile.GetDistanceManhattanToTile(AIRoad.GetRoadStationFrontTile(startTile.location), AIRoad.GetRoadStationFrontTile(endTile.location)) * 100;
	local currNode = Node();
		currNode.tile.SetAttribs(AIRoad.GetRoadStationFrontTile(startTile.location));
		currNode.parentNode = Node()
		currNode.parentNode.tile.SetAttribs(startTile.location);
		currNode.h = AITile.GetDistanceManhattanToTile(AIRoad.GetRoadStationFrontTile(startTile.location), AIRoad.GetRoadStationFrontTile(endTile.location)) * 100;
	local endNode = Node();
		endNode.tile.SetAttribs(AIRoad.GetRoadStationFrontTile(endTile.location));
	while(!isPathBuilt)
	{
		local direction = Paths.GetDirection(currNode);
		local adjTiles = GetBuildableAdjacentTiles(currNode.tile, direction);
		//AISign.BuildSign(currNode.tile.location, "Parent");
		for(local i = adjTiles.Begin(); adjTiles.HasNext(); i = adjTiles.Next())
		{
			if(!closedList.HasItem(i))
			{
				if(AITile.IsBuildable(i) || (AIRoad.IsRoadTile(i) && CanBuildRoadBetween(currNode.tile.location, i)))
				{
					//AISign.BuildSign(i, "Child");
					local node = Node();
					node.tile.SetAttribs(i);
					node.parentNode = currNode;
					direction = Paths.GetDirection(currNode);
					node.h = AITile.GetDistanceManhattanToTile(i, endNode.tile.location) * 100;
					Paths.GetTilePenalties(node);
					node.f = node.g + node.h;
					//AISign.BuildSign(i, "" + node.f);
					binaryHeap.append(node);
					//AILog.Info(binaryHeap.len() - 1 + "");
					if(binaryHeap.len() - 1 > 1)
					{
						for(local heapPos = binaryHeap.len() - 1; binaryHeap[heapPos].f < binaryHeap[heapPos/2].f; heapPos /= 2)
						{
							local temp = binaryHeap[heapPos];
							binaryHeap[heapPos] = binaryHeap[heapPos/2];
							binaryHeap[heapPos/2] = temp;
							if(heapPos/2 <= 1)
							{
								break;
							}
						}
					}
				}
			}
		}
		//AILog.Info("End of Loop");
		if(binaryHeap.len() > 1)
		{
			//AILog.Info("Binary Heap is long enough");
			for(local i =1; i < binaryHeap.len(); i++)
			{
				if(!closedList.HasItem(binaryHeap[i].tile.location))
				{
					//AILog.Info("Getting lowest heursitic.");
					lowestHeur = binaryHeap[i];
					closedList.AddTile(lowestHeur.tile.location);
					break;
				}
			}
		}
		currNode = lowestHeur;
		currNode.tile.SetAttribs(lowestHeur.tile.location);
		direction = Paths.GetDirection(currNode);
		routeCost = Paths.AddCostToRoute(currNode, routeCost);
		closedList.AddTile(currNode.tile.location);
		if(currNode.tile.location == endNode.tile.location)
			{
				AILog.Info("Path Found!");
				isPathBuilt = true;
				break;
			}
	}
	Paths.BuildPath(currNode);
	return true;
}

function Paths::BuildPath(startTile)
{
	local costTile = startTile;
	local routeCost;
	{
		local testMode = AITestMode()
		local costs = AIAccounting()
		for(; costTile.parentNode != null; costTile = costTile.parentNode)
		{
			if(!AIRoad.BuildRoad(costTile.tile.location, costTile.parentNode.tile.location))
			{
				//AILog.Error(AIError.GetLastErrorString());
			}
		}
		routeCost = costs.GetCosts();
	}
	AILog.Info("Real route cost: $" + routeCost);
	
	if(routeCost > GetBalance())
	{
		Loan();
		if(routeCost > GetBalance())
			return false;
	}
	
	for(; startTile.parentNode != null; startTile = startTile.parentNode)
	{
		if(!AIRoad.BuildRoad(startTile.tile.location, startTile.parentNode.tile.location))
		{
			switch(AIError.GetLastError())
			{
				case AIError.ERR_VEHICLE_IN_THE_WAY:
					while(AIError.GetLastError() == AIError.ERR_VEHICLE_IN_THE_WAY)
						AIRoad.BuildRoad(startTile.tile.location, startTile.parentNode.tile.location);
				break;
					
				default:
			}
		}
	}
}

function CanBuildRoadBetween(start, end)
{
	local testMode = AITestMode()
	if(AIRoad.BuildRoad(start, end))
		return true;
	else if(AIError.GetLastError() == AIError.ERR_ALREADY_BUILT)
		return true;
	else
		return false;
}

class Tile
{
	location = null;
	slope = null;
	height = null;
	
	constructor() {
		//height = Tile.GetTrueHeight();
	};
	
	function SetAttribs(tileLoc)
	{
		location = tileLoc;
		slope = AITile.GetSlope(tileLoc);
	}
}

class Node
{
	ROAD_BRIDGE = 1;
	ROAD_TUNNEL = 2;
	ROAD_OTHER_SIDE = 3;

	parentNode = null;
	g = 1000;
	h = 0;
	f = 0;
	tile = Tile();
	
	constructor() {
		parentNode = null;
		g = 1000;
		h = 0;
		f = 0;	
		tile = Tile();
	}
	
	function SetParentNode();
}

function Node::SetParentNode(node)
{
	node.parentNode = Node();
}