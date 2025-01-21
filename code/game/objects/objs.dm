
/obj
	animate_movement = SLIDE_STEPS
	speech_span = SPAN_ROBOT
	var/obj_flags = CAN_BE_HIT
	var/set_obj_flags // ONLY FOR MAPPING: Sets flags from a string list, handled in Initialize. Usage: set_obj_flags = "EMAGGED;!CAN_BE_HIT" to set EMAGGED and clear CAN_BE_HIT.

	var/damtype = BRUTE
	var/atck_type = BLUNT
	var/force = 0

	/// How good a given object is at causing wounds on carbons. Higher values equal better shots at creating serious wounds.
	var/wound_bonus = 0
	/// If this attacks a human with no wound armor on the affected body part, add this to the wound mod. Some attacks may be significantly worse at wounding if there's even a slight layer of armor to absorb some of it vs bare flesh
	var/bare_wound_bonus = 0

	var/datum/armor/armor
	var/obj_integrity	//defaults to max_integrity
	var/max_integrity = 500
	var/integrity_failure = 0 //0 if we have no special broken behavior, otherwise is a percentage of at what point the obj breaks. 0.5 being 50%
	///Damage under this value will be completely ignored
	var/damage_deflection = 0

	var/resistance_flags = NONE // INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ON_FIRE | UNACIDABLE | ACID_PROOF

	/// Custom fire overlay icon
	var/custom_fire_overlay

	var/renamedByPlayer = FALSE //set when a player uses a pen on a renamable object

	var/drag_slowdown // Amont of multiplicative slowdown applied if pulled. >1 makes you slower, <1 makes you faster.

	vis_flags = VIS_INHERIT_PLANE //when this be added to vis_contents of something it inherit something.plane, important for visualisation of obj in openspace.

	var/grade = 1 // object grade value. Defaults to 1

/obj/vv_edit_var(vname, vval)
	if(vname == NAMEOF(src, obj_flags))
		if ((obj_flags & DANGEROUS_POSSESSION) && !(vval & DANGEROUS_POSSESSION))
			return FALSE
	return ..()

/obj/Initialize(mapload)
	if (islist(armor))
		armor = getArmor(arglist(armor))
	else if (!armor)
		armor = getArmor()
	else if (!istype(armor, /datum/armor))
		stack_trace("Invalid type [armor.type] found in .armor during /obj Initialize()")
	obj_integrity = max_integrity

	. = ..() //Do this after, else mat datums is mad.

	if (set_obj_flags)
		var/flagslist = splittext(set_obj_flags,";")
		var/list/string_to_objflag = GLOB.bitfields["obj_flags"]
		for (var/flag in flagslist)
			if(flag[1] == "!")
				flag = copytext(flag, length(flag[1]) + 1) // Get all but the initial !
				obj_flags &= ~string_to_objflag[flag]
			else
				obj_flags |= string_to_objflag[flag]

	if((obj_flags & ON_BLUEPRINTS) && isturf(loc))
		var/turf/T = loc
		T.add_blueprints_preround(src)

/obj/Destroy(force=FALSE)
	STOP_PROCESSING(SSobj, src) // TODO: Have a processing bitflag to reduce on unnecessary loops through the processing lists
	SStgui.close_uis(src)
	. = ..()


/obj/throw_at(atom/target, range, speed, mob/thrower, spin=1, diagonals_first = 0, datum/callback/callback, force, gentle = FALSE, quickstart = TRUE)
	. = ..()
	if(obj_flags & FROZEN)
		visible_message(span_danger("[src] shatters into a million pieces!"))
		qdel(src)

/obj/proc/can_be_unfasten_wrench(mob/user, silent) //if we can unwrench this object; returns SUCCESSFUL_UNFASTEN and FAILED_UNFASTEN, which are both TRUE, or CANT_UNFASTEN, which isn't.
	if(!(isfloorturf(loc) || istype(loc, /turf/open/indestructible)) && !anchored)
		to_chat(user, span_warning("[capitalize(src.name)] needs to be on the floor to be secured!"))
		return FAILED_UNFASTEN
	return SUCCESSFUL_UNFASTEN

