/client/proc/Debug2()
	set category = "Debug"
	set name = "Debug-Game"
	if(!check_rights(R_DEBUG))
		return

	if(GLOB.Debug2)
		GLOB.Debug2 = 0
		message_admins("[key_name(src)] toggled debugging off.")
		log_admin("[key_name(src)] toggled debugging off.")
	else
		GLOB.Debug2 = 1
		message_admins("[key_name(src)] toggled debugging on.")
		log_admin("[key_name(src)] toggled debugging on.")

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Toggle Debug Two") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!



/* 21st Sept 2010
Updated by Skie -- Still not perfect but better!
Stuff you can't do:
Call proc /mob/proc/Dizzy() for some player
Because if you select a player mob as owner it tries to do the proc for
/mob/living/carbon/human/ instead. And that gives a run-time error.
But you can call procs that are of type /mob/living/carbon/human/proc/ for that player.
*/

/client/proc/cmd_admin_animalize(mob/M in GLOB.mob_list)
	set category = "Admin.Fun"
	set name = "Make Simple Animal"

	if(!SSticker.HasRoundStarted())
		tgui_alert(usr,"Wait until the game starts")
		return

	if(!M)
		tgui_alert(usr,"That mob doesn't seem to exist, close the panel and try again.")
		return

	if(isnewplayer(M))
		tgui_alert(usr,"The mob must not be a new_player.")
		return

	log_admin("[key_name(src)] has animalized [M.key].")
	INVOKE_ASYNC(M, TYPE_PROC_REF(/mob, Animalize))

//TODO: merge the vievars version into this or something maybe mayhaps
/client/proc/cmd_debug_del_all_wrapper()
	set category = "Debug"
	set name = "Del-All"

	var/msg = input(src, null, "Del-All") as text|null
	if(msg)
		cmd_debug_del_all(msg)

/client/proc/cmd_debug_del_all(object as text)
	set name = "Del-All"

	var/list/matches = get_fancy_list_of_atom_types()
	if (!isnull(object) && object!="")
		matches = filter_fancy_list(matches, object)

	if(matches.len==0)
		return
	var/hsbitem = input(usr, "Choose an object to delete.", "Delete:") as null|anything in sort_list(matches)
	if(hsbitem)
		hsbitem = matches[hsbitem]
		var/counter = 0
		for(var/atom/O in world)
			if(istype(O, hsbitem))
				counter++
				qdel(O)
			CHECK_TICK
		log_admin("[key_name(src)] has deleted all ([counter]) instances of [hsbitem].")
		message_admins("[key_name_admin(src)] has deleted all ([counter]) instances of [hsbitem].")
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Delete All") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_assume_direct_control(mob/M in GLOB.mob_list)
	set category = "Admin.Game"
	set name = "Assume direct control"
	set desc = "Direct intervention"

	if(M.ckey)
		if(tgui_alert(usr,"This mob is being controlled by [M.key]. Are you sure you wish to assume control of it? [M.key] will be made a ghost.",,list("Yes","No")) != "Yes")
			return
	if(!M || QDELETED(M))
		to_chat(usr, span_warning("The target mob no longer exists."))
		return
	message_admins(span_adminnotice("[key_name_admin(usr)] assumed direct control of [M]."))
	log_admin("[key_name(usr)] assumed direct control of [M].")
	var/mob/adminmob = mob
	if(M.ckey)
		M.ghostize(FALSE)
	M.ckey = ckey
	init_verbs()
	if(isobserver(adminmob))
		qdel(adminmob)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Assume Direct Control") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_give_direct_control(mob/M in GLOB.mob_list)
	set category = "Admin.Game"
	set name = "Give direct control"

	if(!M)
		return
	if(M.ckey)
		if(tgui_alert(usr,"This mob is being controlled by [M.key]. Are you sure you wish to give someone else control of it? [M.key] will be made a ghost.",,list("Yes","No")) != "Yes")
			return
	var/client/newkey = input(src, "Pick the player to put in control.", "New player") as null|anything in sort_list(GLOB.clients)
	var/mob/oldmob = newkey.mob
	var/delmob = FALSE
	if((isobserver(oldmob) || tgui_alert(usr,"Do you want to delete [newkey]'s old mob?","Delete?",list("Yes","No")) != "No"))
		delmob = TRUE
	if(!M || QDELETED(M))
		to_chat(usr, span_warning("The target mob no longer exists, aborting."))
		return
	if(M.ckey)
		M.ghostize(FALSE)
	M.ckey = newkey.key
	M.client?.init_verbs()
	if(delmob)
		qdel(oldmob)
	message_admins(span_adminnotice("[key_name_admin(usr)] gave away direct control of [M] to [newkey]."))
	log_admin("[key_name(usr)] gave away direct control of [M] to [newkey].")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Give Direct Control") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/robust_dress_shop()

	var/list/baseoutfits = list("Naked", "Custom")
	var/list/outfits = list()
	var/list/paths = subtypesof(/datum/outfit)

	for(var/path in paths)
		var/datum/outfit/O = path //not much to initalize here but whatever
		if(initial(O.can_be_admin_equipped))
			outfits[initial(O.name)] = path

	var/dresscode = input("Select outfit", "Robust quick dress shop") as null|anything in baseoutfits + sort_list(outfits)
	if (isnull(dresscode))
		return

	if (outfits[dresscode])
		dresscode = outfits[dresscode]

	if (dresscode == "Custom")
		var/list/custom_names = list()
		for(var/datum/outfit/D in GLOB.custom_outfits)
			custom_names[D.name] = D
		var/selected_name = input("Select outfit", "Robust quick dress shop") as null|anything in sort_list(custom_names)
		dresscode = custom_names[selected_name]
		if(isnull(dresscode))
			return

	return dresscode

