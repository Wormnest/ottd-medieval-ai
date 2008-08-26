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
	while(currNode.parentNode != null && currNode.location != startTile.location) {
		//AISign.BuildSign(currNode.location, "Here");
		//AISign.BuildSign(currNode.prevNode.location, "Then Here");
		AIRoad.BuildRoad(currNode.location, currNode.parentNode.location);
		currNode = currNode.parentNode;
	}
	/*END OF ROAD BUILDING*/
}