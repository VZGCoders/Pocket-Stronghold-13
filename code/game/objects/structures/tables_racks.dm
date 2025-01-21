/* Tables and Racks
 * Contains:
 *		Tables
 *		Glass Tables
 *		Wooden Tables
 *		Reinforced Tables
 *		Racks
 *		Rack Parts
 */

/*
 * Tables
 */

/obj/structure/table
	name = "table"
	desc = "A square piece of metal standing on four metal legs. It can not move."
	icon = 'icons/obj/smooth_structures/table.dmi'
	icon_state = "table-0"
	base_icon_state = "table"
	density = TRUE
	anchored = TRUE
	pass_flags_self = PASSTABLE | LETPASSTHROW
	layer = TABLE_LAYER
	var/buildstack
	var/busy = FALSE
	var/buildstackamount = 1
	var/framestackamount = 2
	var/deconstruction_ready = 1
	var/bashsound = 'sound/effects/tablebash.ogg'
	custom_materials = list(/datum/material/iron = 2000)
	max_integrity = 100
	integrity_failure = 0.33
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_TABLES)
	canSmoothWith = list(SMOOTH_GROUP_TABLES)

/obj/structure/table/Initialize(mapload, _buildstack)
	. = ..()
	if(_buildstack)
		buildstack = _buildstack
	AddElement(/datum/element/climbable)

/obj/structure/table/examine(mob/user)
	. = ..()
	. += deconstruction_hints(user)

/obj/structure/table/proc/deconstruction_hints(mob/user)
	return "<hr><span class='notice'>The top is <b>screwed</b> on, but the main <b>bolts</b> are also visible.</span>"

/obj/structure/table/update_icon()
	if(smoothing_flags & (SMOOTH_CORNERS|SMOOTH_BITMASK))
		QUEUE_SMOOTH(src)
		QUEUE_SMOOTH_NEIGHBORS(src)
	return ..()

/obj/structure/table/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/table/attack_hand(mob/living/user)
	if(Adjacent(user) && user.pulling)
		if(isliving(user.pulling))
			var/mob/living/pushed_mob = user.pulling
			if(pushed_mob.buckled)
				to_chat(user, span_warning("<b>[pushed_mob]</b> is buckled to <b>[pushed_mob.buckled]</b>!"))
				return
			if(user.a_intent == INTENT_GRAB)
				if(user.grab_state < GRAB_AGGRESSIVE)
					to_chat(user, span_warning("You need a better grip to do that!"))
					return
				if(user.grab_state >= GRAB_NECK)
					tablelimbsmash(user, pushed_mob)
				else
					tablepush(user, pushed_mob)
			if(user.a_intent == INTENT_HELP)
				pushed_mob.visible_message(span_notice("<b>[user]</b> begins to place <b>[pushed_mob]</b> onto <b>[src]</b>...") , \
									span_userdanger("<b>[user]</b> begins to place <b>you</b> onto <b>[src]</b>..."))
				if(do_after(user, 35, target = pushed_mob))
					tableplace(user, pushed_mob)
				else
					return
			user.stop_pulling()
		else if(user.pulling.pass_flags & PASSTABLE)
			user.Move_Pulled(src)
			if (user.pulling.loc == loc)
				user.visible_message(span_notice("<b>[user]</b> places <b>[user.pulling]</b> onto <b>[src]</b>.") ,
					span_notice("You place <b>[user.pulling]</b> onto <b>[src]</b>."))
				user.stop_pulling()
	if(user.a_intent == INTENT_HARM)
		user.changeNext_move(CLICK_CD_MELEE)
		user.visible_message(span_warning("[user] smashes \the [src]!") , span_warning("You smash \the [src]!") ,
			span_danger("You hear a loud sound."))
		playsound(src, bashsound, 80, TRUE)
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			if(!H.get_item_by_slot(ITEM_SLOT_GLOVES) && prob(25))
				var/which_hand = BODY_ZONE_L_ARM
				if(!(H.active_hand_index % 2))
					which_hand = BODY_ZONE_R_ARM
				var/obj/item/bodypart/ouchie = H.get_bodypart(which_hand)
				ouchie?.receive_damage(rand(1, 5))
	return ..()

