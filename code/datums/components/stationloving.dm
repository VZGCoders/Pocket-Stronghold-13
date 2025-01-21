/datum/component/stationloving
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	var/inform_admins = FALSE
	var/disallow_soul_imbue = TRUE
	var/allow_death = FALSE

/datum/component/stationloving/Initialize(inform_admins = FALSE, allow_death = FALSE)
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, list(COMSIG_MOVABLE_SECLUDED_LOCATION), PROC_REF(relocate))
	RegisterSignal(parent, list(COMSIG_PARENT_PREQDELETED), PROC_REF(check_deletion))
	RegisterSignal(parent, list(COMSIG_ITEM_IMBUE_SOUL), PROC_REF(check_soul_imbue))
	RegisterSignal(parent, list(COMSIG_ITEM_MARK_RETRIEVAL), PROC_REF(check_mark_retrieval))
	src.inform_admins = inform_admins
	src.allow_death = allow_death

/datum/component/stationloving/InheritComponent(datum/component/stationloving/newc, original, inform_admins, allow_death)
	if (original)
		if (newc)
			inform_admins = newc.inform_admins
			allow_death = newc.allow_death
		else
			inform_admins = inform_admins

/datum/component/stationloving/proc/relocate()
	SIGNAL_HANDLER

	var/targetturf = find_safe_turf()
	if(!targetturf)
		if(GLOB.blobstart.len > 0)
			targetturf = get_turf(pick(GLOB.blobstart))
		else
			CRASH("Unable to find a blobstart landmark")

	var/atom/movable/AM = parent
	playsound(AM, 'sound/machines/synth_no.ogg', 5, TRUE) //hey dumbass, you failed at your MOST IMPORTANT JOB, maybe you should check your chat log to see what could have caused that strange buzzing noise
	AM.forceMove(targetturf)
	to_chat(get(parent, /mob), span_danger("You can't help but feel that you just lost something back there..."))
	// move the disc, so ghosts remain orbiting it even if it's "destroyed"
	return targetturf

/datum/component/stationloving/proc/check_soul_imbue()
	SIGNAL_HANDLER

	return disallow_soul_imbue

/datum/component/stationloving/proc/check_mark_retrieval()
	SIGNAL_HANDLER

	return COMPONENT_BLOCK_MARK_RETRIEVAL

/datum/component/stationloving/proc/check_deletion(datum/source, force) // TRUE = interrupt deletion, FALSE = proceed with deletion

	SIGNAL_HANDLER


	var/turf/T = get_turf(parent)

	if(inform_admins && force)
		message_admins("[parent] has been !!force deleted!! in [ADMIN_VERBOSEJMP(T)].")
		log_game("[parent] has been !!force deleted!! in [loc_name(T)].")

	if(!force && !allow_death)
		var/turf/targetturf = relocate()
		log_game("[parent] has been destroyed in [loc_name(T)]. Moving it to [loc_name(targetturf)].")
		if(inform_admins)
			message_admins("[parent] has been destroyed in [ADMIN_VERBOSEJMP(T)]. Moving it to [ADMIN_VERBOSEJMP(targetturf)].")
		return TRUE
	return FALSE
