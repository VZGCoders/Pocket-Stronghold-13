/mob/living/Initialize()
	. = ..()
	register_init_signals()
	if(unique_name)
		set_name()
	var/datum/atom_hud/data/human/medical/advanced/medhud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	medhud.add_to_hud(src)
	faction += "[REF(src)]"
	GLOB.mob_living_list += src
	SSpoints_of_interest.make_point_of_interest(src)
	update_fov()

/mob/living/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/movetype_handler)

/mob/living/prepare_huds()
	..()
	prepare_data_huds()

/mob/living/proc/prepare_data_huds()
	med_hud_set_health()
	med_hud_set_status()

/mob/living/Destroy()
	if(LAZYLEN(status_effects))
		for(var/s in status_effects)
			var/datum/status_effect/S = s
			if(S.on_remove_on_mob_delete) //the status effect calls on_remove when its mob is deleted
				qdel(S)
			else
				S.be_replaced()
	if(buckled)
		buckled.unbuckle_mob(src,force=1)

	remove_from_all_data_huds()
	GLOB.mob_living_list -= src
	for(var/s in ownedSoullinks)
		var/datum/soullink/S = s
		S.ownerDies(FALSE)
		qdel(s) //If the owner is destroy()'d, the soullink is destroy()'d
	ownedSoullinks = null
	for(var/s in sharedSoullinks)
		var/datum/soullink/S = s
		S.sharerDies(FALSE)
		S.removeSoulsharer(src) //If a sharer is destroy()'d, they are simply removed
	sharedSoullinks = null
	return ..()

/mob/living/onZImpact(turf/T, levels, message = TRUE)
	if(!isgroundlessturf(T))
		ZImpactDamage(T, levels)
		message = FALSE
	return ..()

/mob/living/proc/ZImpactDamage(turf/T, levels)
	visible_message(span_danger("<b>[capitalize(src.name)]</b> flies into <b>[T]</b> voilently!") , \
					span_userdanger("You fly into [T] violently!"))
	adjustBruteLoss((levels * 5) ** 1.5)
	Knockdown(levels * 50)

//Generic Bump(). Override MobBump() and ObjBump() instead of this.
/mob/living/Bump(atom/A)
	if(..()) //we are thrown onto something
		return
	if(buckled || now_pushing)
		return
	if(ismob(A))
		var/mob/M = A
		if(MobBump(M))
			return
	if(isobj(A))
		var/obj/O = A
		if(ObjBump(O))
			return
	if(ismovable(A))
		var/atom/movable/AM = A
		if(PushAM(AM, move_force))
			return

/mob/living/Bumped(atom/movable/AM)
	..()
	last_bumped = world.time

//Called when we bump onto a mob
/mob/living/proc/MobBump(mob/M)
	//Even if we don't push/swap places, we "touched" them, so spread fire
	spreadFire(M)

	if(now_pushing)
		return TRUE

	var/they_can_move = TRUE
	if(isliving(M))
		var/mob/living/L = M
		they_can_move = L.mobility_flags & MOBILITY_MOVE

		//Should stop you pushing a restrained person out of the way
		if(L.pulledby && L.pulledby != src && HAS_TRAIT(L, TRAIT_RESTRAINED))
			if(!(world.time % 5))
				to_chat(src, span_warning("<b>[L]</b> can't let you pass through."))
			return TRUE

		if(L.pulling)
			if(ismob(L.pulling))
				var/mob/P = L.pulling
				if(HAS_TRAIT(P, TRAIT_RESTRAINED))
					if(!(world.time % 5))
						to_chat(src, span_warning("<b>[L]</b> is pulling <b>[P]</b> and doesn't let you pass through."))
					return TRUE

	if(moving_diagonally)//no mob swap during diagonal moves.
		return TRUE

	if(!M.buckled && !M.has_buckled_mobs())
		var/mob_swap = FALSE
		var/too_strong = (M.move_resist > move_force) //can't swap with immovable objects unless they help us
		if(!they_can_move) //we have to physically move them
			if(!too_strong)
				mob_swap = TRUE
		else
			//You can swap with the person you are dragging on grab intent, and restrained people in most cases
			if(M.pulledby == src && a_intent == INTENT_GRAB && !too_strong)
				mob_swap = TRUE
			else if(
				!(HAS_TRAIT(M, TRAIT_NOMOBSWAP) || HAS_TRAIT(src, TRAIT_NOMOBSWAP))&&\
				((HAS_TRAIT(M, TRAIT_RESTRAINED) && !too_strong) || M.a_intent == INTENT_HELP) &&\
				(HAS_TRAIT(src, TRAIT_RESTRAINED) || a_intent == INTENT_HELP)
			)
				mob_swap = TRUE
		if(mob_swap)
			//switch our position with M
			if(loc && !loc.Adjacent(M.loc))
				return TRUE
			now_pushing = TRUE
			var/oldloc = loc
			var/oldMloc = M.loc


			var/M_passmob = (M.pass_flags & PASSMOB) // we give PASSMOB to both mobs to avoid bumping other mobs during swap.
			var/src_passmob = (pass_flags & PASSMOB)
			M.pass_flags |= PASSMOB
			pass_flags |= PASSMOB

			var/move_failed = FALSE
			if(!M.Move(oldloc) || !Move(oldMloc))
				M.forceMove(oldMloc)
				forceMove(oldloc)
				move_failed = TRUE
			if(!src_passmob)
				pass_flags &= ~PASSMOB
			if(!M_passmob)
				M.pass_flags &= ~PASSMOB

			now_pushing = FALSE

			if(!move_failed)
				return TRUE

	//okay, so we didn't switch. but should we push?
	//not if he's not CANPUSH of course
	if(!(M.status_flags & CANPUSH))
		return TRUE
	if(isliving(M))
		var/mob/living/L = M
		if(HAS_TRAIT(L, TRAIT_PUSHIMMUNE))
			return TRUE
	//If they're a human, and they're not in help intent, block pushing
	if(ishuman(M) && (M.a_intent != INTENT_HELP))
		return TRUE
	//anti-riot equipment is also anti-push
	for(var/obj/item/I in M.held_items)
		if(!istype(M, /obj/item/clothing))
			if(prob(I.block_chance*2))
				return

//Called when we bump onto an obj
/mob/living/proc/ObjBump(obj/O)
	return

//Called when we want to push an atom/movable
/mob/living/proc/PushAM(atom/movable/AM, force = move_force)
	if(now_pushing)
		return TRUE
	if(moving_diagonally)// no pushing during diagonal moves.
		return TRUE
	if(!client && (mob_size < MOB_SIZE_SMALL))
		return
	now_pushing = TRUE
	SEND_SIGNAL(src, COMSIG_LIVING_PUSHING_MOVABLE, AM)
	var/t = get_dir(src, AM)
	var/push_anchored = FALSE
	if((AM.move_resist * MOVE_FORCE_CRUSH_RATIO) <= force)
		if(move_crush(AM, move_force, t))
			push_anchored = TRUE
	if((AM.move_resist * MOVE_FORCE_FORCEPUSH_RATIO) <= force)			//trigger move_crush and/or force_push regardless of if we can push it normally
		if(force_push(AM, move_force, t, push_anchored))
			push_anchored = TRUE
	if((AM.anchored && !push_anchored) || (force < (AM.move_resist * MOVE_FORCE_PUSH_RATIO)))
		now_pushing = FALSE
		return
	if(pulling == AM)
		stop_pulling()
	var/current_dir
	if(isliving(AM))
		current_dir = AM.dir
	if(AM.Move(get_step(AM.loc, t), t, glide_size))
		Move(get_step(loc, t), t)
	if(current_dir)
		AM.setDir(current_dir)

	now_pushing = FALSE

