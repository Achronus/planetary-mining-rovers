package path;

import jason.*;
import jason.asSemantics.*;
import jason.asSyntax.*;

public class agent_map extends DefaultInternalAction {
	
	private static int[][] map;
	protected static int width;
	protected static int height;
	private static boolean runOnce = false;

    Navigation navigation;
	
    @Override
    public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
    	// Provides an internal map for all agents, based on their perspective
    	// Note: map can be accessed at values from [0, length-1]
    	width = (int)((NumberTerm)args[0]).solve();
    	height = (int)((NumberTerm)args[1]).solve();
    	
    	// Initialise map to all 0s
    	if(!runOnce) {
    		runOnce = true;
    		map = new int[height][width];
    		for (int y = 0; y < height; y++) {
    			for (int x = 0; x < width; x++) {
    				map[y][x] = 0;
    			}
    		}
    	}
    	return true;
    }
    
    // Update the map with a given parameter
    protected synchronized static void updateMap(int[][] newMap) {
    	map = newMap;
    }
    
    // Retrieves the map
    protected static int[][] getMap() {
		return map;
    }
    
    // Returns map to console for human readability (helpful for debugging)
    private static void printMap() {
    	System.out.println("Agent Map Layout:");
    	for (int y = 0; y <  map[0].length; y++) {
    		for (int x = 0; x < map[1].length; x++) {
    			System.out.print(map[y][x] + " ");
    		}
    		System.out.print("\n");
    	}
    	System.out.println();
    }
}
