/atom/proc/get_overmap() //Helper proc to get the overmap ship representing a given area.
	RETURN_TYPE(/obj/structure/overmap)
	if(!z)
		if(!loc)
			return FALSE
		return loc.get_overmap()
	if(isovermap(loc))
		return loc
	var/datum/space_level/SL = SSmapping.z_list[z]
	if(SL?.linked_overmap)
		return SL.linked_overmap
	var/area/AR = get_area(src)
	return AR.overmap_fallback

/obj/structure/overmap/get_overmap()
	var/obj/structure/overmap/save_overmap = last_overmap
	last_overmap = ..()
	if(!last_overmap && save_overmap?.roomReservation && SSmapping.level_trait(z, ZTRAIT_RESERVED))
		last_overmap = save_overmap // Hack because the space turfs in asteroid templates end up in area space instead of the asteroid's area
	last_overmap?.overmaps_in_ship += src
	return last_overmap

/**
Helper method to get what ship an observer belongs to for stuff like parallax.
*/

/mob/proc/find_overmap()
	var/obj/structure/overmap/OM = loc.get_overmap() //Accounts for things like fighters and for being in nullspace because having no loc is bad.
	if(OM == last_overmap)
		return
	if(last_overmap)
		last_overmap.mobs_in_ship -= src
	last_overmap = OM
	OM?.mobs_in_ship += src

/// Finds a turf outside of the overmap
/proc/GetSafeLoc(atom/A)
	if ( !A ) // play stupid games win stupid prizes
		return
	if(!SSmapping.level_trait(A.z, ZTRAIT_OVERMAP))
		return A

	var/max = world.maxx - TRANSITIONEDGE
	var/min = TRANSITIONEDGE + 1
	var/list/possible_transitions = SSmapping.levels_by_trait(ZTRAIT_STATION)
	var/_z = pick(possible_transitions)
	var/_x
	var/_y
	switch(A.dir)
		if(SOUTH)
			_x = rand(min,max)
			_y = max
		if(WEST)
			_x = max
			_y = rand(min,max)
		if(EAST)
			_x = min
			_y = rand(min,max)
		else
			_x = rand(min,max)
			_y = min
	return locate(_x, _y, _z) //Where are we putting you

/**
A more accurate get_dist, that takes into account the looping edges of the overmap.  
[Here's the algorithm in desmos](https://www.desmos.com/calculator/6akddpjzio)
*/

/proc/overmap_dist(atom/A,atom/B)
	if (!A || !B)
		return 0
	var/TX = (world.maxx / 2) - (TRANSITIONEDGE + 1)
	var/TY = (world.maxy / 2) - (TRANSITIONEDGE + 1)
	var/CX = A.x - B.x
	var/CY = A.y - B.y
	if (CX < -TX)
		CX = ((-CX % TX) - TX)
	else if (CX > TX)
		CX = (TX - (CX % TX))
	
	if (CY < -TY)
		CY = ((-CY % TY) - TY)
	else if (CY > TY)
		CY = (TY - (CY % TY))
	
	return sqrt(CX**2 + CY**2)

/**
Another get_angle that works better with the looping edges of the overmap
*/

/proc/overmap_angle(atom/A,atom/B)
	if (!A || !B)
		return 0
	var/TX = (world.maxx / 2) - (TRANSITIONEDGE + 1)
	var/TY = (world.maxy / 2) - (TRANSITIONEDGE + 1)
	var/CX = A.x - B.x//most of this is copied from the above proc
	var/CY = A.y - B.y
	if (CX < -TX)
		CX = ((-CX % TX) - TX)
	else if (CX > TX)
		CX = (TX - (CX % TX))
	else 
		CX = -CX
	
	if (CY < -TY)
		CY = ((-CY % TY) - TY)
	else if (CY > TY)
		CY = (TY - (CY % TY))
	else 
		CY = -CY

	if(!CY)//straight up copied from Get_Angle
		return (CX>=0)?90:270
	.=arctan(CX/CY)
	if(CY<0)
		.+=180
	else if(CX<0)
		.+=360