/mob/living/start_pulling(atom/movable/AM, state, force = pull_force, supress_message = FALSE)
	if(!AM || !src)
		return FALSE
	if(!(AM.can_be_pulled(src, state, force)))
		return FALSE
	if(throwing || !(mobility_flags & MOBILITY_PULL))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_LIVING_TRY_PULL, AM, force) & COMSIG_LIVING_CANCEL_PULL)
		return FALSE

	AM.add_fingerprint(src)

	// If we're pulling something then drop what we're currently pulling and pull this instead.
	if(pulling)
		// Are we trying to pull something we are already pulling? Then just stop here, no need to continue.
		if(AM == pulling)
			return
		stop_pulling()

	changeNext_move(CLICK_CD_GRABBING)

	if(AM.pulledby)
		if(!supress_message)
			AM.visible_message(span_danger("<b>[src]</b> pulls away <b>[AM]</b> from <b>[AM.pulledby]</b>.") , \
							span_danger("<b>[src]</b> pulls you away from <b>[AM.pulledby]'s</b> grip.") , null, null, src)
			to_chat(src, span_notice("You pull <b>[AM]</b> from <b>[AM.pulledby]'s</b> grip!"))
		log_combat(AM, AM.pulledby, "pulled from", src)
		AM.pulledby.stop_pulling() //an object can't be pulled by two mobs at once.

	pulling = AM
	AM.set_pulledby(src)

	SEND_SIGNAL(src, COMSIG_LIVING_START_PULL, AM, state, force)

	if(!supress_message)
		var/sound_to_play = 'sound/weapons/thudswoosh.ogg'
		if(ishuman(src))
			var/mob/living/carbon/human/H = src
			if(H.dna.species.grab_sound)
				sound_to_play = H.dna.species.grab_sound
			if(HAS_TRAIT(H, TRAIT_STRONG_GRABBER))
				sound_to_play = null
		playsound(src.loc, sound_to_play, 50, TRUE, -1)
	update_pull_hud_icon()

	if(ismob(AM))
		var/mob/M = AM

		log_combat(src, M, "grabbed", addition="passive grab")
		if(!supress_message && !(iscarbon(AM) && HAS_TRAIT(src, TRAIT_STRONG_GRABBER)))
			M.visible_message(span_warning("[capitalize(src.name)] grabs [M][(zone_selected == "l_arm" || zone_selected == "r_arm" && ishuman(M))? "'s hand":""]!") , \
							span_warning("[capitalize(src.name)] grabs your[(zone_selected == "l_arm" || zone_selected == "r_arm" && ishuman(M))? " hand":""]!") , null, null, src)
			to_chat(src, span_notice("You grab [M][(zone_selected == "l_arm" || zone_selected == "r_arm" && ishuman(M))? "'s hand":""]!"))
		if(!iscarbon(src))
			M.LAssailant = null
		else
			M.LAssailant = WEAKREF(usr)
		if(isliving(M))
			var/mob/living/L = M
			SEND_SIGNAL(M, COMSIG_LIVING_GET_PULLED, src)

			if(iscarbon(L))
				var/mob/living/carbon/C = L
				if(HAS_TRAIT(src, TRAIT_STRONG_GRABBER))
					C.grippedby(src)

			update_pull_movespeed()

		set_pull_offsets(M, state)


/mob/living/proc/set_pull_offsets(mob/living/M, grab_state = GRAB_PASSIVE)
	if(M.buckled)
		return //don't make them change direction or offset them if they're buckled into something.
	var/offset = 0
	switch(grab_state)
		if(GRAB_PASSIVE)
			offset = GRAB_PIXEL_SHIFT_PASSIVE
		if(GRAB_AGGRESSIVE)
			offset = GRAB_PIXEL_SHIFT_AGGRESSIVE
		if(GRAB_NECK)
			offset = GRAB_PIXEL_SHIFT_NECK
		if(GRAB_KILL)
			offset = GRAB_PIXEL_SHIFT_NECK
	M.setDir(get_dir(M, src))
	switch(M.dir)
		if(NORTH)
			animate(M, pixel_x = M.base_pixel_x, pixel_y = M.base_pixel_y + offset, 3)
		if(SOUTH)
			animate(M, pixel_x = M.base_pixel_x, pixel_y = M.base_pixel_y - offset, 3)
		if(EAST)
			if(M.lying_angle == 270) //update the dragged dude's direction if we've turned
				M.set_lying_angle(90)
			animate(M, pixel_x = M.base_pixel_x + offset, pixel_y = M.base_pixel_y, 3)
		if(WEST)
			if(M.lying_angle == 90)
				M.set_lying_angle(270)
			animate(M, pixel_x = M.base_pixel_x - offset, pixel_y = M.base_pixel_y, 3)

/mob/living/proc/reset_pull_offsets(mob/living/M, override)
	if(!override && M.buckled)
		return
	animate(M, pixel_x = base_pixel_x, pixel_y = base_pixel_y, 1)

//mob verbs are a lot faster than object verbs
//for more info on why this is not atom/pull, see examinate() in mob.dm
/mob/living/verb/pulled(atom/movable/AM as mob|obj in oview(1))
	set name = "Pull"
	set category = "Obj"

	if(istype(AM) && Adjacent(AM))
		start_pulling(AM)
	else
		stop_pulling()

/mob/living/stop_pulling()
	if(ismob(pulling))
		reset_pull_offsets(pulling)
	..()

	update_pull_movespeed()
	update_pull_hud_icon()

/mob/living/verb/stop_pulling1()
	set name = "Stop pulling"
	set category = "IC"
	stop_pulling()

//same as above
/mob/living/pointed(atom/A as mob|obj|turf in view(client.view, src))
	if(incapacitated())
		return FALSE
	if(!..())
		return FALSE
	visible_message(span_name("[capitalize(src.name)]</span> points at <b>[A]</b>."),
					span_notice("You point at <b>[A]</b>."))
	return TRUE


/mob/living/verb/succumb(whispered as null)
	set hidden = TRUE
	if (!CAN_SUCCUMB(src))
		to_chat(src, text="You are unable to succumb to death! This life continues.", type=MESSAGE_TYPE_INFO)
		return FALSE
	if(!whispered)
		var/response = tgui_alert(usr, "Are you sure you want to leave your body?", "Ghost", list("Yes", "No"))
		if(response != "Yes")
			to_chat(src, span_boldnotice("You stay in your body."))
			return
	log_message("Has [whispered ? "whispered his final words" : "succumbed to death"] with [round(health, 0.1)] points of health!", LOG_ATTACK)
	adjustOxyLoss(health - HEALTH_THRESHOLD_DEAD)
	updatehealth()
	if(!whispered)
		to_chat(src, span_notice("You leave your body."))
	death()
	return TRUE

/mob/living/incapacitated(ignore_restraints = FALSE, ignore_grab = FALSE)
	if(HAS_TRAIT(src, TRAIT_INCAPACITATED) || (!ignore_restraints && (HAS_TRAIT(src, TRAIT_RESTRAINED) || (!ignore_grab && pulledby && pulledby.grab_state >= GRAB_AGGRESSIVE))))
		return TRUE

/mob/living/canUseStorage()
	if (usable_hands <= 0)
		return FALSE
	return TRUE


//This proc is used for mobs which are affected by pressure to calculate the amount of pressure that actually
//affects them once clothing is factored in. ~Errorage
/mob/living/proc/calculate_affecting_pressure(pressure)
	return pressure

/mob/living/proc/getMaxHealth()
	return maxHealth

/mob/living/proc/setMaxHealth(newMaxHealth)
	maxHealth = newMaxHealth

/// Returns the health of the mob while ignoring damage of non-organic (prosthetic) limbs
/// Used by cryo cells to not permanently imprison those with damage from prosthetics,
/// as they cannot be healed through chemicals.
/mob/living/proc/get_organic_health()
	return health

// MOB PROCS //END

/mob/living/proc/mob_sleep()
	set name = "Sleep"
	set category = "IC"

	if(IsSleeping())
		to_chat(src, span_warning("You are already asleep!"))
		return
	else
		switch(tgui_alert(src, "How long do you want to sleep?", "Sleep", list("30 seconds", "45 seconds", "60 seconds"), timeout = 15 SECONDS))
			if("30 seconds")
				SetSleeping(30 SECONDS)
				return
			if("45 seconds")
				SetSleeping(45 SECONDS)
				return
			if("60 seconds")
				SetSleeping(60 SECONDS)
				return
			else
				return

/mob/proc/get_contents()

/mob/living/proc/toggle_resting()
	set name = "Lie down/Get up"
	set category = "IC"

	set_resting(!resting, FALSE)


///Proc to hook behavior to the change of value in the resting variable.
/mob/living/proc/set_resting(new_resting, silent = TRUE, instant = FALSE)
	if(!(mobility_flags & MOBILITY_REST))
		return
	if(new_resting == resting)
		return
	. = resting
	resting = new_resting
	if(new_resting)
		if(body_position == LYING_DOWN)
			if(!silent)
				to_chat(src, span_notice("You keep lying down."))
		else if(HAS_TRAIT(src, TRAIT_FORCED_STANDING) || (buckled && buckled.buckle_lying != NO_BUCKLE_LYING))
			if(!silent)
				to_chat(src, span_notice("You will lie down ASAP."))
		else
			if(!silent)
				to_chat(src, span_notice("You lie down."))
			set_lying_down()
	else
		if(body_position == STANDING_UP)
			if(!silent)
				to_chat(src, span_notice("You keep standing."))
		else if(HAS_TRAIT(src, TRAIT_FLOORED) || (buckled && buckled.buckle_lying != NO_BUCKLE_LYING))
			if(!silent)
				to_chat(src, span_notice("You will stand up ASAP."))
		else
			if(!silent)
				to_chat(src, span_notice("You stand up."))
			get_up(instant)

	update_resting()


/// Proc to append and redefine behavior to the change of the [/mob/living/var/resting] variable.
/mob/living/proc/update_resting()
	update_rest_hud_icon()


/mob/living/proc/get_up(instant = FALSE)
	set waitfor = FALSE
	if(!instant && !do_mob(src, src, 1 SECONDS, timed_action_flags = (IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM), extra_checks = CALLBACK(src, /mob/living/proc/rest_checks_callback), interaction_key = DOAFTER_SOURCE_GETTING_UP))
		return
	if(resting || body_position == STANDING_UP || HAS_TRAIT(src, TRAIT_FLOORED))
		return
	set_lying_angle(0)
	set_body_position(STANDING_UP)


/mob/living/proc/rest_checks_callback()
	if(resting || body_position == STANDING_UP || HAS_TRAIT(src, TRAIT_FLOORED))
		return FALSE
	return TRUE


/// Change the [body_position] to [LYING_DOWN] and update associated behavior.
/mob/living/proc/set_lying_down(new_lying_angle)
	set_body_position(LYING_DOWN)


/// Proc to append behavior related to lying down.
/mob/living/proc/on_lying_down(new_lying_angle)
	if(layer == initial(layer)) //to avoid things like hiding larvas.
		layer = LYING_MOB_LAYER //so mob lying always appear behind standing mobs
	ADD_TRAIT(src, TRAIT_UI_BLOCKED, LYING_DOWN_TRAIT)
	ADD_TRAIT(src, TRAIT_PULL_BLOCKED, LYING_DOWN_TRAIT)
	set_density(FALSE) // We lose density and stop bumping passable dense things.
	if(HAS_TRAIT(src, TRAIT_FLOORED) && !(dir & (NORTH|SOUTH)))
		setDir(pick(NORTH, SOUTH)) // We are and look helpless.
	body_position_pixel_y_offset = PIXEL_Y_OFFSET_LYING


/// Proc to append behavior related to lying down.
/mob/living/proc/on_standing_up()
	if(layer == LYING_MOB_LAYER)
		layer = initial(layer)
	set_density(initial(density)) // We were prone before, so we become dense and things can bump into us again.
	REMOVE_TRAIT(src, TRAIT_UI_BLOCKED, LYING_DOWN_TRAIT)
	REMOVE_TRAIT(src, TRAIT_PULL_BLOCKED, LYING_DOWN_TRAIT)
	body_position_pixel_y_offset = 0



//Recursive function to find everything a mob is holding. Really shitty proc tbh.
/mob/living/get_contents()
	var/list/ret = list()
	ret |= contents						//add our contents
	for(var/i in ret.Copy())			//iterate storage objects
		var/atom/A = i
		SEND_SIGNAL(A, COMSIG_TRY_STORAGE_RETURN_INVENTORY, ret)
	return ret

/**
 * Returns whether or not the mob can be injected. Should not perform any side effects.
 *
 * Arguments:
 * * user - The user trying to inject the mob.
 * * target_zone - The zone being targeted.
 * * injection_flags - A bitflag for extra properties to check.
 *   Check __DEFINES/injection.dm for more details, specifically the ones prefixed INJECT_CHECK_*.
 */
/mob/living/proc/can_inject(mob/user, target_zone, injection_flags)
	return TRUE

/**
 * Like can_inject, but it can perform side effects.
 *
 * Arguments:
 * * user - The user trying to inject the mob.
 * * target_zone - The zone being targeted.
 * * injection_flags - A bitflag for extra properties to check. Check __DEFINES/injection.dm for more details.
 *   Check __DEFINES/injection.dm for more details. Unlike can_inject, the INJECT_TRY_* defines will behave differently.
 */
/mob/living/proc/try_inject(mob/user, target_zone, injection_flags)
	return can_inject(user, target_zone, injection_flags)

/mob/living/is_injectable(mob/user, allowmobs = TRUE)
	return (allowmobs && reagents && can_inject(user))

/mob/living/is_drawable(mob/user, allowmobs = TRUE)
	return (allowmobs && reagents && can_inject(user))


///Sets the current mob's health value. Do not call directly if you don't know what you are doing, use the damage procs, instead.
/mob/living/proc/set_health(new_value)
	. = health
	health = new_value


/mob/living/proc/updatehealth()
	if(status_flags & GODMODE)
		return
	set_health(maxHealth - getOxyLoss() - getToxLoss() - getFireLoss() - getBruteLoss())
	staminaloss = getStaminaLoss()
	update_stat()
	med_hud_set_health()
	med_hud_set_status()
	update_health_hud()

/mob/living/update_health_hud()
	var/severity = 0
	var/healthpercent = (health/maxHealth) * 100
	if(hud_used?.healthdoll) //to really put you in the boots of a simplemob
		var/atom/movable/screen/healthdoll/living/livingdoll = hud_used.healthdoll
		switch(healthpercent)
			if(100 to INFINITY)
				severity = 0
			if(80 to 100)
				severity = 1
			if(60 to 80)
				severity = 2
			if(40 to 60)
				severity = 3
			if(20 to 40)
				severity = 4
			if(1 to 20)
				severity = 5
			else
				severity = 6
		livingdoll.icon_state = "living[severity]"
		if(!livingdoll.filtered)
			livingdoll.filtered = TRUE
			var/icon/mob_mask = icon(icon, icon_state)
			if(mob_mask.Height() > world.icon_size || mob_mask.Width() > world.icon_size)
				var/health_doll_icon_state = health_doll_icon ? health_doll_icon : "megasprite"
				mob_mask = icon('icons/hud/screen_gen.dmi', health_doll_icon_state) //swap to something generic if they have no special doll
			livingdoll.add_filter("mob_shape_mask", 1, alpha_mask_filter(icon = mob_mask))
			livingdoll.add_filter("inset_drop_shadow", 2, drop_shadow_filter(size = -1))
	if(severity > 0)
		overlay_fullscreen("brute", /atom/movable/screen/fullscreen/brute, severity)
	else
		clear_fullscreen("brute")

//Proc used to resuscitate a mob, for full_heal see fully_heal()
/mob/living/proc/revive(full_heal = FALSE, admin_revive = FALSE, excess_healing = 0)
	if(excess_healing)
		if(iscarbon(src) && excess_healing)
			var/mob/living/carbon/C = src
			if(!(C.dna?.species && (NOBLOOD in C.dna.species.species_traits)))
				C.blood_volume += (excess_healing*2)//1 excess = 10 blood

			for(var/i in C.internal_organs)
				var/obj/item/organ/O = i
				if(O.organ_flags & ORGAN_SYNTHETIC)
					continue
				O.applyOrganDamage(excess_healing*-1)//1 excess = 5 organ damage healed

		adjustOxyLoss(-20, TRUE)
		adjustToxLoss(-20, TRUE, TRUE) //slime friendly
		updatehealth()
	if(full_heal)
		fully_heal(admin_revive = admin_revive)
	if(stat == DEAD && can_be_revived()) //in some cases you can't revive (e.g. no brain)
		set_suicide(FALSE)
		set_stat(UNCONSCIOUS) //the mob starts unconscious,
		updatehealth() //then we check if the mob should wake up.
		if(admin_revive)
			get_up(TRUE)
		update_sight()
		clear_alert("not_enough_oxy")
		reload_fullscreen()
		. = TRUE
		if(excess_healing)
			INVOKE_ASYNC(src, PROC_REF(emote), "gasp")
			log_combat(src, src, "revived")
	else if(admin_revive)
		updatehealth()
		get_up(TRUE)
	// The signal is called after everything else so components can properly check the updated values
	SEND_SIGNAL(src, COMSIG_LIVING_REVIVE, full_heal, admin_revive)


/mob/living/proc/remove_CC()
	SetStun(0)
	SetKnockdown(0)
	SetImmobilized(0)
	SetParalyzed(0)
	SetSleeping(0)
	setStaminaLoss(0)
	SetUnconscious(0)

//proc used to completely heal a mob.
//admin_revive = TRUE is used in other procs, for example mob/living/carbon/fully_heal()
/mob/living/proc/fully_heal(admin_revive = FALSE)
	restore_blood()
	setToxLoss(0, 0) //zero as second argument not automatically call updatehealth().
	setOxyLoss(0, 0)
	remove_CC()
	set_disgust(0)
	losebreath = 0
	set_nutrition(NUTRITION_LEVEL_FED + 50)
	bodytemperature = get_body_temp_normal(apply_change=FALSE)
	set_blindness(0)
	set_blurriness(0)
	set_dizziness(0)
	cure_nearsighted()
	cure_blind()
	cure_husk()
	hallucination = 0
	heal_overall_damage(INFINITY, INFINITY, INFINITY, null, TRUE) //heal brute and burn dmg on both organic and robotic limbs, and update health right away.
	extinguish_mob()
	fire_stacks = 0
	set_confusion(0)
	dizziness = 0
	drowsyness = 0
	stuttering = 0
	slurring = 0
	jitteriness = 0
	stop_sound_channel(CHANNEL_HEARTBEAT)
	SEND_SIGNAL(src, COMSIG_LIVING_POST_FULLY_HEAL, admin_revive)


//proc called by revive(), to check if we can actually ressuscitate the mob (we don't want to revive him and have him instantly die again)
/mob/living/proc/can_be_revived()
	. = TRUE
	if(health <= HEALTH_THRESHOLD_DEAD)
		return FALSE

/mob/living/proc/update_damage_overlays()
	return

/mob/living/Move(atom/newloc, direct, glide_size_override)
	if(lying_angle != 0)
		lying_angle_on_movement(direct)
	if (buckled && buckled.loc != newloc) //not updating position
		if (!buckled.anchored)
			buckled.moving_from_pull = moving_from_pull
			. = buckled.Move(newloc, direct, glide_size)
			buckled?.moving_from_pull = null
		return

	var/old_direction = dir
	var/turf/T = loc
	if(pulling)
		update_pull_movespeed()
	. = ..()

	if(moving_diagonally != FIRST_DIAG_STEP && isliving(pulledby))
		var/mob/living/L = pulledby
		L.set_pull_offsets(src, pulledby.grab_state)

	if(active_storage && !(CanReach(active_storage.parent,view_only = TRUE)))
		active_storage.close(src)

	if(body_position == LYING_DOWN && !buckled && prob(getBruteLoss()*200/maxHealth))
		makeTrail(newloc, T, old_direction)


///Called by mob Move() when the lying_angle is different than zero, to better visually simulate crawling.
/mob/living/proc/lying_angle_on_movement(direct)
	if(direct & EAST)
		set_lying_angle(90)
	else if(direct & WEST)
		set_lying_angle(270)

/mob/living/proc/makeTrail(turf/target_turf, turf/start, direction)
	if(!isturf(start) || !blood_volume)
		return

	var/blood_exists = locate(/obj/effect/decal/cleanable/trail_holder) in start

	var/trail_type = getTrail()
	if(!trail_type)
		return

	var/brute_ratio = round(getBruteLoss() / maxHealth, 0.1)
	if(blood_volume < max(BLOOD_VOLUME_NORMAL*(1 - brute_ratio * 0.25), 0))//don't leave trail if blood volume below a threshold
		return

	var/bleed_amount = bleedDragAmount()
	blood_volume = max(blood_volume - bleed_amount, 0) //that depends on our brute damage.
	var/newdir = get_dir(target_turf, start)
	if(newdir != direction)
		newdir = newdir | direction
		if(newdir == (NORTH|SOUTH))
			newdir = NORTH
		else if(newdir == (EAST|WEST))
			newdir = EAST
	if((newdir in GLOB.cardinals) && (prob(50)))
		newdir = turn(get_dir(target_turf, start), 180)
	if(!blood_exists)
		new /obj/effect/decal/cleanable/trail_holder(start)

	for(var/obj/effect/decal/cleanable/trail_holder/TH in start)
		if((!(newdir in TH.existing_dirs) || trail_type == "trails_1" || trail_type == "trails_2") && TH.existing_dirs.len <= 16) //maximum amount of overlays is 16 (all light & heavy directions filled)
			TH.existing_dirs += newdir
			TH.add_overlay(image('icons/effects/blood.dmi', trail_type, dir = newdir))
			TH.transfer_mob_blood_dna(src)

/mob/living/carbon/human/makeTrail(turf/T)
	if((NOBLOOD in dna.species.species_traits) || !is_bleeding() || HAS_TRAIT(src, TRAIT_NOBLEED))
		return
	..()

///Returns how much blood we're losing from being dragged a tile, from [/mob/living/proc/makeTrail]
/mob/living/proc/bleedDragAmount()
	var/brute_ratio = round(getBruteLoss() / maxHealth, 0.1)
	return max(1, brute_ratio * 2)

/mob/living/carbon/bleedDragAmount()
	return ..()

/mob/living/proc/getTrail()
	if(getBruteLoss() < 300)
		return pick("ltrails_1", "ltrails_2")
	else
		return pick("trails_1", "trails_2")

/mob/living/can_resist()
	return !((next_move > world.time) || incapacitated(ignore_restraints = TRUE))

/mob/living/verb/resist()
	set name = "Resist"
	set category = "IC"

	if(!can_resist())
		return
	changeNext_move(CLICK_CD_RESIST)

	SEND_SIGNAL(src, COMSIG_LIVING_RESIST, src)
	//resisting grabs (as if it helps anyone...)
	if(!HAS_TRAIT(src, TRAIT_RESTRAINED) && pulledby)
		log_combat(src, pulledby, "resisted grab")
		resist_grab()
		return

	//unbuckling yourself
	if(buckled && last_special <= world.time)
		resist_buckle()

	//Breaking out of a container (Locker, sleeper, cryo...)
	else if(loc != get_turf(src))
		loc.container_resist_act(src)

	else if(mobility_flags & MOBILITY_MOVE)
		if(on_fire)
			resist_fire() //stop, drop, and roll
		else if(last_special <= world.time)
			resist_restraints() //trying to remove cuffs.


/mob/proc/resist_grab(moving_resist)
	return 1 //returning 0 means we successfully broke free

/mob/living/resist_grab(moving_resist)
	. = TRUE
	if(pulledby.grab_state || resting || HAS_TRAIT(src, TRAIT_GRABWEAKNESS))
		var/altered_grab_state = pulledby.grab_state
		if((resting || HAS_TRAIT(src, TRAIT_GRABWEAKNESS)) && pulledby.grab_state < GRAB_KILL) //If resting, resisting out of a grab is equivalent to 1 grab state higher. won't make the grab state exceed the normal max, however
			altered_grab_state++
		var/resist_chance = BASE_GRAB_RESIST_CHANCE /// see defines/combat.dm, this should be baseline 60%
		resist_chance = (resist_chance/altered_grab_state) ///Resist chance divided by the value imparted by your grab state. It isn't until you reach neckgrab that you gain a penalty to escaping a grab.
		if(prob(resist_chance))
			visible_message(span_danger("<b>[src]</b> breaks out of <b>[pulledby]'s</b> grip!") , \
							span_danger("You break out of <b>[pulledby]'s</b> grip!") , null, null, pulledby)
			to_chat(pulledby, span_warning("<b>[src]</b> breaks out of your grip!"))
			log_combat(pulledby, src, "broke grab")
			pulledby.stop_pulling()
			return FALSE
		else
			adjustStaminaLoss(rand(15,20))//failure to escape still imparts a pretty serious penalty
			visible_message(span_danger("<b>[src]</b> fails to break out of <b>[pulledby]'s</b> grip!") , \
							span_warning("You fail to break out of <b>[pulledby]'s</b> grip!") , null, null, pulledby)
			to_chat(pulledby, span_danger("<b>[src]</b> fail to break out of your grip!"))
		if(moving_resist && client) //we resisted by trying to move
			client.move_delay = world.time + 40
	else
		pulledby.stop_pulling()
		return FALSE

/mob/living/proc/resist_buckle()
	buckled.user_unbuckle_mob(src,src)

/mob/living/proc/resist_fire()
	return

/mob/living/proc/resist_restraints()
	return

/mob/living/proc/get_visible_name()
	return name

// The src mob tries to strip an item from someone
// Override if a certain type of mob should be behave differently when stripping items (can't, for example)
/mob/living/stripPanelUnequip(obj/item/what, mob/who, where)
	if(!what.canStrip(who))
		to_chat(src, span_warning("You fail to strip <b>[what.name]</b>, looks like it's glued!"))
		return
	who.visible_message(span_warning("<b>[src]</b> attempts to strip <b>[what.name]</b> from <b>[who]</b>.") , \
					span_userdanger("<b>[src]</b> attempts to strip your <b>[what.name]</b>.") , null, null, src)
	to_chat(src, span_danger("You attempt to strip <b>[what.name]</b> from <b>[who]</b>..."))
	who.log_message("[key_name(who)] is being stripped of [what] by [key_name(src)]", LOG_ATTACK, color="red")
	log_message("[key_name(who)] is being stripped of [what] by [key_name(src)]", LOG_ATTACK, color="red", log_globally=FALSE)
	what.add_fingerprint(src)
	if(do_mob(src, who, what.strip_delay, interaction_key = what))
		if(what && Adjacent(who))
			if(islist(where))
				var/list/L = where
				if(what == who.get_item_for_held_index(L[2]))
					if(what.doStrip(src, who))
						who.log_message("[key_name(who)] has been stripped of [what] by [key_name(src)]", LOG_ATTACK, color="red")
						log_message("[key_name(who)] has been stripped of [what] by [key_name(src)]", LOG_ATTACK, color="red", log_globally=FALSE)
			if(what == who.get_item_by_slot(where))
				if(what.doStrip(src, who))
					who.log_message("[key_name(who)] has been stripped of [what] by [key_name(src)]", LOG_ATTACK, color="red")
					log_message("[key_name(who)] has been stripped of [what] by [key_name(src)]", LOG_ATTACK, color="red", log_globally=FALSE)

// The src mob is trying to place an item on someone
// Override if a certain mob should be behave differently when placing items (can't, for example)
/mob/living/stripPanelEquip(obj/item/what, mob/who, where)
	what = src.get_active_held_item()
	if(what && (HAS_TRAIT(what, TRAIT_NODROP)))
		to_chat(src, span_warning("You are unable to put <b>[what.name]</b> on <b>[who]</b>, looks like it's stuck to your hand!"))
		return
	if(what)
		var/list/where_list
		var/final_where

		if(islist(where))
			where_list = where
			final_where = where[1]
		else
			final_where = where

		if(!what.mob_can_equip(who, src, final_where, TRUE, TRUE))
			to_chat(src, span_warning("Can't put <b>[what.name]</b> here!"))
			return
		if(istype(what,/obj/item/clothing))
			var/obj/item/clothing/c = what
			if(c.clothing_flags & DANGEROUS_OBJECT)
				who.visible_message(span_danger("<b>[src]</b> attempts to put <b>[what]</b> on <b>[who]</b>.") , \
							span_userdanger("<b>[src]</b> attempts to put <b>[what]</b> on you.") , null, null, src)
			else
				who.visible_message(span_notice("<b>[src]</b> attempts to put <b>[what]</b> on <b>[who]</b>.") , \
							span_notice("<b>[src]</b> attempts to put <b>[what]</b> on you.") , null, null, src)
		to_chat(src, span_notice("You attempt to put <b>[what]</b> on <b>[who]</b>..."))
		who.log_message("[key_name(who)] is having [what] put on them by [key_name(src)]", LOG_ATTACK, color="red")
		log_message("[key_name(who)] is having [what] put on them by [key_name(src)]", LOG_ATTACK, color="red", log_globally=FALSE)
		if(do_mob(src, who, what.equip_delay_other))
			if(what && Adjacent(who) && what.mob_can_equip(who, src, final_where, TRUE, TRUE))
				if(temporarilyRemoveItemFromInventory(what))
					if(where_list)
						if(!who.put_in_hand(what, where_list[2]))
							what.forceMove(get_turf(who))
					else
						who.equip_to_slot(what, where, TRUE)
					who.log_message("[key_name(who)] had [what] put on them by [key_name(src)]", LOG_ATTACK, color="red")
					log_message("[key_name(who)] had [what] put on them by [key_name(src)]", LOG_ATTACK, color="red", log_globally=FALSE)

/mob/living/proc/do_jitter_animation(jitteriness)
	var/amplitude = min(4, (jitteriness/100) + 1)
	var/pixel_x_diff = rand(-amplitude, amplitude)
	var/pixel_y_diff = rand(-amplitude/3, amplitude/3)
	animate(src, pixel_x = pixel_x_diff, pixel_y = pixel_y_diff , time = 2, loop = 6, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
	animate(pixel_x = -pixel_x_diff , pixel_y = -pixel_y_diff , time = 2, flags = ANIMATION_RELATIVE)

/mob/living/cancel_camera()
	..()
	cameraFollow = null

/mob/living/proc/can_track(mob/living/user)
	//basic fast checks go first. When overriding this proc, I recommend calling ..() at the end.
	if(SEND_SIGNAL(src, COMSIG_LIVING_CAN_TRACK, args) & COMPONENT_CANT_TRACK)
		return FALSE
	var/turf/T = get_turf(src)
	if(!T)
		return FALSE
	if(is_marx_level(T.z)) //dont detect mobs on centcom
		return FALSE
	if(user != null && src == user)
		return FALSE
	if(invisibility || alpha == 0)//cloaked
		return FALSE
	return TRUE

//used in datum/reagents/reaction() proc
/mob/living/proc/get_permeability_protection(list/target_zones)
	return 0

/mob/living/proc/harvest(mob/living/user) //used for extra objects etc. in butchering
	return

/mob/living/can_hold_items(obj/item/I)
	return usable_hands && ..()

/mob/living/canUseTopic(atom/movable/M, be_close=FALSE, no_dexterity=FALSE, no_tk=FALSE, need_hands = FALSE, floor_okay=FALSE)
	if(!(mobility_flags & MOBILITY_UI) && !floor_okay)
		to_chat(src, span_warning("You can't do it right now!"))
		return FALSE
	if(be_close && !Adjacent(M) && (M.loc != src))
		if(no_tk)
			to_chat(src, span_warning("Too far away!"))
			return FALSE
		var/datum/dna/D = has_dna()
		if(!D)
			to_chat(src, span_warning("Too far away!"))
			return FALSE
	if(need_hands && !can_hold_items(isitem(M) ? M : null)) //almost redundant if it weren't for mobs,
		to_chat(src, span_warning("You are unable to do this!"))
		return FALSE
	if(!no_dexterity && !ISADVANCEDTOOLUSER(src))
		to_chat(src, span_warning("You lack the dexterity to do this!"))
		return FALSE
	return TRUE

/mob/living/proc/can_use_guns(obj/item/G)//actually used for more than guns!
	if(G.trigger_guard == TRIGGER_GUARD_NONE)
		to_chat(src, span_warning("It is unable to shoot!"))
		return FALSE
	if(G.trigger_guard != TRIGGER_GUARD_ALLOW_ALL && !ISADVANCEDTOOLUSER(src))
		to_chat(src, span_warning("You try to shoot from [G.name], but nothing happens!"))
		return FALSE
	return TRUE

/mob/living/proc/update_stamina()
	return

/mob/living/throw_at(atom/target, range, speed, mob/thrower, spin=1, diagonals_first = 0, datum/callback/callback, force, gentle = FALSE, quickstart = TRUE)
	stop_pulling()
	. = ..()

// Called when we are hit by a bolt of polymorph and changed
// Generally the mob we are currently in is about to be deleted
/mob/living/proc/wabbajack_act(mob/living/new_mob)
	new_mob.name = real_name
	new_mob.real_name = real_name

	if(mind)
		mind.transfer_to(new_mob)
	else
		new_mob.key = key

/mob/living/anti_magic_check(magic = TRUE, holy = FALSE, tinfoil = FALSE, chargecost = 1, self = FALSE)
	. = ..()
	if(.)
		return
	if((magic && HAS_TRAIT(src, TRAIT_ANTIMAGIC)) || (holy && HAS_TRAIT(src, TRAIT_HOLY)))
		return src

/mob/living/proc/fakefireextinguish()
	return

/mob/living/proc/fakefire()
	return

/mob/living/proc/unfry_mob() //Callback proc to tone down spam from multiple sizzling frying oil dipping.
	REMOVE_TRAIT(src, TRAIT_OIL_FRIED, "cooking_oil_react")

//Mobs on Fire
/mob/living/proc/IgniteMob()
	if(fire_stacks > 0 && !on_fire)
		on_fire = TRUE
		src.visible_message(span_warning("<b>[src]</b> is on fire!") , \
						span_userdanger("You are on fire!"))
		new/obj/effect/dummy/lighting_obj/moblight/fire(src)
		throw_alert("fire", /atom/movable/screen/alert/fire)
		update_fire()
		SEND_SIGNAL(src, COMSIG_LIVING_IGNITED,src)
		return TRUE
	return FALSE

/**
 * Extinguish all fire on the mob
 *
 * This removes all fire stacks, fire effects, alerts, and moods
 * Signals the extinguishing.
 */
/mob/living/proc/extinguish_mob()
	if(!on_fire)
		return
	on_fire = FALSE
	fire_stacks = 0 //If it is not called from set_fire_stacks()
	for(var/obj/effect/dummy/lighting_obj/moblight/fire/F in src)
		qdel(F)
	clear_alert("fire")
	SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "on_fire")
	SEND_SIGNAL(src, COMSIG_LIVING_EXTINGUISHED, src)
	update_fire()

/obj/effect/dummy/lighting_obj/moblight/fire
	name = "fire"
	light_color = LIGHT_COLOR_FIRE
	light_range = LIGHT_RANGE_FIRE

/**
 * Adjust the amount of fire stacks on a mob
 *
 * This modifies the fire stacks on a mob.
 *
 * Vars:
 * * add_fire_stacks: int The amount to modify the fire stacks
 */
/mob/living/proc/adjust_fire_stacks(add_fire_stacks)
	set_fire_stacks(fire_stacks + add_fire_stacks)

/**
 * Set the fire stacks on a mob
 *
 * This sets the fire stacks on a mob, stacks are clamped between -20 and 20.
 * If the fire stacks are reduced to 0 then we will extinguish the mob.
 *
 * Vars:
 * * stacks: int The amount to set fire_stacks to
 */
/mob/living/proc/set_fire_stacks(stacks)
	fire_stacks = clamp(stacks, -20, 20)
	if(fire_stacks <= 0)
		extinguish_mob()

//Share fire evenly between the two mobs
//Called in MobBump() and Crossed()
/mob/living/proc/spreadFire(mob/living/L)
	if(!istype(L))
		return

	if(on_fire)
		if(L.on_fire) // If they were also on fire
			var/firesplit = (fire_stacks + L.fire_stacks)/2
			set_fire_stacks(firesplit)
			L.set_fire_stacks(firesplit)
		else // If they were not
			set_fire_stacks(fire_stacks / 2)
			L.adjust_fire_stacks(fire_stacks)
			if(L.IgniteMob()) // Ignite them
				log_game("[key_name(src)] bumped into [key_name(L)] and set them on fire")

	else if(L.on_fire) // If they were on fire and we were not
		L.set_fire_stacks(L.fire_stacks / 2)
		adjust_fire_stacks(L.fire_stacks)
		IgniteMob() // Ignite us

//Mobs on Fire end

// used by secbot and monkeys Crossed
/mob/living/proc/knockOver(mob/living/carbon/C)
	if(C.key) //save us from monkey hordes
		C.visible_message("<span class='warning'>[pick( \
						"[C] stumbles over [name]!", \
						"[C] jumps over [name]!", \
						"[C] flies over  [name]!", \
						"[C] performs a tactical somersault over [name] and falls!", \
						"[C] knocks over [name]!", \
						"[C] bounces from [name]!")]</span>")
	C.Paralyze(40)

/mob/living/can_be_pulled()
	return ..() && !(buckled?.buckle_prevents_pull)


/// Called when mob changes from a standing position into a prone while lacking the ability to stand up at the moment.
/mob/living/proc/on_fall()
	return

/mob/living/forceMove(atom/destination)
	if(!currently_z_moving)
		stop_pulling()
		if(buckled && !HAS_TRAIT(src, TRAIT_CANNOT_BE_UNBUCKLED))
			buckled.unbuckle_mob(src, force = TRUE)
		if(has_buckled_mobs())
			unbuckle_all_mobs(force = TRUE)
	. = ..()
	if(. && client)
		reset_perspective()


/mob/living/proc/update_z(new_z) // 1+ to register, null to unregister
	if (registered_z != new_z)
		if (registered_z)
			SSmobs.clients_by_zlevel[registered_z] -= src
		if (client)
			if (new_z)
				//Figure out how many clients were here before
				var/oldlen = SSmobs.clients_by_zlevel[new_z].len
				SSmobs.clients_by_zlevel[new_z] += src
				for (var/I in length(SSidlenpcpool.idle_mobs_by_zlevel[new_z]) to 1 step -1) //Backwards loop because we're removing (guarantees optimal rather than worst-case performance), it's fine to use .len here but doesn't compile on 511
					var/mob/living/simple_animal/SA = SSidlenpcpool.idle_mobs_by_zlevel[new_z][I]
					if (SA)
						if(oldlen == 0)
							//Start AI idle if nobody else was on this z level before (mobs will switch off when this is the case)
							SA.toggle_ai(AI_IDLE)

						//If they are also within a close distance ask the AI if it wants to wake up
						if(get_dist(get_turf(src), get_turf(SA)) < MAX_SIMPLEMOB_WAKEUP_RANGE)
							SA.consider_wakeup() // Ask the mob if it wants to turn on it's AI
					//They should clean up in destroy, but often don't so we get them here
					else
						SSidlenpcpool.idle_mobs_by_zlevel[new_z] -= SA


			registered_z = new_z
		else
			registered_z = null

/mob/living/onTransitZ(old_z,new_z)
	..()
	update_z(new_z)

/mob/living/MouseDrop_T(atom/dropping, atom/user)
	var/mob/living/U = user
	if(isliving(dropping))
		var/mob/living/M = dropping
		if(M.can_be_held && U.pulling == M)
			M.mob_try_pickup(U)//blame kevinz
			return//dont open the mobs inventory if you are picking them up
	. = ..()

/mob/living/proc/mob_pickup(mob/living/L)
	var/obj/item/clothing/head/mob_holder/holder = new(get_turf(src), src, held_state, head_icon, held_lh, held_rh, worn_slot_flags)
	L.visible_message(span_warning("[L] picks up [src]!"))
	L.put_in_hands(holder)

/mob/living/proc/set_name()
	numba = rand(1, 1000)
	name = "[name] ([numba])"
	real_name = name

/mob/living/proc/mob_try_pickup(mob/living/user)
	if(!ishuman(user))
		return
	if(user.get_active_held_item())
		to_chat(user, span_warning("No free hands!"))
		return FALSE
	if(buckled)
		to_chat(user, span_warning("<b>[src]</b> is buckled to something!"))
		return FALSE
	user.visible_message(span_warning("<b>[user]</b> starts to pick up <b>[src]</b>!") , \
					span_danger("You start to pick up <b>[src]</b>...") , null, null, src)
	to_chat(src, span_userdanger("<b>[user]</b> is starting to pick you up!"))
	if(!do_after(user, 20, target = src))
		return FALSE
	mob_pickup(user)
	return TRUE

/mob/living/reset_perspective(atom/A)
	if(..())
		update_sight()
		if(client.eye && client.eye != src)
			var/atom/AT = client.eye
			AT.get_remote_view_fullscreens(src)
		else
			clear_fullscreen("remote_view", 0)

/mob/living/vv_edit_var(var_name, var_value)
	switch(var_name)
		if (NAMEOF(src, maxHealth))
			if (!isnum(var_value) || var_value <= 0)
				return FALSE
		if(NAMEOF(src, health)) //this doesn't work. gotta use procs instead.
			return FALSE
		if(NAMEOF(src, druggy))
			set_drugginess(var_value)
			. = TRUE
		if(NAMEOF(src, resting))
			set_resting(var_value)
			. = TRUE
		if(NAMEOF(src, fire_stacks))
			set_fire_stacks(var_value)
			. = TRUE
		if(NAMEOF(src, lying_angle))
			set_lying_angle(var_value)
			. = TRUE
		if(NAMEOF(src, buckled))
			set_buckled(var_value)
			. = TRUE
		if(NAMEOF(src, num_legs))
			set_num_legs(var_value)
			. = TRUE
		if(NAMEOF(src, usable_legs))
			set_usable_legs(var_value)
			. = TRUE
		if(NAMEOF(src, num_hands))
			set_num_hands(var_value)
			. = TRUE
		if(NAMEOF(src, usable_hands))
			set_usable_hands(var_value)
			. = TRUE
		if(NAMEOF(src, body_position))
			set_body_position(var_value)
			. = TRUE

	if(!isnull(.))
		datum_flags |= DF_VAR_EDITED
		return

	. = ..()

	switch(var_name)
		if(NAMEOF(src, maxHealth))
			updatehealth()
		if(NAMEOF(src, resize))
			update_transform()
		if(NAMEOF(src, lighting_alpha))
			sync_lighting_plane_alpha()


/mob/living/vv_get_header()
	. = ..()
	var/refid = REF(src)
	. += {"
		<br><font size='1'>[VV_HREF_TARGETREF(refid, VV_HK_GIVE_DIRECT_CONTROL, "[ckey || "no ckey"]")] / [VV_HREF_TARGETREF_1V(refid, VV_HK_BASIC_EDIT, "[real_name || "no real name"]", NAMEOF(src, real_name))]</font>
		<br><font size='1'>
			BRUTE:<font size='1'><a href='?_src_=vars;[HrefToken()];mobToDamage=[refid];adjustDamage=brute' id='brute'>[getBruteLoss()]</a>
			FIRE:<font size='1'><a href='?_src_=vars;[HrefToken()];mobToDamage=[refid];adjustDamage=fire' id='fire'>[getFireLoss()]</a>
			TOXIN:<font size='1'><a href='?_src_=vars;[HrefToken()];mobToDamage=[refid];adjustDamage=toxin' id='toxin'>[getToxLoss()]</a>
			OXY:<font size='1'><a href='?_src_=vars;[HrefToken()];mobToDamage=[refid];adjustDamage=oxygen' id='oxygen'>[getOxyLoss()]</a>
			BRAIN:<font size='1'><a href='?_src_=vars;[HrefToken()];mobToDamage=[refid];adjustDamage=brain' id='brain'>[getOrganLoss(ORGAN_SLOT_BRAIN)]</a>
			STAMINA:<font size='1'><a href='?_src_=vars;[HrefToken()];mobToDamage=[refid];adjustDamage=stamina' id='stamina'>[getStaminaLoss()]</a>
		</font>
	"}

/mob/living/proc/move_to_error_room()
	var/obj/effect/landmark/error/error_landmark = locate(/obj/effect/landmark/error) in GLOB.landmarks_list
	if(error_landmark)
		forceMove(error_landmark.loc)
	else
		forceMove(locate(4,4,1)) //Even if the landmark is missing, this should put them in the error room.
		//If you're here from seeing this error, I'm sorry. I'm so very sorry. The error landmark should be a sacred object that nobody has any business messing with, and someone did!
		//Consider seeing a therapist.
		var/ERROR_ERROR_LANDMARK_ERROR = "ERROR-ERROR: ERROR landmark missing!"
		log_mapping(ERROR_ERROR_LANDMARK_ERROR)
		CRASH(ERROR_ERROR_LANDMARK_ERROR)

/**
 * Changes the inclination angle of a mob, used by humans and others to differentiate between standing up and prone positions.
 *
 * In BYOND-angles 0 is NORTH, 90 is EAST, 180 is SOUTH and 270 is WEST.
 * This usually means that 0 is standing up, 90 and 270 are horizontal positions to right and left respectively, and 180 is upside-down.
 * Mobs that do now follow these conventions due to unusual sprites should require a special handling or redefinition of this proc, due to the density and layer changes.
 * The return of this proc is the previous value of the modified lying_angle if a change was successful (might include zero), or null if no change was made.
 */
/mob/living/proc/set_lying_angle(new_lying)
	if(new_lying == lying_angle)
		return
	. = lying_angle
	lying_angle = new_lying
	if(lying_angle != lying_prev)
		update_transform()
		lying_prev = lying_angle


/**
 * add_body_temperature_change Adds modifications to the body temperature
 *
 * This collects all body temperature changes that the mob is experiencing to the list body_temp_changes
 * the aggrogate result is used to derive the new body temperature for the mob
 *
 * arguments:
 * * key_name (str) The unique key for this change, if it already exist it will be overridden
 * * amount (int) The amount of change from the base body temperature
 */
/mob/living/proc/add_body_temperature_change(key_name, amount)
	body_temp_changes["[key_name]"] = amount

/**
 * remove_body_temperature_change Removes the modifications to the body temperature
 *
 * This removes the recorded change to body temperature from the body_temp_changes list
 *
 * arguments:
 * * key_name (str) The unique key for this change that will be removed
 */
/mob/living/proc/remove_body_temperature_change(key_name)
	body_temp_changes -= key_name

/**
 * get_body_temp_normal_change Returns the aggregate change to body temperature
 *
 * This aggregates all the changes in the body_temp_changes list and returns the result
 */
/mob/living/proc/get_body_temp_normal_change()
	var/total_change = 0
	if(body_temp_changes.len)
		for(var/change in body_temp_changes)
			total_change += body_temp_changes["[change]"]
	return total_change

/**
 * get_body_temp_normal Returns the mobs normal body temperature with any modifications applied
 *
 * This applies the result from proc/get_body_temp_normal_change() against the 310.15 and returns the result
 *
 * arguments:
 * * apply_change (optional) Default True This applies the changes to body temperature normal
 */
/mob/living/proc/get_body_temp_normal(apply_change=TRUE)
	if(!apply_change)
		return 310.15
	return 310.15 + get_body_temp_normal_change()

//Checks if the user is incapacitated or on cooldown.
/mob/living/proc/can_look_up()
	return !(incapacitated(ignore_restraints = TRUE))

/**
 * look_up Changes the perspective of the mob to any openspace turf above the mob
 *
 * This also checks if an openspace turf is above the mob before looking up or resets the perspective if already looking up
 *
 */
/mob/living/proc/look_up()
	if(client.perspective != MOB_PERSPECTIVE) //We are already looking up.
		stop_look_up()
	if(!can_look_up())
		return
	changeNext_move(CLICK_CD_LOOK_UP)
	RegisterSignal(src, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(stop_look_up)) //We stop looking up if we move.
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(start_look_up)) //We start looking again after we move.
	start_look_up()

/mob/living/proc/start_look_up()
	SIGNAL_HANDLER
	var/turf/ceiling = get_step_multiz(src, UP)
	if(!ceiling) //We are at the highest z-level.
		to_chat(src, span_warning("There is a ceiling?"))
		return
	else if(!istransparentturf(ceiling)) //There is no turf we can look through above us
		var/turf/front_hole = get_step(ceiling, dir)
		if(istransparentturf(front_hole))
			ceiling = front_hole
		else
			var/list/checkturfs = block(locate(x-1,y-1,ceiling.z),locate(x+1,y+1,ceiling.z))-ceiling-front_hole //Try find hole near of us
			for(var/turf/checkhole in checkturfs)
				if(istransparentturf(checkhole))
					ceiling = checkhole
					break
		if(!istransparentturf(ceiling))
			to_chat(src, span_warning("The ceiling is opaque."))
			return

	reset_perspective(ceiling)

/mob/living/proc/stop_look_up()
	SIGNAL_HANDLER
	reset_perspective()

/mob/living/proc/end_look_up()
	stop_look_up()
	UnregisterSignal(src, COMSIG_MOVABLE_PRE_MOVE)
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)

/**
 * look_down Changes the perspective of the mob to any openspace turf below the mob
 *
 * This also checks if an openspace turf is below the mob before looking down or resets the perspective if already looking up
 *
 */
/mob/living/proc/look_down()
	if(client.perspective != MOB_PERSPECTIVE) //We are already looking down.
		stop_look_down()
	if(!can_look_up()) //if we cant look up, we cant look down.
		return
	changeNext_move(CLICK_CD_LOOK_UP)
	RegisterSignal(src, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(stop_look_down)) //We stop looking down if we move.
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(start_look_down)) //We start looking again after we move.
	start_look_down()

/mob/living/proc/start_look_down()
	SIGNAL_HANDLER
	var/turf/floor = get_turf(src)
	var/turf/lower_level = get_step_multiz(floor, DOWN)
	if(!lower_level) //We are at the lowest z-level.
		to_chat(src, span_warning("Nothing to see."))
		return
	else if(!istransparentturf(floor)) //There is no turf we can look through below us
		var/turf/front_hole = get_step(floor, dir)
		if(istransparentturf(front_hole))
			floor = front_hole
			lower_level = get_step_multiz(front_hole, DOWN)
		else
			var/list/checkturfs = block(locate(x-1,y-1,z),locate(x+1,y+1,z))-floor //Try find hole near of us
			for(var/turf/checkhole in checkturfs)
				if(istransparentturf(checkhole))
					floor = checkhole
					lower_level = get_step_multiz(checkhole, DOWN)
					break
		if(!istransparentturf(floor))
			to_chat(src, span_warning("The floor is opaque."))
			return

	reset_perspective(lower_level)

/mob/living/proc/stop_look_down()
	SIGNAL_HANDLER
	reset_perspective()

/mob/living/proc/end_look_down()
	stop_look_down()
	UnregisterSignal(src, COMSIG_MOVABLE_PRE_MOVE)
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)


/mob/living/set_stat(new_stat)
	. = ..()
	if(isnull(.))
		return

	switch(.) //Previous stat.
		if(CONSCIOUS)
			if(stat >= UNCONSCIOUS)
				ADD_TRAIT(src, TRAIT_IMMOBILIZED, TRAIT_KNOCKEDOUT)
			ADD_TRAIT(src, TRAIT_HANDS_BLOCKED, STAT_TRAIT)
			ADD_TRAIT(src, TRAIT_INCAPACITATED, STAT_TRAIT)
			ADD_TRAIT(src, TRAIT_FLOORED, STAT_TRAIT)
		if(SOFT_CRIT)
			if(stat >= UNCONSCIOUS)
				ADD_TRAIT(src, TRAIT_IMMOBILIZED, TRAIT_KNOCKEDOUT) //adding trait sources should come before removing to avoid unnecessary updates
			if(pulledby)
				REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, PULLED_WHILE_SOFTCRIT_TRAIT)
		if(UNCONSCIOUS)
			if(stat != HARD_CRIT)
				cure_blind(UNCONSCIOUS_TRAIT)
		if(HARD_CRIT)
			if(stat != UNCONSCIOUS)
				cure_blind(UNCONSCIOUS_TRAIT)
		if(DEAD)
			remove_from_dead_mob_list()
			add_to_alive_mob_list()
	switch(stat) //Current stat.
		if(CONSCIOUS)
			if(. >= UNCONSCIOUS)
				REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, TRAIT_KNOCKEDOUT)
			REMOVE_TRAIT(src, TRAIT_HANDS_BLOCKED, STAT_TRAIT)
			REMOVE_TRAIT(src, TRAIT_INCAPACITATED, STAT_TRAIT)
			REMOVE_TRAIT(src, TRAIT_FLOORED, STAT_TRAIT)
			REMOVE_TRAIT(src, TRAIT_CRITICAL_CONDITION, STAT_TRAIT)
		if(SOFT_CRIT)
			if(pulledby)
				ADD_TRAIT(src, TRAIT_IMMOBILIZED, PULLED_WHILE_SOFTCRIT_TRAIT) //adding trait sources should come before removing to avoid unnecessary updates
			if(. >= UNCONSCIOUS)
				REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, TRAIT_KNOCKEDOUT)
			ADD_TRAIT(src, TRAIT_CRITICAL_CONDITION, STAT_TRAIT)
		if(UNCONSCIOUS)
			if(. != HARD_CRIT)
				become_blind(UNCONSCIOUS_TRAIT)
			if(health <= crit_threshold && !HAS_TRAIT(src, TRAIT_NOSOFTCRIT))
				ADD_TRAIT(src, TRAIT_CRITICAL_CONDITION, STAT_TRAIT)
			else
				REMOVE_TRAIT(src, TRAIT_CRITICAL_CONDITION, STAT_TRAIT)
		if(HARD_CRIT)
			if(. != UNCONSCIOUS)
				become_blind(UNCONSCIOUS_TRAIT)
			ADD_TRAIT(src, TRAIT_CRITICAL_CONDITION, STAT_TRAIT)
		if(DEAD)
			REMOVE_TRAIT(src, TRAIT_CRITICAL_CONDITION, STAT_TRAIT)
			remove_from_alive_mob_list()
			add_to_dead_mob_list()


