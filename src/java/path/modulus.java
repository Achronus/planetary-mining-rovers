package path;

import jason.*;
import jason.asSemantics.*;
import jason.asSyntax.*;

public class modulus extends DefaultInternalAction {

    @Override
    public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
        // Performs the modulus operation on two numbers and outputs it as the third argument
    	int a = (int)((NumberTerm)args[0]).solve();
    	int b = (int)((NumberTerm)args[1]).solve();
    	int result = modPosition(a, b);
    	
    	return un.unifies(new NumberTermImpl(result), args[2]);
    }
    
    // Performs a basic modulus operation
    private int modPosition(int a, int b) {
    	if (a < 0 || a > b) {
    		int result = a % b;
    		return result < 0 ? result + b : result;
    	}
    	else {
    		return a;
    	}
    }
}
