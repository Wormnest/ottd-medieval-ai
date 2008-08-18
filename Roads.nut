class Roads
{
	constructor();
	function BuildRoads(startTile, endTile);
}

function Roads::BuildRoads(currNode, startTile, endTile)
{
	/*START OF ROAD BUILDING*/
	AILog.Info("Road Building...")
	AIRoad.BuildRoad(endTile.location, currNode.location)
	while(currNode.prevNode != null && currNode.location != startTile.location) {
		AIRoad.BuildRoad(currNode.location, currNode.prevNode.location);
		currNode = currNode.prevNode;
	}
	/*END OF ROAD BUILDING*/
}