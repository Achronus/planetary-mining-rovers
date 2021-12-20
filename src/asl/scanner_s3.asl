/* Initial goals */

! initialize.

/* Plans */

/* Set initial beliefs and rules */
+! initialize : true <- 
	rover.ia.check_config(_, SR, _); // capacity, scan range, resource
	rover.ia.check_status(E); // energy
	+ energy(E);
	+ scan_range(SR);
	+ gold_count(0); // deposits
	+ diamond_count(0); // deposits
	+ x_distance_moved(0);
	+ found_count(0);
	+ agent_count(2); // used for quadrants
	+ move_range(5);
	+ move_laps(3);
	+ power_threshold(200);
	path.get_position(X, Y);
	+ base_position(X, Y);
	! setup_agent_map;
	! assign_quadrants;
	.

/* Agent Map Related Plans */
// Create the agents perception of the map
// Index - 0: normal path, 2: gold, 3: diamond, 8: base
+! setup_agent_map: agent_count(AC) & move_range(MR) <-
	rover.ia.get_map_size(W, H);
	path.agent_map(W, H);
	+ map_size(W, H);
	path.update_position(0, 0);
	path.note_resource(0, 0, 8); // base
	.

/* Agent Quadrant Allocation */
// Retrieves the quadrants based on number of agents
+! assign_quadrants : agent_count(AC) <-
	path.get_quadrants(AC, QuadBounds);
	! assign_quadrants(QuadBounds);
	.

// Assigns an agent to a specific part of the map
+! assign_quadrants(QuadBounds) : true <-
	// Get lists separate for agents
	.nth(0, QuadBounds, Q1);
	.nth(1, QuadBounds, Q2);
	
	// Assign quadrants
	.my_name(NAME);
	if (NAME == scan1) {
		.nth(0, Q1, LB);
		.nth(1, Q1, UB);
		+ quadrant(LB, UB);
	}
	elif (NAME == scan2) {
		.nth(0, Q2, LB);
		.nth(1, Q2, UB);
		+ quadrant(LB, UB);
	}
	! move_to_quadrant;
	.

// Moves agents to their quadrant
@move_to_quadrant[atomic]
+! move_to_quadrant : quadrant(LB, UB) & scan_range(SR) <-
	path.get_position(AgX, AgY);
	.my_name(NAME);
	if (NAME == scan1) {
		path.get_route(AgX, AgY, AgX, LB+SR, Route, 0);
	}
	elif (NAME == scan2) {
		path.get_route(AgX, AgY, AgX, UB-SR, Route, 0);
	}
	! follow_route(Route);
	! scan_for_resource;
	.

/* Standard Movement Plans */
// Sweeps across quadrant until resources are found
@standard_movement[atomic]
+! standard_movement : x_distance_moved(MX) & move_range(MR) & move_laps(L) & power_threshold(PT) <-
	.drop_all_intentions;
	rover.ia.get_map_size(W, _);
	path.get_position(X, Y);
	rover.ia.check_status(Energy);	
	
	// Once moved the full width distance, change direction
	if (MX >= W) {
		+ change_direction;
		-+ x_distance_moved(0);
		-+ move_laps(L-1);
	}
	
	// Stop searching if scanned quadrant fully
	if (L == 0) {
		.print("Finished scanning quadrant. Returning to base.");
		! move_to_base;
		+ begin_mining;
	}
	elif (Energy <= PT) {
		.print("Low on power, returning to base.");
		! move_to_base;
		+ begin_mining;
	}
	else {
		.my_name(NAME);
		// Move around normally
		if (NAME == scan1) {
			if (not change_direction) {
				NewX = X + MR;
				NewY = Y;
				-+ x_distance_moved(MX + MR);
			}
			else {
				NewX = X;
				NewY = Y - MR;
				- change_direction;
			}
		}
		elif (NAME == scan2) {
			if (not change_direction) {
				NewX = X - MR;
				NewY = Y;
				-+ x_distance_moved(MX + MR);
			}
			else {
				NewX = X;
				NewY = Y + MR;
				- change_direction;
			}
		}
		move(X - NewX, Y - NewY);
		path.update_position(X - NewX, Y - NewY);
		! scan_for_resource;	
	}
	.

// Returns to base
+! move_to_base : true <-
	path.get_position(X, Y);
	path.get_route(0, 0, X, Y, Route, 1);
	! follow_route(Route);
	.

/* Route Specific Movement Plans (Uses A*) */
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

// If there is no route, move normally
-! follow_route([]) : true <- true.

// Scan for a resource
+! scan_for_resource : scan_range(SR) <-
	scan(SR);
	.

/* Handle Resource Plans */
// Recursively call handle resource until no more found
+! handle_resource(Resource, Qty, XPos, YPos) : sort_resources & found_count(FC) <-	
	- sort_resources;
	// Move as normal
	if (FC == 0) {
		! standard_movement;
	}
	// Sort the resource and assign to miner
	else {
		! handle_resource(Resource, Qty, XPos, YPos);
	}
	.

// Processes found resources
@handle_resource[atomic]
+! handle_resource(Resource, Qty, XPos, YPos) : gold_count(GC) & diamond_count(DC) & found_count(FC) & map_size(W, H) <-
	// Set resource positions relative to scanner agents
	path.get_position(AgX, AgY);
	path.modulus((AgX + XPos), W, ResX);
	path.modulus((AgY + YPos), H, ResY);

	// Ignore resources that have already been found
	if (not sent_details(Resource, ResX, ResY, Route, RouteHome)) {
		// Update the map for each resource found
		if (Resource == "Gold") {
			path.note_resource(ResX, ResY, 2);
			-+ gold_count(GC+1);
			.print("Found ", Resource, " at [", ResX, ", ", ResY, "].");
		}
		elif (Resource == "Diamond") {
			path.note_resource(ResX, ResY, 3);
			-+ diamond_count(DC+1);
			.print("Found ", Resource, " at [", ResX, ", ", ResY, "].");
		}
		
		// Get miners routes
		path.get_route(0, 0, ResX, ResY, Route, 0); // To resource
		path.get_route(0, 0, ResX, ResY, RouteHome, 1); // To base
		+ available_resource(Resource, Qty, ResX, ResY, Route, RouteHome);
		
		// Tell miners the resources that are available
		if (Resource == "Gold") {
			.send(gold, tell, available_resource(Resource, Qty, ResX, ResY, Route, RouteHome));
		}
		elif (Resource == "Diamond") {
			.send(diamond, tell, available_resource(Resource, Qty, ResX, ResY, Route, RouteHome));
		};
		+ sent_details(Resource, ResX, ResY, Route, RouteHome);
		- available_resource(Resource, Qty, ResX, ResY, Route, RouteHome);
	}
	-+ found_count(FC-1);
	+ sort_resources;
	- resource_found(Resource, Qty, ResX, ResY);
	! handle_resource(Resource, Qty, XPos, YPos);
	. 

/* Beliefs/Percepts */
// Informs miners to begin mining
+ begin_mining[source(self)] : true  <-
	.drop_all_intentions;
	.print("Successfully returned to base.");
	.broadcast(tell, begin_mining);
	.

/* Generic Resource Handling */
// Count found resources and move onto processing them
+ resource_found(Resource, Qty, XPos, YPos) : found_count(FC) <-
	.count(resource_found(_, _, _, _), FoundCount);
	-+ found_count(FC+FoundCount);
	+ sort_resources;
	! handle_resource(Resource, Qty, XPos, YPos);
	.

// If nothing found, continue moving
+ resource_not_found : true <-
	.drop_all_intentions;
	! standard_movement;
	.