/obj/structure/table/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(.)
		return
	if(mover.throwing)
		return TRUE
	if(locate(/obj/structure/table) in get_turf(mover))
		return TRUE

/obj/structure/table/CanAStarPass(to_dir, atom/movable/caller)
	. = !density
	if(istype(caller))
		. = . || (caller.pass_flags & PASSTABLE)

/obj/structure/table/proc/tableplace(mob/living/user, mob/living/pushed_mob)
	pushed_mob.forceMove(loc)
	pushed_mob.set_resting(TRUE, TRUE)
	pushed_mob.visible_message(span_notice("<b>[user]</b> places <b>[pushed_mob]</b> onto <b>[src]</b>.") , \
								span_notice("<b>[user]</b> places <b>[pushed_mob]</b> onto <b>[src]</b>."))
	log_combat(user, pushed_mob, "places", null, "onto [src]")

/obj/structure/table/proc/tablepush(mob/living/user, mob/living/pushed_mob)
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_danger("Throwing [pushed_mob] onto the table might hurt them!"))
		return
	var/added_passtable = FALSE
	if(!(pushed_mob.pass_flags & PASSTABLE))
		added_passtable = TRUE
		pushed_mob.pass_flags |= PASSTABLE
	pushed_mob.Move(src.loc)
	if(added_passtable)
		pushed_mob.pass_flags &= ~PASSTABLE
	if(pushed_mob.loc != loc) //Something prevented the tabling
		return
	pushed_mob.Knockdown(30)
	pushed_mob.apply_damage(10, BRUTE)
	pushed_mob.apply_damage(40, STAMINA)
	if(user.mind?.martial_art.smashes_tables && user.mind?.martial_art.can_use(user))
		deconstruct(FALSE)
	playsound(pushed_mob, 'sound/effects/tableslam.ogg', 90, TRUE)
	pushed_mob.visible_message(span_danger("<b>[user]</b> slams <b>[pushed_mob]</b> onto <b>[src]</b>!") , \
								span_userdanger("<b>[user]</b> slams you onto <b>[src]</b>!"))
	log_combat(user, pushed_mob, "tabled", null, "onto [src]")
	SEND_SIGNAL(pushed_mob, COMSIG_ADD_MOOD_EVENT, "table", /datum/mood_event/table)

/obj/structure/table/proc/tablelimbsmash(mob/living/user, mob/living/pushed_mob)
	pushed_mob.Knockdown(30)
	var/obj/item/bodypart/banged_limb = pushed_mob.get_bodypart(user.zone_selected) || pushed_mob.get_bodypart(BODY_ZONE_HEAD)
	banged_limb?.receive_damage(30)
	pushed_mob.apply_damage(60, STAMINA)
	take_damage(50)
	if(user.mind?.martial_art.smashes_tables && user.mind?.martial_art.can_use(user))
		deconstruct(FALSE)
	playsound(pushed_mob, "sound/effects/bang.ogg", 90, TRUE)
	pushed_mob.visible_message(span_danger("<b>[user]</b> smashes [pushed_mob]'s head againts \the <b>[src]</b>!") ,
								span_userdanger("<b>[user]</b> smashes your head against \the <b>[src]</b>!"))
	log_combat(user, pushed_mob, "head slammed", null, "against [src]")
	SEND_SIGNAL(pushed_mob, COMSIG_ADD_MOOD_EVENT, "table", /datum/mood_event/table_limbsmash,0,0, banged_limb)

