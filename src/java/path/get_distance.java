package path;

import jason.*;
import jason.asSemantics.*;
import jason.asSyntax.*;

public class get_distance extends DefaultInternalAction {

    @Override
    public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
        // Gets the relative distance between two points, accounting for wrap around
    	int agentX = (int)((NumberTerm)args[0]).solve();
    	int agentY = (int)((NumberTerm)args[1]).solve();
    	int goalX = (int)((NumberTerm)args[2]).solve();
    	int goalY = (int)((NumberTerm)args[3]).solve();
    	
    	int newX = xDistance(agentX, goalX);
    	int newY = yDistance(agentY, goalY);
    	
    	return un.unifies(new NumberTermImpl(newX), args[4]) && un.unifies(new NumberTermImpl(newY), args[5]);
    }
    
    private int xDistance(int pos, int goal) {
    	return distance(pos, goal, agent_map.width);
    }
    
    private int yDistance(int pos, int goal) {
    	return distance(pos, goal, agent_map.height);
    }
    
    // Calculates the distance between two points
    private int distance(int a, int b, int axis) {
    	// Handle upper bound wrap around
    	if ((a == axis-1 && b == 0)) {
    		return 1;
    	}
    	// Handle lower bound wrap around
    	else if ((a == 0 && b == axis-1)) {
    		return -1;
    	}
    	// Handle generic case
    	else {
    		return b - a;
    	}
    }
}