/client/proc/cmd_debug_mob_lists()
	set category = "Debug"
	set name = "Debug Mob Lists"
	set desc = "For when you just gotta know"

	switch(tgui_input_list(usr, "Which list?",, list("Players","Admins","Mobs","Living Mobs","Dead Mobs","Clients","Joined Clients")))
		if("Players")
			to_chat(usr, jointext(GLOB.player_list,","), confidential = TRUE)
		if("Admins")
			to_chat(usr, jointext(GLOB.admins,","), confidential = TRUE)
		if("Mobs")
			to_chat(usr, jointext(GLOB.mob_list,","), confidential = TRUE)
		if("Living Mobs")
			to_chat(usr, jointext(GLOB.alive_mob_list,","), confidential = TRUE)
		if("Dead Mobs")
			to_chat(usr, jointext(GLOB.dead_mob_list,","), confidential = TRUE)
		if("Clients")
			to_chat(usr, jointext(GLOB.clients,","), confidential = TRUE)
		if("Joined Clients")
			to_chat(usr, jointext(GLOB.joined_player_list,","), confidential = TRUE)

/client/proc/cmd_display_del_log()
	set category = "Debug"
	set name = "Display del() Log"
	set desc = "Display del's log of everything that's passed through it."

	var/list/dellog = list("<B>List of things that have gone through qdel this round</B><BR><BR><ol>")
	sortTim(SSgarbage.items, cmp=/proc/cmp_qdel_item_time, associative = TRUE)
	for(var/path in SSgarbage.items)
		var/datum/qdel_item/I = SSgarbage.items[path]
		dellog += "<li><u>[path]</u><ul>"
		if (I.failures)
			dellog += "<li>Failures: [I.failures]</li>"
		dellog += "<li>qdel() Count: [I.qdels]</li>"
		dellog += "<li>Destroy() Cost: [I.destroy_time]ms</li>"
		if (I.hard_deletes)
			dellog += "<li>Total Hard Deletes [I.hard_deletes]</li>"
			dellog += "<li>Time Spent Hard Deleting: [I.hard_delete_time]ms</li>"
		if (I.slept_destroy)
			dellog += "<li>Sleeps: [I.slept_destroy]</li>"
		if (I.no_respect_force)
			dellog += "<li>Ignored force: [I.no_respect_force]</li>"
		if (I.no_hint)
			dellog += "<li>No hint: [I.no_hint]</li>"
		dellog += "</ul></li>"

	dellog += "</ol>"

	usr << browse(dellog.Join(), "window=dellog")

/client/proc/cmd_display_overlay_log()
	set category = "Debug"
	set name = "Display overlay Log"
	set desc = "Display SSoverlays log of everything that's passed through it."

	render_stats(SSoverlays.stats, src)

/client/proc/cmd_display_init_log()
	set category = "Debug"
	set name = "Display Initialize() Log"
	set desc = "Displays a list of things that didn't handle Initialize() properly"

	usr << browse(replacetext(SSatoms.InitLog(), "\n", "<br>"), "window=initlog")

/client/proc/debug_huds_wrapper()
	set category = "Debug"
	set name = "Debug HUDs"
	set desc = "Debug the data or antag HUDs"

	var/msg = input(src, null, "Debug HUDs") as num|null
	if(msg)
		debug_huds(msg)

/client/proc/debug_huds(i as num)
	set name = "Debug HUDs"

	if(!holder)
		return
	debug_variables(GLOB.huds[i])