/obj/structure/table/attackby(obj/item/I, mob/user, params)
	if(!(flags_1 & NODECONSTRUCT_1) && user.a_intent != INTENT_HELP)
		if(I.tool_behaviour == TOOL_SCREWDRIVER && deconstruction_ready)
			to_chat(user, span_notice("You start disassembling <b>[src]</b>..."))
			if(I.use_tool(src, user, 20, volume=50))
				deconstruct(TRUE)
			return

		if(I.tool_behaviour == TOOL_WRENCH && deconstruction_ready)
			to_chat(user, span_notice("You start deconstructing <b>[src]</b>..."))
			if(I.use_tool(src, user, 40, volume=50))
				playsound(src.loc, 'sound/items/deconstruct.ogg', 50, TRUE)
				deconstruct(TRUE, 1)
			return

	if(istype(I, /obj/item/riding_offhand))
		var/obj/item/riding_offhand/riding_item = I
		var/mob/living/carried_mob = riding_item.rider
		if(carried_mob == user) //Piggyback user.
			return
		switch(user.a_intent)
			if(INTENT_HARM)
				user.unbuckle_mob(carried_mob)
				tablelimbsmash(user, carried_mob)
			if(INTENT_HELP)
				var/tableplace_delay = 3.5 SECONDS
				var/skills_space = ""
				if(HAS_TRAIT(user, TRAIT_QUICKER_CARRY))
					tableplace_delay = 2 SECONDS
					skills_space = " expertly"
				else if(HAS_TRAIT(user, TRAIT_QUICK_CARRY))
					tableplace_delay = 2.75 SECONDS
					skills_space = " quickly"
				carried_mob.visible_message(span_notice("[user] begins to[skills_space] place [carried_mob] onto [src]...") ,
					span_userdanger("[user] begins to[skills_space] place [carried_mob] onto [src]..."))
				if(do_after(user, tableplace_delay, target = carried_mob))
					user.unbuckle_mob(carried_mob)
					tableplace(user, carried_mob)
			else
				user.unbuckle_mob(carried_mob)
				tablepush(user, carried_mob)
		return TRUE

	if(user.a_intent != INTENT_HARM && !(I.item_flags & ABSTRACT))
		if(user.transferItemToLoc(I, drop_location(), silent = FALSE))
			var/list/click_params = params2list(params)
			//Center the icon where the user clicked.
			if(!click_params || !click_params["icon-x"] || !click_params["icon-y"])
				return
			//Clamp it so that the icon never moves more than 16 pixels in either direction (thus leaving the table turf)
			I.pixel_x = clamp(text2num(click_params["icon-x"]) - 16, -(world.icon_size/2), world.icon_size/2)
			I.pixel_y = clamp(text2num(click_params["icon-y"]) - 16, -(world.icon_size/2), world.icon_size/2)
			AfterPutItemOnTable(I, user)
			return TRUE
	else
		return ..()

/obj/structure/table/proc/AfterPutItemOnTable(obj/item/I, mob/living/user)
	return

/obj/structure/table/deconstruct(disassembled = TRUE, wrench_disassembly = 0)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/turf/T = get_turf(src)
		if(buildstack)
			new buildstack(T, buildstackamount)
		else
			for(var/i in custom_materials)
				var/datum/material/M = i
				new M.sheet_type(T, FLOOR(custom_materials[M] / MINERAL_MATERIAL_AMOUNT, 1))
	qdel(src)

/*
 * Surgery Tables
 */

/obj/structure/table/optable
	name = "surgery table"
	desc = "Used for difficult medical procedures."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "optable"
	smoothing_flags = NONE
	smoothing_groups = null
	canSmoothWith = null
	can_buckle = 1
	buckle_lying = 90
	buckle_requires_restraints = TRUE
	var/mob/living/carbon/human/patient = null

/obj/structure/table/optable/tablepush(mob/living/user, mob/living/pushed_mob)
	pushed_mob.forceMove(loc)
	pushed_mob.set_resting(TRUE, TRUE)
	visible_message(span_notice("<b>[user]</b> lays <b>[pushed_mob]</b> on <b>[src]</b>."))
	get_patient()

/obj/structure/table/optable/proc/get_patient()
	var/mob/living/carbon/M = locate(/mob/living/carbon) in loc
	if(M)
		if(M.resting)
			set_patient(M)
	else
		set_patient(null)

/obj/structure/table/optable/proc/set_patient(new_patient)
	if(patient)
		UnregisterSignal(patient, COMSIG_PARENT_QDELETING)
	patient = new_patient
	if(patient)
		RegisterSignal(patient, COMSIG_PARENT_QDELETING, PROC_REF(patient_deleted))

/obj/structure/table/optable/proc/patient_deleted(datum/source)
	SIGNAL_HANDLER
	set_patient(null)

/obj/structure/table/optable/proc/check_eligible_patient()
	get_patient()
	if(!patient)
		return FALSE
	if(ishuman(patient))
		return TRUE
	return FALSE
