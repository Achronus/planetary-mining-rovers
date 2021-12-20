package path;

import java.util.ArrayList;
import java.util.List;

import jason.*;
import jason.asSemantics.*;
import jason.asSyntax.*;

public class get_quadrants extends DefaultInternalAction {

    @Override
    public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
        /* 
        * Gets the agent quadrants as an array of Y values that are a list
    	* of int arrays that contain a lower and upper bound
    	*/
    	int numberOfAgents = (int)((NumberTerm)args[0]).solve();
    	List<int[]> quadrantHeights = divideMap(numberOfAgents);
    	ListTerm heights = new ListTermImpl();
    	
    	// Iterate over the quadrant heights and store them
    	for (int[] bounds : quadrantHeights) {
    		final NumberTerm lower = new NumberTermImpl((int)bounds[0]);
    		final NumberTerm upper = new NumberTermImpl((int)bounds[1]);
    		final ListTerm temp = new ListTermImpl();
    		temp.append(lower);
    		temp.append(upper);
    		heights.append(temp);
    	}
    	return un.unifies((ListTerm)heights, args[1]);
    }
    
    // Split map into quadrants
    private List<int[]> divideMap(int numAgents) {
    	// Get a single quadrants height
    	List<int[]> heights = new ArrayList<int[]>();
    	int totalHeight = agent_map.height;
    	int baseHeight = (int)Math.floor(totalHeight/numAgents);
    	int lb = 0;
    	int ub = baseHeight;
    	
    	// Split height into quadrants
    	for (int i = 0; i < numAgents; i++) {
    		int[] bounds = new int[2]; // [lower, upper] bounds
    		
    		// Calculate bounds and add to list
    		bounds[0] = lb;
    		bounds[1] = ub;
    		heights.add(bounds);
    		
    		// Increment bounds for next iteration
			lb += ub+1;
    		ub = lb + baseHeight;
    		
    		// Don't exceed max height
    		if (ub > totalHeight) {
    			ub = totalHeight;
    		}
    	}
    	return heights;
    }
    
}
