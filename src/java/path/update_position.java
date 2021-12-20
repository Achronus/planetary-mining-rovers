package path;

import jason.*;
import jason.asSemantics.*;
import jason.asSyntax.*;

public class update_position extends DefaultInternalAction {

    @Override
    public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
        try {
        	// Updates agents position
        	int x = (int)((NumberTerm)args[0]).solve();
        	int y = (int)((NumberTerm)args[1]).solve();
        	Navigation.getInstance(ts.getUserAgArch().getAgName()).UpdatePosition(x, y);
        }
        catch (Throwable t) {
            t.printStackTrace();
            return false;
        }
    	return true;
    }
}