///Reports the event of the change in value of the buckled variable.
/mob/living/proc/set_buckled(new_buckled)
	if(new_buckled == buckled)
		return
	SEND_SIGNAL(src, COMSIG_LIVING_SET_BUCKLED, new_buckled)
	. = buckled
	buckled = new_buckled
	if(buckled)
		if(!HAS_TRAIT(buckled, TRAIT_NO_IMMOBILIZE))
			ADD_TRAIT(src, TRAIT_IMMOBILIZED, BUCKLED_TRAIT)
		switch(buckled.buckle_lying)
			if(NO_BUCKLE_LYING) // The buckle doesn't force a lying angle.
				REMOVE_TRAIT(src, TRAIT_FLOORED, BUCKLED_TRAIT)
			if(0) // Forcing to a standing position.
				REMOVE_TRAIT(src, TRAIT_FLOORED, BUCKLED_TRAIT)
				set_body_position(STANDING_UP)
				set_lying_angle(0)
			else // Forcing to a lying position.
				ADD_TRAIT(src, TRAIT_FLOORED, BUCKLED_TRAIT)
				set_body_position(LYING_DOWN)
				set_lying_angle(buckled.buckle_lying)
	else
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, BUCKLED_TRAIT)
		REMOVE_TRAIT(src, TRAIT_FLOORED, BUCKLED_TRAIT)
		if(.) // We unbuckled from something.
			var/atom/movable/old_buckled = .
			if(old_buckled.buckle_lying == 0 && (resting || HAS_TRAIT(src, TRAIT_FLOORED))) // The buckle forced us to stay up (like a chair)
				set_lying_down() // We want to rest or are otherwise floored, so let's drop on the ground.

