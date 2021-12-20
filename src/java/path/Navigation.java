package path;

import java.util.*;

public class Navigation {
    
	private static HashMap<String, Navigation> instances = null;
	
	private int xPos, yPos; // col, row
	private static AStar aStar;
	
	// Creates an instance of the agent, taken from the decompiled rover code
    public synchronized static Navigation getInstance(final String ag) {
        if (instances == null) {
            (instances = new HashMap<String, Navigation>()).put(ag, new Navigation());
        }
        if (instances.get(ag) == null) {     
        	instances.put(ag, new Navigation());
        }
        return instances.get(ag);
    }
    
    // Initialise variables
    public Navigation() {
    	aStar = new AStar();
    	xPos = 0;
    	yPos = 0;
    }
    
    // Updates the agents current position
    public synchronized void UpdatePosition(int x, int y) {
    	// Reset indices
    	int rowIdx = 0, colIdx = 0;

    	// Set new information
    	colIdx = mod(xPos + x, agent_map.width);
    	rowIdx = mod(yPos + y, agent_map.height);
    	
    	xPos = colIdx;
    	yPos = rowIdx;
    }
      
    // Get agents current position
    public int[] getPosition() {
    	return new int[]{xPos, yPos};
    }
    
    // Adds a resource to the map
    public void addResource(int x, int y, int idx) {
    	int[][] map = agent_map.getMap();
        map[mod(y, agent_map.height)][mod(x, agent_map.width)] = idx;
        agent_map.updateMap(map);
	}
    
    // Calculates the best route to the target location
    public List<int[]> calculateBestRoute(int startX, int startY, int endX, int endY, int routeType) {
    	// Initialise the AStar algorithm
    	aStar.init();
    	
    	// Review map and return best path
    	int[][] map = agent_map.getMap();
    	return aStar.bestRoute(map, startX, startY, endX, endY, routeType);
    }
    
    // Takes the modulus of two numbers - used to handle 'wrap around' map movement
    // Three step process (integer division): divide, multiply, subtract
    /* E.g. 2 % 10 = 2
    		2 / 10 = 0.2 (0)
    		0 * 10 = 0
    		2 - 0  = 2
    */
    public int mod(int a, int b) {
    	int result = a % b;
    	return result < 0 ? result + b : result;
    }
}
