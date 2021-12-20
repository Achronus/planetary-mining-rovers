/* Initial goals */

! initialize.

/* Plans */

/* Set initial beliefs and rules */
+! initialize : true <- 
	rover.ia.check_config(C, _, R); // capacity, scan range, resource
	rover.ia.check_status(E); // energy
	+ energy(E);
	+ capacity(C);
	+ resource_type(R);
	+ carrying(0);
	+ assigned_count(0);
	path.get_position(X, Y);
	+ base_position(X, Y);
	! setup_agent_map;
	.

/* Agent Map Related Plans */
// Create the agents perception of the map
// Index - 0: normal path, 2: gold, 3: diamond, 8: base
+! setup_agent_map: true <-
	rover.ia.get_map_size(W, H);
	path.agent_map(W, H);
	+ map_size(W, H);
	path.update_position(0, 0);
	path.note_resource(0, 0, 8); // base
	.print("Waiting for scanners to finish scanning quadrants.");
	.

/* Movement to Resource or Base Plans */
// Focus on resource until depleted
+! move_to_resource : target_resource(ResX, ResY) & assigned_resource(Resource, Qty, _, _, Route, RouteHome) <-
	.drop_all_intentions;
	+ moving_to_resource;
	.print("I am moving to the ", Resource, " node (", Qty, ") again.");
	- target_resource(ResX, ResY);
	! follow_route(Route);
	. 

// First move to resource, stores last agent position
+! move_to_resource : first_move & assigned_resource(Resource, Qty, ResX, ResY, Route, RouteHome) <-
	.drop_all_intentions;
	.print("I am moving to a ", Resource, " node (", Qty, ") for the first time.");
	- first_move;
	+ moving_to_resource;
	! follow_route(Route);
	.

// Returns to base once full on ore
+! move_to_base : assigned_resource(Resource, Qty, ResX, ResY, Route, RouteHome) <-
	+ return_to_base;
	! follow_route(RouteHome);
	.

/* Route Specific Movement Plans (Uses A*) */
// Follows a route to a destination - recursively processes the list of movements
// First = first tile; Next = remainder of the list
@follow_route[atomic]
+! follow_route([First|Next]) : true <-
	// Get the X and Y values for the first item in the list
	.nth(0, First, X);
	.nth(1, First, Y);
	
	// Get the agent position, update it and move forward
	path.get_position(AgX, AgY);
	path.get_distance(AgX, AgY, X, Y, DistanceX, DistanceY);
	move(DistanceX, DistanceY);
	path.update_position(DistanceX,  DistanceY);
	
	// Handle obstructions
	if (obstructed(_, _, _, _)) {
		! obstructed;
	}
	else {
		! follow_route(Next);
	}
	.

// On resource arrival, collect it
+! follow_route([]) : moving_to_resource <-
    ! mine_resource.

// Once returned to base, deposit the ore
+! follow_route([]) : return_to_base <-
    ! deposit_resource.

// If there is no route, move normally
-! follow_route([]) : true <- true.

/* Agent Collision Handling */
+! follow_route(Route) : obstructed(XTravelled, YTravelled, XLeft, YLeft) <- ! obstructed.
	
-! follow_route(Route) : obstructed(XTravelled, YTravelled, XLeft, YLeft) <- ! obstructed.

+! follow_route([]) : obstructed(XTravelled, YTravelled, XLeft, YLeft) <- ! obstructed.
	
-! follow_route([]) : obstructed(XTravelled, YTravelled, XLeft, YLeft) <- ! obstructed.

// Handles collisions when following a route
+! obstructed : obstructed(XTravelled, YTravelled, XLeft, YLeft) & assigned_resource(Resource, Qty, ResX, ResY, Route, RouteHome) <- 
	.drop_all_intentions;
	.print("Oops, sorry I didn't see you there!");
	
	// Make agents move and wait
	if (NAME == diamond) 
	{
		move(0, 2);
		.wait(4000);
	}
	elif (NAME == gold) {
		move(0, -2);
		.wait(2000);
	}
	.abolish(obstructed(XTravelled, YTravelled, XLeft, YLeft));
	// Reconfigure route and continue on moving
	path.get_position(AgX, AgY);
	path.get_route(AgX, AgY, ResX-AgX, ResY-AgY, NewRoute, 0);
	path.get_route(0, 0, ResX, ResY, NewRouteHome, 1);
	
	-+ assigned_resource(Resource, Qty, ResX, ResY, NewRoute, NewRouteHome)
	if (return_to_base) {
		! move_to_base;
	}
	elif (first_move | moving_to_resource) {
		+ target_resource(ResX, ResY);
		! move_to_resource;
	}
	.