/mob/living/set_pulledby(new_pulledby)
	. = ..()
	if(. == FALSE) //null is a valid value here, we only want to return if FALSE is explicitly passed.
		return
	if(pulledby)
		if(!. && stat == SOFT_CRIT)
			ADD_TRAIT(src, TRAIT_IMMOBILIZED, PULLED_WHILE_SOFTCRIT_TRAIT)
	else if(. && stat == SOFT_CRIT)
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, PULLED_WHILE_SOFTCRIT_TRAIT)


/// Updates the grab state of the mob and updates movespeed
/mob/living/setGrabState(newstate)
	. = ..()
	switch(grab_state)
		if(GRAB_PASSIVE)
			remove_movespeed_modifier(MOVESPEED_ID_MOB_GRAB_STATE)
		if(GRAB_AGGRESSIVE)
			add_movespeed_modifier(/datum/movespeed_modifier/grab_slowdown/aggressive)
		if(GRAB_NECK)
			add_movespeed_modifier(/datum/movespeed_modifier/grab_slowdown/neck)
		if(GRAB_KILL)
			add_movespeed_modifier(/datum/movespeed_modifier/grab_slowdown/kill)


/// Only defined for carbons who can wear masks and helmets, we just assume other mobs have visible faces
/mob/living/proc/is_face_visible()
	return TRUE


