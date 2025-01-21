/**
 * # area
 *
 * A grouping of tiles into a logical space, mostly used by map editors
 */
/area
	name = "Area"
	icon = 'icons/turf/areas.dmi'
	icon_state = "unknown"
	layer = AREA_LAYER
	//Keeping this on the default plane, GAME_PLANE, will make area overlays fail to render on FLOOR_PLANE.
	plane = AREA_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	invisibility = INVISIBILITY_LIGHTING

	var/area_flags = VALID_TERRITORY | BLOBS_ALLOWED | UNIQUE_AREA | CULT_PERMITTED

	var/lightswitch = TRUE

	/// All beauty in this area combined, only includes indoor area.
	var/totalbeauty = 0
	/// Beauty average per open turf in the area
	var/beauty = 0
	/// If a room is too big it doesn't have beauty.
	var/beauty_threshold = 150

	/// Size of the area in open turfs, only calculated for indoors areas.
	var/areasize = 0

	/// Bonus mood for being in this area
	var/mood_bonus = 0
	/// Mood message for being here, only shows up if mood_bonus != 0
	var/mood_message = span_nicegreen("This place looks good!\n")
	/// Does the mood bonus require a trait?
	var/mood_trait

	var/ambience_volume = 15
	var/ambience_index = AMBIENCE_GENERIC
	var/list/ambientsounds
	var/list/ambigensounds
	flags_1 = CAN_BE_DIRTY_1

	///Typepath to limit the areas (subtypes included) that atoms in this area can smooth with. Used for shuttles.
	var/area/area_limited_icon_smoothing

	///This datum, if set, allows terrain generation behavior to be ran on Initialize()
	var/datum/map_generator/map_generator

	///Used to decide what kind of reverb the area makes sound have
	var/sound_environment = SOUND_ENVIRONMENT_HANGAR

	///Used to decide what the minimum time between ambience is
	var/min_ambience_cooldown = 30 SECONDS
	///Used to decide what the maximum time between ambience is
	var/max_ambience_cooldown = 90 SECONDS

	//Lighting overlay
	var/obj/effect/lighting_overlay

	var/list/air_vent_info = list()
	var/list/air_scrub_info = list()

/**
 * A list of teleport locations
 *
 * Adding a wizard area teleport list because motherfucking lag -- Urist
 * I am far too lazy to make it a proper list of areas so I'll just make it run the usual telepot routine at the start of the game
 */
GLOBAL_LIST_EMPTY(teleportlocs)

/**
 * Generate a list of turfs you can teleport to from the areas list
 *
 * Includes areas if they're not a shuttle or not not teleport or have no contents
 *
 * The chosen turf is the first item in the areas contents that is a station level
 *
 * The returned list of turfs is sorted by name
 */
/proc/process_teleport_locs()
	for(var/V in GLOB.sortedAreas)
		var/area/AR = V
		if(AR.area_flags & NOTELEPORT)
			continue
		if(GLOB.teleportlocs[AR.name])
			continue
		if (!AR.contents.len)
			continue
		var/turf/picked = AR.contents[1]
		if (picked && is_fortress_level(picked.z))
			GLOB.teleportlocs[AR.name] = AR

	sortTim(GLOB.teleportlocs, GLOBAL_PROC_REF(cmp_text_asc))

/**
 * Called when an area loads
 *
 *  Adds the item to the GLOB.areas_by_type list based on area type
 */
/area/New()
	// This interacts with the map loader, so it needs to be set immediately
	// rather than waiting for atoms to initialize.
	if (area_flags & UNIQUE_AREA)
		GLOB.areas_by_type[type] = src
	return ..()

/*
 * Initalize this area
 *
 * intializes the dynamic area lighting and also registers the area with the z level via
 * reg_in_areas_in_z
 *
 * returns INITIALIZE_HINT_LATELOAD
 */
/area/Initialize(mapload)
	icon_state = ""

	if(!ambigensounds)
		ambigensounds = GLOB.ambience_assoc[ambience_index]

	if(area_flags & AREA_USES_STARLIGHT)
		static_lighting = CONFIG_GET(flag/starlight)

	if(static_lighting)
		luminosity = 0

	. = ..()

	if(!static_lighting)
		blend_mode = BLEND_MULTIPLY

	reg_in_areas_in_z()

	update_base_lighting()

	return INITIALIZE_HINT_LATELOAD

/**
 * Sets machine power levels in the area
 */
/area/LateInitialize()
	update_beauty()

/area/proc/RunGeneration()
	if(map_generator)
		map_generator = new map_generator()
		var/list/turfs = list()
		for(var/turf/T in contents)
			turfs += T
		map_generator.generate_terrain(turfs)

/area/proc/test_gen()
	if(map_generator)
		var/list/turfs = list()
		for(var/turf/T in contents)
			turfs += T
		map_generator.generate_terrain(turfs)


/**
 * Register this area as belonging to a z level
 *
 * Ensures the item is added to the SSmapping.areas_in_z list for this z
 */
/area/proc/reg_in_areas_in_z()
	if(!length(contents))
		return
	var/list/areas_in_z = SSmapping.areas_in_z
	update_areasize()
	if(!z)
		WARNING("No z found for [src]")
		return
	if(!areas_in_z["[z]"])
		areas_in_z["[z]"] = list()
	areas_in_z["[z]"] += src

