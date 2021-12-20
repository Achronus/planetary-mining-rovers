package path;

public class Node implements Comparable {
	public Node parent;
	public int x, y;
	public int gCost; // distance from starting node
	public int hCost; // (heuristic) distance from end node
	public int totalCost; // gCost + hCost (fCost)
	
	Node(Node parent, int x, int y, int gCost, int hCost) {
		this.parent = parent;
		this.x = x;
		this.y = y;
		this.gCost = gCost;
		this.hCost = hCost;
		this.totalCost = gCost + hCost;
	}
	
	// Reset a node
	public void empty() {
		parent = null;
		x = 0;
		y = 0;
		gCost = 0;
		hCost = 0;
		totalCost = 0;
	}
	
	// Set a node if already created
	public void set(Node parent, int x, int y, int gCost, int hCost) {
		this.parent = parent;
		this.x = x;
		this.y = y;
		this.gCost = gCost;
		this.hCost = hCost;
		this.totalCost = gCost + hCost;
	}
	
	// Creates a copy of a node
	public Node clone() {
		return new Node(this.parent, this.x, this.y, this.gCost, this.hCost);
	}
	
	// Stores node coordinates in list format
	public int[] getCoordinates() {
		return new int[]{this.x, this.y};
	}
	
	// Compare nodes against total cost
	public int compareTo(Object obj) {
		return this.totalCost - ((Node)obj).totalCost;
	}
}