// Ignore obstructed fails
-! obstructed: true <- true.

/* Resource Specific Plans */
@mine_resource[atomic]
+! mine_resource : capacity(C) & resource_type(R) & assigned_resource(Resource, Qty, XPos, YPos, Route, RouteHome) <- 
	.drop_all_events;
	- moving_to_resource;
	if (Qty >= C) {
		for ( .range(I, 1, C) ) {
			collect(R);
		};
		-+ assigned_resource(Resource, Qty-C, XPos, YPos, Route, RouteHome);
		-+ carrying(C);
	}
	else {
		for ( .range(I, 1, Qty) ) {
			collect(R);
		};
		Mined = Qty;
		-+ carrying(Mined);
		-+ assigned_resource(Resource, Qty-Mined, XPos, YPos, Route, RouteHome);
		.print("Resource depleted. Returning to base with ", Mined, " ", Resource, ".");
	};
	path.get_position(GoalX, GoalY);
	+ target_resource(GoalX, GoalY);
	! move_to_base;
	.

@deposit_resource[atomic]
+! deposit_resource : carrying(C) & resource_type(R) & assigned_resource(Resource, Qty, ResX, ResY, Route, RouteHome) <- 
	for ( .range(I, 1, C) ) {
		deposit(R);
	};
	-+ carrying(0);
	.

// Wait for scanners to finish finding resources then start mining
+! start_mining : mining_check1 & mining_check2 <-
	.print("Beginning mining.");
	.my_name(NAME);
	+ assign_resource;
	! handle_resource;
	.

/* Handle Resource Plans */
// Assigns a single resource from available resources
+! handle_resource : assign_resource & assigned_count(AC) & available_resource(Resource, Qty, XPos, YPos, Route, RouteHome) <-	
	- assign_resource;
	if (AC == 0) {
		// Assign a resource
		! handle_resource(Resource, Qty, XPos, YPos, Route, RouteHome);
	}
	.

// Assigns a resource for mining
@handle_resource[atomic]
+! handle_resource(Resource, Qty, ResX, ResY, Route, RouteHome) : assigned_count(AC) <-
	-+ assigned_count(AC+1);
	+ assigned_resource(Resource, Qty, ResX, ResY, Route, RouteHome);
	.abolish(available_resource(Resource, Qty, ResX, ResY, Route, RouteHome));
	+ first_move;
	! move_to_resource;
	. 

// Ignore invalid resource assignments - miner has completed task
-! handle_resource : true <- 
	.print("Task complete.");
	.

/* Beliefs/Percepts */
// Once deposited at base, collect resource again until empty
@action_completed(deposit)[atomic]
+ action_completed(deposit) : resource_type(R) & assigned_resource(Resource, Qty, X, Y, Route, RouteHome) <-
	- return_to_base;
	if (Qty == 0) {
		// Remove assigned and targeted resource
		- target_resource(X, Y);
		-+ assigned_count(0);
		path.note_resource(X, Y, 0);
		
		// Assign a new resource
		- assigned_resource(Resource, Qty, X, Y, Route, RouteHome);
		+ assign_resource;
		! handle_resource;
	}
	else {
		! move_to_resource;	
	}
	.

// Ignore invalid collections
- invalid_action(collect, _) : true <- true.

/* Communicated Beliefs */
// Store resources that the scanners have found in the Belief Base
+ available_resource(Resource, Qty, XPos, YPos, Route, RouteHome): true <- true.

// Scanner 1 cleared quadrant for mining
+ begin_mining[source(scan1)] : true <-
	+ mining_check1;
	
	// Start mining if both checks achieved
	if (mining_check1 & mining_check2) {
		! start_mining;
	}
	.

// Scanner 2 cleared quadrant for mining
+ begin_mining[source(scan2)] : true <-
	+ mining_check2;
	
	// Start mining if both checks achieved
	if (mining_check1 & mining_check2) {
		! start_mining;
	}
	.

// Handle agent obstructions
+ obstructed(XTravelled, YTravelled, XLeft, YLeft) <- ! obstructed.
