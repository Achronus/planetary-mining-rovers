package path;

import jason.*;
import jason.asSemantics.*;
import jason.asSyntax.*;

public class note_resource extends DefaultInternalAction {

    @Override
    public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
        try {
        	// Adds a resource to the agent map, letting the agent take a 'mental note' of its position
        	int x = (int)((NumberTerm)args[0]).solve();
        	int y = (int)((NumberTerm)args[1]).solve();
        	int idx = (int)((NumberTerm)args[2]).solve();
        	Navigation.getInstance(ts.getUserAgArch().getAgName()).addResource(x, y, idx);
        }
        catch (Throwable t) {
        	t.printStackTrace();
        	return false;
        }
        return true;
    }
}