///Proc to modify the value of num_legs and hook behavior associated to this event.
/mob/living/proc/set_num_legs(new_value)
	if(num_legs == new_value)
		return
	. = num_legs
	num_legs = new_value


///Proc to modify the value of usable_legs and hook behavior associated to this event.
/mob/living/proc/set_usable_legs(new_value)
	if(usable_legs == new_value)
		return
	. = usable_legs
	usable_legs = new_value

	if(new_value > .) // Gained leg usage.
		REMOVE_TRAIT(src, TRAIT_FLOORED, LACKING_LOCOMOTION_APPENDAGES_TRAIT)
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, LACKING_LOCOMOTION_APPENDAGES_TRAIT)
	else if(!(movement_type & (FLYING | FLOATING))) //Lost leg usage, not flying.
		if(!usable_legs)
			ADD_TRAIT(src, TRAIT_FLOORED, LACKING_LOCOMOTION_APPENDAGES_TRAIT)
			if(!usable_hands)
				ADD_TRAIT(src, TRAIT_IMMOBILIZED, LACKING_LOCOMOTION_APPENDAGES_TRAIT)

	if(usable_legs < default_num_legs)
		var/limbless_slowdown = (default_num_legs - usable_legs) * 3
		if(!usable_legs && usable_hands < default_num_hands)
			limbless_slowdown += (default_num_hands - usable_hands) * 3
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/limbless, multiplicative_slowdown = limbless_slowdown)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/limbless)


