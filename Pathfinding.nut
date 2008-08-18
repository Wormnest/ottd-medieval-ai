class Pathfinding
{
	constructor();
	function FindPath(startTile, endTile);
}

function Pathfinding::FindPath(startTile, endTile)
{
	AILog.Info("Route Calculating...");
	local currHeight = AITile.GetHeight(startTile.location);
	local heightNeeded = AITile.GetHeight(endTile.location);
	local hillPenalty = 0;
	local canTurn = true;
	if(currHeight == heightNeeded) {
		hillPenalty = 100;
	}
	//AILog.Info(heightNeeded + "")
	if(startTile.location != endTile.location) {
		/*SIGNS*/
		AILog.Info("Start Tile: " + startTile.location + ", End Tile: " + endTile.location)
		/*VARIABLES*/
		local tilesAdjToTile = null;
		local nextTile = null;
		local atEndTile = false
		local needAdjacency = true;
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
			if(needAdjacency) {
				tilesAdjToTile = GetAdjacentTiles(currNode.location)
			}
			else {
				needAdjacency = true;
				tilesAdjToTile.Clear();
				tilesAdjToTile.AddTile(nextTile);
			}
			/*CHECK ADJACENT TILES*/
			for(local i = tilesAdjToTile.Begin(); tilesAdjToTile.HasNext() && !atEndTile; i = tilesAdjToTile.Next()) {
				/*IF TILE IS BUILDABLE*/
				if(AITile.IsBuildable(i) && !closedList.HasItem(i) || AIRoad.IsRoadTile(i) && !closedList.HasItem(i)) {
					/*INITIALISE NODE*/
					AISign.BuildSign(i, "Tile");
					local node = Node();
					node.prevNode = currNode;
					node.location = i;
					if(AIRoad.IsRoadTile(i)) {
						node.g -= 100;
					}
					//SLOPES
					if(AITile.GetSlope(i) != AITile.SLOPE_FLAT && AITile.GetSlope(i) != AITile.SLOPE_NWS && AITile.GetSlope(i) != AITile.SLOPE_WSE && AITile.GetSlope(i) != AITile.SLOPE_SEN && AITile.GetSlope(i) != AITile.SLOPE_ENW) {
						AISign.BuildSign(i, "Sloped");
						AILog.Info(AITile.GetSlope(i) + " <-- Slope")
						if(i - AIMap.GetTileIndex(1, 0) == currNode.location) { //From the north-east
							//AILog.Info("From the north-east");
							if(AITile.GetSlope(i) == AITile.SLOPE_S || AITile.GetSlope(i) == AITile.SLOPE_W || AITile.GetSlope(i) == AITile.SLOPE_SW) { //Going Up
								//AILog.Info("Going up")
								canTurn = true;
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
							else if(AITile.GetSlope(i) == AITile.SLOPE_N || AITile.GetSlope(i) == AITile.SLOPE_E || AITile.GetSlope(i) == AITile.SLOPE_NE) { //Going Down
								//AILog.Info("Going down")
								canTurn = true;
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
						}
						else if(i + AIMap.GetTileIndex(0, 1) == currNode.location) { //From the north-west
							//AILog.Info("From the north-west");
							if(AITile.GetSlope(i) == AITile.SLOPE_S || AITile.GetSlope(i) == AITile.SLOPE_E || AITile.GetSlope(i) == AITile.SLOPE_SE) { //Going up
								//AILog.Info("Going up");
								canTurn = false;
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
							else if(AITile.GetSlope(i) == AITile.SLOPE_N || AITile.GetSlope(i) == AITile.SLOPE_W || AITile.GetSlope(i) == AITile.SLOPE_NW) { //Going down
								//AILog.Info("Going down");
								canTurn = true;
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
						else if(i + AIMap.GetTileIndex(1, 0) == currNode.location) { //From the south-west
							//AILog.Info("From the south-west");
							if(AITile.GetSlope(i) == AITile.SLOPE_N || AITile.GetSlope(i) == AITile.SLOPE_E || AITile.GetSlope(i) == AITile.SLOPE_NE) { //Going up
								//AILog.Info("Going up")
								canTurn = false;
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
							else if(AITile.GetSlope(i) == AITile.SLOPE_S || AITile.GetSlope(i) == AITile.SLOPE_W || AITile.GetSlope(i) == AITile.SLOPE_SW) { //Going down
								//AILog.Info("Going down")
								canTurn = false;
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
						else if(i - AIMap.GetTileIndex(0, 1) == currNode.location) { //From the south-east
							//AILog.Info("From the south-east");
							if(AITile.GetSlope(i) == AITile.SLOPE_N || AITile.GetSlope(i) == AITile.SLOPE_W || AITile.GetSlope(i) == AITile.SLOPE_NW) { //Going up
								//AILog.Info("Going Up")
								canTurn = false;
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
							else if(AITile.GetSlope(i) == AITile.SLOPE_S || AITile.GetSlope(i) == AITile.SLOPE_E || AITile.GetSlope(i) == AITile.SLOPE_SE) { //Going down
								//AILog.Info("Going Down")
								canTurn = true;
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
						}
						else {AILog.Info("Other Slope")}
					}

				//	AISign.BuildSign(i, "i")
					if(!canTurn) {
						canTurn = true;
						needAdjacency = false;
					//	AISign.BuildSign(i, "ii");
						if(i - AIMap.GetTileIndex(1, 0) == currNode.location) { //From the north-east
							AISign.BuildSign(i, "iii");
							//AISign.BuildSign(i - AIMap.GetTileIndex(1, 0), "Next i");
							nextTile = i - AIMap.GetTileIndex(1, 0);
						}
						else if(i + AIMap.GetTileIndex(0, 1) == currNode.location) { //From the north-west
							AISign.BuildSign(i, "iii");
							//AISign.BuildSign(i - AIMap.GetTileIndex(0, 1), "Next i");
							nextTile = i - AIMap.GetTileIndex(0, 1);
						}
						else if(i + AIMap.GetTileIndex(1, 0) == currNode.location) { //From the south-west
							AISign.BuildSign(i, "iii");
							//AISign.BuildSign(i - AIMap.GetTileIndex(-1, 0), "Next i");
							nextTile = i - AIMap.GetTileIndex(-1, 0);
						}
						else if(i - AIMap.GetTileIndex(0, 1) == currNode.location) { //From the south-east
							AISign.BuildSign(i, "iii");
							//AISign.BuildSign(i - AIMap.GetTileIndex(0, -1), "Next i");
							nextTile = i - AIMap.GetTileIndex(0, 1);
						}
						AILog.Info(i + "");
						AILog.Info(nextTile + "");
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
			}
			if(!atEndTile) {
				for(local i = 1; i < binHeap.heap.len(); i++) {
					if(lowestHeur.f != binHeap.heap[i].f && !closedList.HasItem(binHeap.heap[i].location)) {
						lowestHeur = binHeap.heap[i];
						break;
					}
				}
			}
			closedList.AddItem(lowestHeur.location, lowestHeur.location);
			currHeight = AITile.GetHeight(currNode.location)
			if(!atEndTile && lowestHeur.prevNode != null) { 
				currNode = lowestHeur;
				currNode.prevNode = lowestHeur.prevNode
			}
		}
		/*END OF PATHFINDER*/	
		Roads.BuildRoads(currNode, startTile, endTile);
	}
	else {return false};
	return true;
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