/obj/proc/default_unfasten_wrench(mob/user, obj/item/I, time = 20) //try to unwrench an object in a WONDERFUL DYNAMIC WAY
	if(!(flags_1 & NODECONSTRUCT_1) && I.tool_behaviour == TOOL_WRENCH)
		var/turf/ground = get_turf(src)
		if(!anchored && ground.is_blocked_turf(exclude_mobs = TRUE, source_atom = src))
			to_chat(user, span_notice("You failed to wrench <b>[src.name]</b>."))
			return CANT_UNFASTEN
		var/can_be_unfasten = can_be_unfasten_wrench(user)
		if(!can_be_unfasten || can_be_unfasten == FAILED_UNFASTEN)
			return can_be_unfasten
		if(time)
			to_chat(user, span_notice("You start to [anchored ? "un" : ""]wrench <b>[src.name]</b>..."))
		I.play_tool_sound(src, 50)
		var/prev_anchored = anchored
		//as long as we're the same anchored state and we're either on a floor or are anchored, toggle our anchored state
		if(I.use_tool(src, user, time, extra_checks = CALLBACK(src, PROC_REF(unfasten_wrench_check), prev_anchored, user)))
			if(!anchored && ground.is_blocked_turf(exclude_mobs = TRUE, source_atom = src))
				to_chat(user, span_notice("You failed to wrench <b>[src.name]</b>."))
				return CANT_UNFASTEN
			to_chat(user, span_notice("You [anchored ? "Un" : ""]wrench <b>[src.name]</b>."))
			set_anchored(!anchored)
			playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
			SEND_SIGNAL(src, COMSIG_OBJ_DEFAULT_UNFASTEN_WRENCH, anchored)
			return SUCCESSFUL_UNFASTEN
		return FAILED_UNFASTEN
	return CANT_UNFASTEN

/obj/proc/unfasten_wrench_check(prev_anchored, mob/user) //for the do_after, this checks if unfastening conditions are still valid
	if(anchored != prev_anchored)
		return FALSE
	if(can_be_unfasten_wrench(user, TRUE) != SUCCESSFUL_UNFASTEN) //if we aren't explicitly successful, cancel the fuck out
		return FALSE
	return TRUE

/obj/proc/handle_internal_lifeform(mob/lifeform_inside_me, breath_request)
	return null

/obj/proc/updateUsrDialog()
	if((obj_flags & IN_USE) && !(obj_flags & USES_TGUI))
		var/is_in_use = FALSE
		var/list/nearby = viewers(1, src)
		for(var/mob/M in nearby)
			if (M.client)
				is_in_use = TRUE
				ui_interact(M)
		if(isAdminGhostAI(usr))
			if (!(usr in nearby))
				if (usr.client) // && M.machine == src is omitted because if we triggered this by using the dialog, it doesn't matter if our machine changed in between triggering it and this - the dialog is probably still supposed to refresh.
					is_in_use = TRUE
					ui_interact(usr)

		// check for TK users

		if(ishuman(usr))
			if(!(usr in nearby))
				if(usr.client)
					is_in_use = TRUE
					ui_interact(usr)
		if (is_in_use)
			obj_flags |= IN_USE
		else
			obj_flags &= ~IN_USE

/obj/proc/updateDialog(update_viewers = TRUE,update_ais = TRUE)
	// Check that people are actually using the machine. If not, don't update anymore.
	if(obj_flags & IN_USE)
		if(update_viewers)
			for(var/mob/M in viewers(1, src))
				if (M.client)
					src.interact(M)


/obj/attack_ghost(mob/user)
	. = ..()
	if(.)
		return
	SEND_SIGNAL(src, COMSIG_ATOM_UI_INTERACT, user)
	ui_interact(user)

//called when the user unsets the machine.
/atom/movable/proc/on_unset_machine(mob/user)
	return

/obj/item/proc/updateSelfDialog()
	var/mob/M = src.loc
	if(istype(M) && M.client)
		src.attack_self(M)

/obj/get_dumping_location(datum/component/storage/source,mob/user)
	return get_turf(src)

/**
 * This proc is used for telling whether something can pass by this object in a given direction, for use by the pathfinding system.
 *
 * Trying to generate one long path across the station will call this proc on every single object on every single tile that we're seeing if we can move through, likely
 * multiple times per tile since we're likely checking if we can access said tile from multiple directions, so keep these as lightweight as possible.
 *
 * Arguments:
 * * ID- An ID card representing what access we have (and thus if we can open things like airlocks or windows to pass through them). The ID card's physical location does not matter, just the reference
 * * to_dir- What direction we're trying to move in, relevant for things like directional windows that only block movement in certain directions
 * * caller- The movable we're checking pass flags for, if we're making any such checks
 **/
/obj/proc/CanAStarPass(to_dir, atom/movable/caller)
	if(istype(caller) && (caller.pass_flags & pass_flags_self))
		return TRUE
	. = !density

/obj/proc/check_uplink_validity()
	return 1