///Proc to modify the value of num_hands and hook behavior associated to this event.
/mob/living/proc/set_num_hands(new_value)
	if(num_hands == new_value)
		return
	. = num_hands
	num_hands = new_value


///Proc to modify the value of usable_hands and hook behavior associated to this event.
/mob/living/proc/set_usable_hands(new_value)
	if(usable_hands == new_value)
		return
	. = usable_hands
	usable_hands = new_value

	if(new_value > .) // Gained hand usage.
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, LACKING_LOCOMOTION_APPENDAGES_TRAIT)
	else if(!(movement_type & (FLYING | FLOATING)) && !usable_hands && !usable_legs) //Lost a hand, not flying, no hands left, no legs.
		ADD_TRAIT(src, TRAIT_IMMOBILIZED, LACKING_LOCOMOTION_APPENDAGES_TRAIT)


/// Whether or not this mob will escape from storages while being picked up/held.
/mob/living/proc/will_escape_storage()
	return FALSE

/// Sets the mob's hunger levels to a safe overall level. Useful for TRAIT_NOHUNGER species changes.
/mob/living/proc/set_safe_hunger_level()
	// Nutrition reset and alert clearing.
	nutrition = NUTRITION_LEVEL_FED
	hydration = HYDRATION_LEVEL_NORMAL + 15
	clear_alert("nutrition")
	satiety = 0

	// Trait removal if obese
	if(HAS_TRAIT_FROM(src, TRAIT_FAT, OBESITY))
		if(overeatduration >= (200 SECONDS))
			to_chat(src, span_notice("Your transformation restores your body's natural fitness!"))

		REMOVE_TRAIT(src, TRAIT_FAT, OBESITY)
		remove_movespeed_modifier(/datum/movespeed_modifier/obesity)
		update_inv_w_uniform()
		update_inv_wear_suit()

	// Reset overeat duration.
	overeatduration = 0


