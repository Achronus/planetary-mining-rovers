package path;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public class AStar {
	// Open nodes: set to be evaluated
	// Closed nodes: set already evaluated
	private List<Node> open, closed, path;
	private List<int[]> route;

	private int[][] map;
	
	private Node currentNode, endNode, neighbourNode;
	
	// Constructor
	public AStar() {
		this.open = new ArrayList<Node>();
		this.closed = new ArrayList<Node>();
		this.path = new ArrayList<Node>();
		this.route = new ArrayList<int[]>();
		this.currentNode = new Node(null, 0, 0, 0, 0);
		this.endNode = new Node(null, 0, 0, 0, 0);
		this.neighbourNode = new Node(null, 0, 0, 0, 0);
	}
	
	// Reset everything
	public void init() {
		this.open.clear();
		this.closed.clear();
		
		if (path != null) {
			this.path.clear();
		}
		else {
			this.path = new ArrayList<Node>();
		}
		
		this.route.clear();
		this.currentNode.empty();
		this.endNode.empty();
		this.neighbourNode.empty();
	}
	
	// Calculates the best route
	private List<Node> calculateRoute(int xStart, int yStart) {		
		// Add start node to closed
		this.closed.add(this.currentNode);
		
		// Add neighbours to open list
		addNeighbours();
		
		// Iterate from start to end
		while (this.currentNode.x != this.endNode.x || this.currentNode.y != this.endNode.y) {
			// Assign neighbour with lowest score (first node due to ordering)
			this.currentNode = this.open.get(0);
			this.open.remove(0); // Remove it from open
			this.closed.add(this.currentNode); // Add it to closed
			
			// Repeat for new node
			addNeighbours();
		}
		
		// Cycle back through the list of nodes and put into order of movement (goal as last item)
		this.path.add(0, this.currentNode);
		while (this.currentNode.x != xStart || this.currentNode.y != yStart) {
			this.currentNode = this.currentNode.parent;
			this.path.add(0, this.currentNode);
		}
		return this.path;
	}
	
	// Add neighbours of current node to open list
	private void addNeighbours() {
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				// Determine new values
				int newX = mod(this.currentNode.x + x, agent_map.width);
				int newY = mod(this.currentNode.y + y, agent_map.height);
				int hCost = distance(this.currentNode, this.endNode, x, y);
				
				// Set the neighbour node
				neighbourNode.set(this.currentNode, newX, newY, this.currentNode.gCost, hCost);
				
				// Ignore adding node if either: in a list, a resource, or the starting node
				if ((x != 0 || y != 0) &&
					!checkForNodeInList(this.open, neighbourNode) && 
					!checkForNodeInList(this.closed, neighbourNode)) {
					// Increment gCost and add a copy to open list
					neighbourNode.gCost = neighbourNode.parent.gCost + 1;
					this.open.add(neighbourNode.clone());
				}
				// Reset neighbour node
				neighbourNode.empty();
			}
		}
		// Sort nodes in relation to total cost (see Node compareTo method)
		// In ascending order (smallest first)
		open.sort(null);
	}
	
	// Sets the best route
	// routeType = 0 or 1, 0: to resource, 1: to base
	public List<int[]> bestRoute(int[][]map, int xStart, int yStart, int xEnd, int yEnd, int routeType) {
		// Store values
		this.map = map;
		this.currentNode.x = xStart;
		this.currentNode.y = yStart;
		this.endNode.x = mod(xEnd + xStart, agent_map.width);
		this.endNode.y = mod(yEnd + yStart, agent_map.height);

		// Calculate optimal route
		this.path = calculateRoute(xStart, yStart);

		// Store coordinates for each node into a readable array for the agent
		for (Node node : this.path) {
			int[] coords = node.getCoordinates();
			this.route.add(coords);
		}
		
		// Remove starting node, resource/standard movement route
		if (routeType == 0 && this.route.size() > 1) {
			this.route.remove(0);
		}
		// Returning to base, reverse route
		else if (routeType == 1) {
			Collections.reverse(this.route);
			this.route.remove(0);
		}
		return this.route;
	}
	
	// Checks if a node is in a list
	private static boolean checkForNodeInList(List<Node> nodeList, Node node) {
		for (Node item : nodeList) {
			if (item.x == node.x && item.y == node.y)
				return true;
		}
		return false;
	}
	
	// Calculate the Manhattan distance between two nodes for hCost
	private int distance(Node a, Node b, int nearestX, int nearestY) {
		int x = distanceMod(a.x + nearestX, b.x, agent_map.width);
		int y = distanceMod(a.y + nearestY, b.y, agent_map.height);
		return x + y;
	}
	
	// Modulus of the distance between two nodes
	private int distanceMod(int a, int b, int axisLength) {
		int difference = Math.abs(b - a);
		return difference < Math.floor(axisLength/2) ? difference : axisLength - difference;
	}
	
    // Takes the modulus of two numbers - used to handle 'wrap around' map movement
    private int mod(int a, int b) {
    	// E.g. 2 % 10 = 2
    	// 2 / 10 = 0, so 2 - 0 = 2 
    	int result = a % b;
    	return result < 0 ? result + b : result;
    }
}