/obj/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "---")
	VV_DROPDOWN_OPTION(VV_HK_MASS_DEL_TYPE, "Delete all of type")
	VV_DROPDOWN_OPTION(VV_HK_OSAY, "Object Say")
	VV_DROPDOWN_OPTION(VV_HK_ARMOR_MOD, "Modify armor values")

/obj/vv_do_topic(list/href_list)
	if(!(. = ..()))
		return
	if(href_list[VV_HK_OSAY])
		if(check_rights(R_FUN, FALSE))
			usr.client.object_say(src)
	if(href_list[VV_HK_ARMOR_MOD])
		var/list/pickerlist = list()
		var/list/armorlist = armor.getList()

		for (var/i in armorlist)
			pickerlist += list(list("value" = armorlist[i], "name" = i))

		var/list/result = presentpicker(usr, "Modify armor", "Modify armor: [src]", Button1="Save", Button2 = "Cancel", Timeout=FALSE, inputtype = "text", values = pickerlist)

		if (islist(result))
			if (result["button"] != 2) // If the user pressed the cancel button
				// text2num conveniently returns a null on invalid values
				armor = armor.setRating(sharp = text2num(result["values"][SHARP]),\
			                  pierce = text2num(result["values"][PIERCE]),\
			                  blunt = text2num(result["values"][BLUNT]),\
			                  fire = text2num(result["values"][FIRE]),\
			                  acid = text2num(result["values"][ACID]))
				log_admin("[key_name(usr)] modified the armor on [src] ([type]) to sharp: [armor.sharp], pierce: [armor.pierce], blunt: [armor.blunt], fire: [armor.fire], acid: [armor.acid]")
				message_admins(span_notice("[key_name_admin(usr)] modified the armor on [src] ([type]) to sharp: [armor.sharp], pierce: [armor.pierce], blunt: [armor.blunt], fire: [armor.fire], acid: [armor.acid]"))
	if(href_list[VV_HK_MASS_DEL_TYPE])
		if(check_rights(R_DEBUG|R_SERVER))
			var/action_type = tgui_alert(usr, "Strict type ([type]) or type and all subtypes?",,list("Strict type","Type and subtypes","Cancel"))
			if(action_type == "Cancel" || !action_type)
				return

			if(tgui_alert(usr, "Are you really sure you want to delete all objects of type [type]?",,list("Yes","No")) != "Yes")
				return

			if(tgui_alert(usr, "Second confirmation required. Delete?",,list("Yes","No")) != "Yes")
				return

			var/O_type = type
			switch(action_type)
				if("Strict type")
					var/i = 0
					for(var/obj/Obj in world)
						if(Obj.type == O_type)
							i++
							qdel(Obj)
						CHECK_TICK
					if(!i)
						to_chat(usr, "No objects of this type exist")
						return
					log_admin("[key_name(usr)] deleted all objects of type [O_type] ([i] objects deleted) ")
					message_admins(span_notice("[key_name(usr)] deleted all objects of type [O_type] ([i] objects deleted) "))
				if("Type and subtypes")
					var/i = 0
					for(var/obj/Obj in world)
						if(istype(Obj,O_type))
							i++
							qdel(Obj)
						CHECK_TICK
					if(!i)
						to_chat(usr, "No objects of this type exist")
						return
					log_admin("[key_name(usr)] deleted all objects of type or subtype of [O_type] ([i] objects deleted) ")
					message_admins(span_notice("[key_name(usr)] deleted all objects of type or subtype of [O_type] ([i] objects deleted) "))

// Should move all contained objects to it's location.
/obj/proc/dump_contents()
	CRASH("Unimplemented.")

/obj/handle_ricochet(obj/projectile/P)
	. = ..()
	if(. && receive_ricochet_damage_coeff)
		take_damage(P.damage * receive_ricochet_damage_coeff, P.damage_type, P.flag, 0, turn(P.dir, 180), P.armour_penetration) // pass along receive_ricochet_damage_coeff damage to the structure for the ricochet

/obj/update_overlays()
	. = ..()
	if(resistance_flags & ON_FIRE)
		. += custom_fire_overlay ? custom_fire_overlay : GLOB.fire_overlay

/// Handles exposing an object to reagents.
/obj/expose_reagents(list/reagents, datum/reagents/source, methods=TOUCH, volume_modifier=1, show_message=TRUE)
	. = ..()
	if(. & COMPONENT_NO_EXPOSE_REAGENTS)
		return

	SEND_SIGNAL(source, COMSIG_REAGENTS_EXPOSE_OBJ, src, reagents, methods, volume_modifier, show_message)
	for(var/reagent in reagents)
		var/datum/reagent/R = reagent
		. |= R.expose_obj(src, reagents[R])