/client/proc/toggle_medal_disable()
	set category = "Debug"
	set name = "Toggle Medal Disable"
	set desc = "Toggles the safety lock on trying to contact the medal hub."

	if(!check_rights(R_DEBUG))
		return

	SSachievements.achievements_enabled = !SSachievements.achievements_enabled

	message_admins(span_adminnotice("[key_name_admin(src)] [SSachievements.achievements_enabled ? "disabled" : "enabled"] the medal hub lockout."))
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Toggle Medal Disable") // If...
	log_admin("[key_name(src)] [SSachievements.achievements_enabled ? "disabled" : "enabled"] the medal hub lockout.")

/client/proc/view_runtimes()
	set category = "Debug"
	set name = "View Runtimes"
	set desc = "Open the runtime Viewer"

	if(!holder)
		return

	GLOB.error_cache.show_to(src)

/client/proc/pump_random_event()
	set category = "Debug"
	set name = "Pump Random Event"
	set desc = "Schedules the event subsystem to fire a new random event immediately. Some events may fire without notification."
	if(!holder)
		return

	SSevents.scheduled = world.time

	message_admins(span_adminnotice("[key_name_admin(src)] pumped a random event."))
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Pump Random Event")
	log_admin("[key_name(src)] pumped a random event.")

/client/proc/start_line_profiling()
	set category = "Profile"
	set name = "Start Line Profiling"
	set desc = "Starts tracking line by line profiling for code lines that support it"

	LINE_PROFILE_START

	message_admins(span_adminnotice("[key_name_admin(src)] started line by line profiling."))
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Start Line Profiling")
	log_admin("[key_name(src)] started line by line profiling.")

/client/proc/stop_line_profiling()
	set category = "Profile"
	set name = "Stops Line Profiling"
	set desc = "Stops tracking line by line profiling for code lines that support it"

	LINE_PROFILE_STOP

	message_admins(span_adminnotice("[key_name_admin(src)] stopped line by line profiling."))
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Stop Line Profiling")
	log_admin("[key_name(src)] stopped line by line profiling.")

/client/proc/show_line_profiling()
	set category = "Profile"
	set name = "Show Line Profiling"
	set desc = "Shows tracked profiling info from code lines that support it"

	var/sortlist = list(
		"Avg time"		=	/proc/cmp_profile_avg_time_dsc,
		"Total Time"	=	/proc/cmp_profile_time_dsc,
		"Call Count"	=	/proc/cmp_profile_count_dsc
	)
	var/sort = input(src, "Sort type?", "Sort Type", "Avg time") as null|anything in sortlist
	if (!sort)
		return
	sort = sortlist[sort]
	profile_show(src, sort)

/client/proc/reload_configuration()
	set category = "Debug"
	set name = "Reload Configuration"
	set desc = "Force config reload to world default"
	if(!check_rights(R_DEBUG))
		return
	if(tgui_alert(usr, "Are you absolutely sure you want to reload the configuration from the default path on the disk, wiping any in-round modificatoins?", "Really reset?", list("No", "Yes")) == "Yes")
		config.admin_reload()

