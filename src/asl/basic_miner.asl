/* Initial goals */

! initialize.

/* Plans */

/* Set initial beliefs and rules */
+! initialize : true <- 
	rover.ia.check_config(C, SR, R); // capacity, scan range, resource
	rover.ia.check_status(E); // energy
	+ energy(E);
	+ capacity(C);
	+ scan_range(SR);
	+ assigned_resource(R);
	+ gold_count(0); // deposits
	! setup_agent_map;
	! standard_movement;
	.

/* Create the agents perception of the map, updating it as the agent moves */
+! setup_agent_map: true <-
	rover.ia.get_map_size(W, H);
	path.agent_map(W, H);
	path.update_position(0, 0);
	path.note_resource(0, 0, 8); // base
	.

// Adds instances of the respective item on the agent map
// 0: normal path, 2: gold, 3: diamond, 8: base, -1: obstacle
+! update_agent_map : resource_details(Resource, _, XPos, YPos) & gold_count(GC) <-
	if (Resource == "Gold") {
		path.note_resource(XPos, YPos, 2);
		-+ gold_count(GC+1);
	}
	.
	
/* Movement Plans */
// Basic movements until resources are found
+! standard_movement : true <-
	.drop_all_intentions;
	path.get_position(X, Y);
	if (not change_direction) {
		NewX = X + 2;
		NewY = Y;
		+ change_direction;
	}
	else {
		NewX = X;
		NewY = Y - 2;
		- change_direction;
	}

	move(X - NewX, Y - NewY);
	path.update_position(X - NewX, Y - NewY);
	path.get_position(AgX, AgY);
	! scan_for_resource;
	.

// Move to resource if one has been found
+! move_to_resource : target_resource(ResX, ResY) & resource_details(Resource, Qty, _, _) <-
	.drop_all_intentions;
	+ move_to_resource;
	.print("I am moving to the ", Resource, " node (", Qty, ") again.");
	path.get_position(AgX, AgY);
	path.get_route(AgX, AgY, ResX, ResY, Route, 0);
	! follow_route(Route);
	. 

// First move to resource, stores last agent position
+! move_to_resource : first_move & resource_details(Resource, Qty, ResX, ResY) <-
	.drop_all_intentions;
	.print("I am moving to a ", Resource, " node (", Qty, ") for the first time.");
	path.get_position(AgX, AgY);
	- first_move;
	+ move_to_resource;
	path.get_route(AgX, AgY, ResX, ResY, Route, 0);
	! follow_route(Route);
	.

// Follows a route to a destination - recursively processes the list of movements
// First = first tile; Next = remainder of the list
+! follow_route([First|Next]) : true <-
	// Get the X and Y values for the first item in the list
	.nth(0, First, X);
	.nth(1, First, Y);
	
	// Get the agent position, update it and move forward
	path.get_position(AgX, AgY);
	path.get_distance(AgX, AgY, X, Y, DistanceX, DistanceY);
	move(DistanceX, DistanceY);
	path.update_position(DistanceX,  DistanceY);
	! follow_route(Next);
	.

// On resource arrival, collect it
+! follow_route([]) : move_to_resource  <-
	- move_to_resource;
    ! mine_resource.

// Once returned to base, deposit the ore
+! follow_route([]) : return_to_base  <-
    ! deposit_resource.

// Remove plan if route is empty, resetting route
-! follow_route([]) : true <- true.

// Returns to base once full on ore
+! move_to_base : true <-
	+ return_to_base;
	path.get_position(X, Y);
	path.get_route(0, 0, X, Y, Route, 1);
	! follow_route(Route);
	.

/* Action Related Plans */
+! scan_for_resource : scan_range(SR) <-
	scan(SR);
	.

/* Resource Specific Plans */
@mine_resource[atomic]
+! mine_resource : capacity(C) & assigned_resource(R) & resource_details(Resource, Qty, XPos, YPos) <- 
	.drop_all_events;
	if (Qty >= C) {
		for ( .range(I, 1, C) ) {
			collect(R);
		};
		-+ resource_details(Resource, Qty-C, XPos, YPos);
	}
	else {
		for ( .range(I, 1, Qty) ) {
			collect(R);
		};
		- resource_details;
	};
	path.get_position(GoalX, GoalY);
	+ target_resource(GoalX, GoalY);
	! move_to_base;
	.

@deposit_resource[atomic]
+! deposit_resource : capacity(C) & assigned_resource(R) & resource_details(Resource, Qty, X, Y) <- 
	for ( .range(I, 1, C) ) {
		deposit(R);
	};
	.

/* Beliefs/Percepts */

// Handle resource depletion
+ invalid_action(collect, _) : resource_details(Resource, Qty, X, Y) & gold_count(GC) <-
	- resource_details(Resource, Qty, X, Y);
	- resource_focus(Resource, Qty, X, Y);
	- move_to_resource;
	- target_resource(X, Y);
	path.note_resource(X, Y, 0);
	
	if (Resource == "Gold") {
		-+ gold_count(GC-1);
	}
	! standard_movement;
	.

// Once deposited at base, collect resource again until empty
+ action_completed(deposit) : assigned_resource(R) & resource_details(Resource, Qty, X, Y) <-
	- return_to_base;
	! move_to_resource;
	.

/* Generic resource handling */
@resource_found(_, _, _, _)[atomic]
+ resource_found(Resource, Qty, XPos, YPos) : assigned_resource(R)  <-
	+ resource_details(Resource, Qty, XPos, YPos);
	! update_agent_map;
	+ first_move;
	! move_to_resource;	
	.

// If nothing found, continue moving
+ resource_not_found : true <-
	.drop_all_intentions;
	! standard_movement;
	.
	
