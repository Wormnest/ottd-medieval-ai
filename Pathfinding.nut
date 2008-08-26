class Paths
{
	MAX_TILE_COST = 400;
	
	function FindPath(startTile, endTile);
	function BuildPath(startTile);
}

function Paths::FindPath(startTile, endTile)
{
	AILog.Info("Path starts at: " + AIStation.GetName(AIStation.GetStationID(startTile.location)) + " Station");
	AILog.Info("Path finishes at: " + AIStation.GetName(AIStation.GetStationID(endTile.location)) + " Station");
	local isPathBuilt = false;
	local closedList = AITileList();
	local binaryHeap = [];
	binaryHeap.append(0);
	AILog.Info(binaryHeap.len() - 1 + "");
	local lowestHeur = Node();
		lowestHeur.tile.SetAttribs(AIRoad.GetRoadStationFrontTile(startTile.location));
		lowestHeur.h = AITile.GetDistanceManhattanToTile(AIRoad.GetRoadStationFrontTile(startTile.location), AIRoad.GetRoadStationFrontTile(endTile.location)) * 100;
	local currNode = Node();
		currNode.tile.SetAttribs(AIRoad.GetRoadStationFrontTile(startTile.location));
		currNode.parentNode = Node()
		currNode.parentNode.tile.SetAttribs(AIRoad.GetRoadStationFrontTile(startTile.location));
		currNode.h = AITile.GetDistanceManhattanToTile(AIRoad.GetRoadStationFrontTile(startTile.location), AIRoad.GetRoadStationFrontTile(endTile.location)) * 100;
	local endNode = Node();
		endNode.tile.SetAttribs(AIRoad.GetRoadStationFrontTile(endTile.location));
	while(!isPathBuilt)
	{
		local adjTiles = GetAdjacentTiles(currNode.tile.location);
		//AISign.BuildSign(currNode.tile.location, "Parent: " + currNode.h);
		for(local i = adjTiles.Begin(); adjTiles.HasNext(); i = adjTiles.Next())
		{
			if(!closedList.HasItem(i))
			{
				if(AITile.IsBuildable(i) || AIRoad.IsRoadTile(i))
				{
					local node = Node();
					node.tile.SetAttribs(i);
					node.h = AITile.GetDistanceManhattanToTile(i, endNode.tile.location) * 100;
					node.parentNode = currNode;
					//AISign.BuildSign(i, "Child: " + node.h);
					binaryHeap.append(node);
					AILog.Info(binaryHeap.len() - 1 + "");
					if(binaryHeap.len() - 1 > 1)
					{
						for(local heapPos = binaryHeap.len() - 1; binaryHeap[heapPos].h < binaryHeap[heapPos/2].h; heapPos /= 2)
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
		AILog.Info("End of Loop");
		if(binaryHeap.len() > 1)
		{
			AILog.Info("Binary Heap is long enough");
			for(local i =1;; i++)
			{
				if(!closedList.HasItem(binaryHeap[i].tile.location))
				{
					AILog.Info("Getting lowest heursitic.");
					lowestHeur = binaryHeap[i];
					closedList.AddTile(lowestHeur.tile.location);
					break;
				}
			}
		}
		currNode = lowestHeur;
		currNode.tile.SetAttribs(lowestHeur.tile.location);
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
	for(; startTile.parentNode != null; startTile = startTile.parentNode)
	{
		AILog.Info("Building from: " + startTile.tile.location + " to " + startTile.parentNode.tile.location);
		AIRoad.BuildRoad(startTile.tile.location, startTile.parentNode.tile.location);
	}
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
	parentNode = null;
	g = 30;
	h = 0;
	f = 0;
	tile = Tile();
	
	constructor() {
		parentNode = null;
		g = 30;
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