/// A debug verb to check the sources of currently running timers
/client/proc/check_timer_sources()
	set category = "Debug"
	set name = "Check Timer Sources"
	set desc = "Checks the sources of the running timers"
	if (!check_rights(R_DEBUG))
		return

	var/bucket_list_output = generate_timer_source_output(SStimer.bucket_list)
	var/second_queue = generate_timer_source_output(SStimer.second_queue)

	usr << browse({"
		<h3>bucket_list</h3>
		[bucket_list_output]

		<h3>second_queue</h3>
		[second_queue]
	"}, "window=check_timer_sources;size=700x700")

/proc/generate_timer_source_output(list/datum/timedevent/events)
	var/list/per_source = list()

	// Collate all events and figure out what sources are creating the most
	for (var/_event in events)
		if (!_event)
			continue
		var/datum/timedevent/event = _event

		do
			if (event.source)
				if (per_source[event.source] == null)
					per_source[event.source] = 1
				else
					per_source[event.source] += 1
			event = event.next
		while (event && event != _event)

	// Now, sort them in order
	var/list/sorted = list()
	for (var/source in per_source)
		sorted += list(list("source" = source, "count" = per_source[source]))
	sorted = sortTim(sorted, PROC_REF(cmp_timer_data))

	// Now that everything is sorted, compile them into an HTML output
	var/output = "<table border='1'>"

	for (var/_timer_data in sorted)
		var/list/timer_data = _timer_data
		output += {"<tr>
			<td><b>[timer_data["source"]]</b></td>
			<td>[timer_data["count"]]</td>
		</tr>"}

	output += "</table>"

	return output

/proc/cmp_timer_data(list/a, list/b)
	return b["count"] - a["count"]

#ifdef TESTING
/client/proc/check_missing_sprites()
	set category = "Debug"
	set name = "Debug Worn Item Sprites"
	set desc = "We're cancelling the Spritemageddon. (This will create a LOT of runtimes! Don't use on a live server!)"
	var/actual_file_name
	for(var/test_obj in subtypesof(/obj/item))
		var/obj/item/sprite = new test_obj
		if(!sprite.slot_flags || (sprite.item_flags & ABSTRACT))
			continue
		//Is there an explicit worn_icon to pick against the worn_icon_state? Easy street expected behavior.
		if(sprite.worn_icon)
			if(!(sprite.icon_state in icon_states(sprite.worn_icon)))
				to_chat(src, span_warning("ERROR sprites for [sprite.type]. Slot Flags are [sprite.slot_flags].") , confidential = TRUE)
		else if(sprite.worn_icon_state)
			if(sprite.slot_flags & ITEM_SLOT_MASK)
				actual_file_name = 'icons/mob/clothing/mask.dmi'
				if(!(sprite.worn_icon_state in icon_states(actual_file_name)))
					to_chat(src, span_warning("ERROR sprites for [sprite.type]. Mask slot.") , confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_NECK)
				actual_file_name = 'icons/mob/clothing/neck.dmi'
				if(!(sprite.worn_icon_state in icon_states(actual_file_name)))
					to_chat(src, span_warning("ERROR sprites for [sprite.type]. Neck slot.") , confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_BACK)
				actual_file_name = 'icons/mob/clothing/back.dmi'
				if(!(sprite.worn_icon_state in icon_states(actual_file_name)))
					to_chat(src, span_warning("ERROR sprites for [sprite.type]. Back slot.") , confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_HEAD)
				actual_file_name = 'icons/mob/clothing/head.dmi'
				if(!(sprite.worn_icon_state in icon_states(actual_file_name)))
					to_chat(src, span_warning("ERROR sprites for [sprite.type]. Head slot.") , confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_BELT)
				actual_file_name = 'icons/mob/clothing/belt.dmi'
				if(!(sprite.worn_icon_state in icon_states(actual_file_name)))
					to_chat(src, span_warning("ERROR sprites for [sprite.type]. Belt slot.") , confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_SUITSTORE)
				actual_file_name = 'icons/mob/clothing/belt_mirror.dmi'
				if(!(sprite.worn_icon_state in icon_states(actual_file_name)))
					to_chat(src, span_warning("ERROR sprites for [sprite.type]. Suit Storage slot.") , confidential = TRUE)
		else if(sprite.icon_state)
			if(sprite.slot_flags & ITEM_SLOT_MASK)
				actual_file_name = 'icons/mob/clothing/mask.dmi'
				if(!(sprite.icon_state in icon_states(actual_file_name)))
					to_chat(src, span_warning("ERROR sprites for [sprite.type]. Mask slot.") , confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_NECK)
				actual_file_name = 'icons/mob/clothing/neck.dmi'
				if(!(sprite.icon_state in icon_states(actual_file_name)))
					to_chat(src, span_warning("ERROR sprites for [sprite.type]. Neck slot.") , confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_BACK)
				actual_file_name = 'icons/mob/clothing/back.dmi'
				if(!(sprite.icon_state in icon_states(actual_file_name)))
					to_chat(src, span_warning("ERROR sprites for [sprite.type]. Back slot.") , confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_HEAD)
				actual_file_name = 'icons/mob/clothing/head.dmi'
				if(!(sprite.icon_state in icon_states(actual_file_name)))
					to_chat(src, span_warning("ERROR sprites for [sprite.type]. Head slot.") , confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_BELT)
				actual_file_name = 'icons/mob/clothing/belt.dmi'
				if(!(sprite.icon_state in icon_states(actual_file_name)))
					to_chat(src, span_warning("ERROR sprites for [sprite.type]. Belt slot.") , confidential = TRUE)
			if(sprite.slot_flags & ITEM_SLOT_SUITSTORE)
				actual_file_name = 'icons/mob/clothing/belt_mirror.dmi'
				if(!(sprite.icon_state in icon_states(actual_file_name)))
					to_chat(src, span_warning("ERROR sprites for [sprite.type]. Suit Storage slot.") , confidential = TRUE)
#endif