/**
 * Destroy an area and clean it up
 *
 * Removes the area from GLOB.areas_by_type and also stops it processing on SSobj
 *
 * This is despite the fact that no code appears to put it on SSobj, but
 * who am I to argue with old coders
 */
/area/Destroy()
	if(GLOB.areas_by_type[type] == src)
		GLOB.areas_by_type[type] = null
	GLOB.sortedAreas -= src
	STOP_PROCESSING(SSobj, src)
	return ..()

/**
 * Update the icon state of the area
 *
 * Im not sure what the heck this does, somethign to do with weather being able to set icon
 * states on areas?? where the heck would that even display?
 */
/area/update_icon_state()
	var/weather_icon
	for(var/V in SSweather.processing)
		var/datum/weather/W = V
		if(W.stage != END_STAGE && (src in W.impacted_areas))
			W.update_areas()
			weather_icon = TRUE
	if(!weather_icon)
		icon_state = null
	return ..()

/**
 * Call back when an atom enters an area
 *
 * Sends signals COMSIG_AREA_ENTERED and COMSIG_ENTER_AREA (to a list of atoms)
 *
 * If the area has ambience, then it plays some ambience music to the ambience channel
 */
/area/Entered(atom/movable/arrived, area/old_area)
	set waitfor = FALSE
	SEND_SIGNAL(src, COMSIG_AREA_ENTERED, arrived, old_area)
	if(!LAZYACCESS(arrived.important_recursive_contents, RECURSIVE_CONTENTS_AREA_SENSITIVE))
		return
	for(var/atom/movable/recipient as anything in arrived.important_recursive_contents[RECURSIVE_CONTENTS_AREA_SENSITIVE])
		SEND_SIGNAL(recipient, COMSIG_ENTER_AREA, src)

	if(!isliving(arrived))
		return

	var/mob/living/L = arrived
	if(!L.ckey)
		return

	//Ship ambience just loops if turned on.
	if(L.client?.prefs.toggles & SOUND_SHIP_AMBIENCE)
		SEND_SOUND(L, sound('sound/ambience/shipambience.ogg', repeat = 1, wait = 0, volume = 5, channel = CHANNEL_BUZZ))

	if(L?.client && (L.client.prefs.toggles & SOUND_AMBIENCE))
		play_ambience(L.client)

/area/proc/play_ambience(client/C)

	if(!C?.mob)
		return

	if(!C.played)
		var/sound/S = sound(pick(ambientsounds))

		S.repeat = TRUE
		S.channel = CHANNEL_AMBIENCE
		S.wait = FALSE
		S.volume = ambience_volume
		S.status = SOUND_STREAM

		SEND_SOUND(C.mob, S)

		C.played = TRUE

		spawn(30)
			var/soundLen = 30
			if(C)
				var/list/sounds_list = C.SoundQuery()

				for(var/playing_sound in sounds_list)
					var/sound/found = playing_sound
					if(found.file == S.file)
						soundLen = found.len

				addtimer(CALLBACK(src, TYPE_PROC_REF(/area/, reset_ambience_played), C), soundLen * 10)

/area/proc/reset_ambience_played(client/C)
	C?.played = FALSE

///Divides total beauty in the room by roomsize to allow us to get an average beauty per tile.
/area/proc/update_beauty()
	if(!areasize)
		beauty = 0
		return FALSE
	if(areasize >= beauty_threshold)
		beauty = 0
		return FALSE //Too big
	beauty = totalbeauty / areasize


/**
 * Called when an atom exits an area
 *
 * Sends signals COMSIG_AREA_EXITED and COMSIG_EXIT_AREA (to a list of atoms)
 */
/area/Exited(atom/movable/gone, direction)
	SEND_SIGNAL(src, COMSIG_AREA_EXITED, gone, direction)
	if(!LAZYACCESS(gone.important_recursive_contents, RECURSIVE_CONTENTS_AREA_SENSITIVE))
		return
	for(var/atom/movable/recipient as anything in gone.important_recursive_contents[RECURSIVE_CONTENTS_AREA_SENSITIVE])
		SEND_SIGNAL(recipient, COMSIG_EXIT_AREA, src)

/**
 * Setup an area (with the given name)
 *
 * Sets the area name, sets all status var's to false and adds the area to the sorted area list
 */
/area/proc/setup(a_name)
	name = a_name
	area_flags &= ~VALID_TERRITORY
	area_flags &= ~BLOBS_ALLOWED
	addSorted()
/**
 * Set the area size of the area
 *
 * This is the number of open turfs in the area contents, or FALSE if the outdoors var is set
 *
 */
/area/proc/update_areasize()
	areasize = 0
	for(var/turf/open/T in contents)
		areasize++

/**
 * Causes a runtime error
 */
/area/AllowDrop()
	CRASH("Bad op: area/AllowDrop() called")

/**
 * Causes a runtime error
 */
/area/drop_location()
	CRASH("Bad op: area/drop_location() called")

/// A hook so areas can modify the incoming args (of what??)
/area/proc/PlaceOnTopReact(list/new_baseturfs, turf/fake_turf_type, flags)
	return flags


/// Called when a living mob that spawned here, joining the round, receives the player client.
/area/proc/on_joining_game(mob/living/boarder)
	return
/// Gets an areas virtual z value. For having multiple areas on the same z-level treated mechanically as different z-levels
/area/proc/get_virtual_z(turf/T)
	return T.z

/area/get_virtual_z_level()
	return get_virtual_z(get_turf(src))