/// Changes the value of the [living/body_position] variable.
/mob/living/proc/set_body_position(new_value)
	if(body_position == new_value)
		return
	. = body_position
	body_position = new_value
	SEND_SIGNAL(src, COMSIG_LIVING_SET_BODY_POSITION)
	if(new_value == LYING_DOWN) // From standing to lying down.
		on_lying_down()
	else // From lying down to standing up.
		on_standing_up()


/// Proc to append behavior to the condition of being floored. Called when the condition starts.
/mob/living/proc/on_floored_start()
	if(body_position == STANDING_UP) //force them on the ground
		set_lying_angle(pick(90, 270))
		set_body_position(LYING_DOWN)
		on_fall()


/// Proc to append behavior to the condition of being floored. Called when the condition ends.
/mob/living/proc/on_floored_end()
	if(!resting)
		get_up()


/// Proc to append behavior to the condition of being handsblocked. Called when the condition starts.
/mob/living/proc/on_handsblocked_start()
	drop_all_held_items()
	ADD_TRAIT(src, TRAIT_UI_BLOCKED, TRAIT_HANDS_BLOCKED)
	ADD_TRAIT(src, TRAIT_PULL_BLOCKED, TRAIT_HANDS_BLOCKED)


/// Proc to append behavior to the condition of being handsblocked. Called when the condition ends.
/mob/living/proc/on_handsblocked_end()
	REMOVE_TRAIT(src, TRAIT_UI_BLOCKED, TRAIT_HANDS_BLOCKED)
	REMOVE_TRAIT(src, TRAIT_PULL_BLOCKED, TRAIT_HANDS_BLOCKED)


/// Returns the attack damage type of a living mob such as [BRUTE].
/mob/living/proc/get_attack_type()
	return BRUTE


/**
 * Apply a martial art move from src to target.
 *
 * This is used to process martial art attacks against nonhumans.
 * It is also used to process martial art attacks by nonhumans, even against humans
 * Human vs human attacks are handled in species code right now.
 */
/mob/living/proc/apply_martial_art(mob/living/target, modifiers, is_grab = FALSE)
	if(HAS_TRAIT(target, TRAIT_MARTIAL_ARTS_IMMUNE))
		return FALSE
	var/datum/martial_art/style = mind?.martial_art
	var/attack_result = FALSE
	if (style)
		switch (a_intent)
			if (INTENT_GRAB)
				attack_result = style.grab_act(src, target)
			if (INTENT_HARM)
				if (HAS_TRAIT(src, TRAIT_PACIFISM))
					return FALSE
				attack_result = style.harm_act(src, target)
			if (INTENT_DISARM)
				attack_result = style.disarm_act(src, target)
			if (INTENT_HELP)
				attack_result = style.help_act(src, target)
	return attack_result
