package path;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import jason.*;
import jason.asSemantics.*;
import jason.asSyntax.*;

public class get_route extends DefaultInternalAction {
	
    @Override
    public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
        // Using the current coordinates and goal (resource or base) coordinates, 
    	// we use the A Star algorithm to calculate the best route, returned as a list
    	
    	// Get values from arguments
    	int agentX = (int)((NumberTerm)args[0]).solve();
    	int agentY = (int)((NumberTerm)args[1]).solve();
    	int goalX = (int)((NumberTerm)args[2]).solve();
    	int goalY = (int)((NumberTerm)args[3]).solve();
    	int routeType = (int)((NumberTerm)args[5]).solve(); // 0 = resource/standard movement, 1 = base
    	
    	// Set initial values for storing route as a list
    	ListTerm finalCoordinates = new ListTermImpl();
    	List<int[]> routeCoordinates = Navigation.getInstance(ts.getUserAgArch().getAgName()).calculateBestRoute(agentX, agentY, goalX, goalY, routeType);
    	
    	// Iterate over the coordinates and store them
    	for (int[] coords: routeCoordinates) {
    		final NumberTerm x = new NumberTermImpl((int)coords[0]);
    		final NumberTerm y = new NumberTermImpl((int)coords[1]);
    		final ListTerm tempList = new ListTermImpl();
    		tempList.append(x); 
    		tempList.append(y);
    		finalCoordinates.append(tempList);
    	}
    	return un.unifies((ListTerm)finalCoordinates, args[4]);
    }
}
