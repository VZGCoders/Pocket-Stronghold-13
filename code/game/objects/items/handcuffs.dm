/obj/item/restraints
	breakoutchance = 100
	breakouttime = 60 SECONDS
	dye_color = DYE_PRISONER

/obj/item/restraints/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] is strangling [user.p_them()]self with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	return(OXYLOSS)

/proc/getnoun(number, one, two, five)
	var/n = abs(number)
	n = n % 100
	if (n >= 11 &&  n <= 19)
		return five

	n = n % 10
	switch(n)
		if(1)
			return one
		if(2 to 4)
			return two
	return five

/obj/item/restraints/Destroy()
	if(iscarbon(loc))
		var/mob/living/carbon/M = loc
		if(M.handcuffed == src)
			M.set_handcuffed(null)
			M.update_handcuffed()
			if(M.buckled && M.buckled.buckle_requires_restraints)
				M.buckled.unbuckle_mob(M)
		if(M.legcuffed == src)
			M.legcuffed = null
			M.update_inv_legcuffed()
	return ..()

//Handcuffs

/obj/item/restraints/handcuffs
	name = "handcuffs"
	desc = "Use this to keep prisoners in line."
	gender = PLURAL
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "handcuff"
	worn_icon_state = "handcuff"
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	throwforce = 0
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 3
	throw_range = 5
	custom_materials = list(/datum/material/iron=500)
	breakouttime = 30 SECONDS
	breakoutchance = 50
	custom_price = PAYCHECK_HARD * 0.35
	var/cuffsound = 'sound/weapons/handcuffs.ogg'
	var/trashtype = null //for disposable cuffs

/obj/item/restraints/handcuffs/attack(mob/living/carbon/C, mob/living/user)
	if(!istype(C))
		return

	SEND_SIGNAL(C, COMSIG_CARBON_CUFF_ATTEMPTED, user)

	if(iscarbon(user) && (HAS_TRAIT(user, TRAIT_CLUMSY) && prob(50)))
		to_chat(user, span_warning("Uh... how do those things work?!"))
		apply_cuffs(user,user)
		return

	if(!C.handcuffed)
		if(C.canBeHandcuffed())
			C.visible_message(span_danger("[user] is trying to put [name] on [C]!"), \
								span_userdanger("[user] is trying to put [name] on you!"))

			playsound(loc, cuffsound, 30, TRUE, -2)
			log_combat(user, C, "attempted to handcuff")
			if(do_mob(user, C, 30, timed_action_flags = IGNORE_SLOWDOWNS) && C.canBeHandcuffed())
				apply_cuffs(C, user)
				C.visible_message(span_notice("[user] handcuffs [C]."), \
									span_userdanger("[user] handcuffs you."))
				SSblackbox.record_feedback("tally", "handcuffs", 1, type)

				log_combat(user, C, "handcuffed")
			else
				to_chat(user, span_warning("You fail to handcuff [C]!"))
				log_combat(user, C, "failed to handcuff")
		else
			to_chat(user, span_warning("[C] doesn't have two hands..."))

/obj/item/restraints/handcuffs/proc/apply_cuffs(mob/living/carbon/target, mob/user, dispense = 0)
	if(target.handcuffed)
		return

	if(!user.temporarilyRemoveItemFromInventory(src) && !dispense)
		return

	var/obj/item/restraints/handcuffs/cuffs = src
	if(trashtype)
		cuffs = new trashtype()
	else if(dispense)
		cuffs = new type()

	cuffs.forceMove(target)
	target.set_handcuffed(cuffs)

	target.update_handcuffed()
	if(trashtype && !dispense)
		qdel(src)
	return

//Legcuffs

/obj/item/restraints/legcuffs
	name = "leg cuffs"
	desc = "Use this to keep prisoners in line."
	gender = PLURAL
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "handcuff"
	flags_1 = CONDUCT_1
	throwforce = 0
	w_class = WEIGHT_CLASS_NORMAL
	slowdown = 7
	breakouttime = 10 SECONDS
	breakoutchance = 53.7 // 78.563% and 90.075% to break out on second and third try respectively

/obj/item/restraints/legcuffs/beartrap
	name = "bear trap"
	desc = "A trap used to catch bears and other legged creatures."
	throw_speed = 1
	throw_range = 1
	icon_state = "beartrap"
	breakouttime = 10 SECONDS
	breakoutchance = 100
	var/armed = 0
	var/trap_damage = 20

/obj/item/restraints/legcuffs/beartrap/Initialize()
	. = ..()
	update_icon()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(spring_trap),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/item/restraints/legcuffs/beartrap/update_icon_state()
	icon_state = "[initial(icon_state)][armed]"
	return ..()

/obj/item/restraints/legcuffs/beartrap/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] is sticking [user.p_them()] head in the [src.name]! It looks like [user.p_theyre()] trying to commit suicide!"))
	playsound(loc, 'sound/weapons/bladeslice.ogg', 50, TRUE, -1)
	return (BRUTELOSS)

/obj/item/restraints/legcuffs/beartrap/attack_self(mob/user)
	. = ..()
	if(!ishuman(user) || user.stat != CONSCIOUS || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return
	armed = !armed
	update_icon()
	to_chat(user, span_notice("[src] is now [armed ? "armed" : "disarmed"]"))

/obj/item/restraints/legcuffs/beartrap/proc/close_trap()
	armed = FALSE
	update_icon()
	playsound(src, 'sound/effects/snap.ogg', 50, TRUE)

/obj/item/restraints/legcuffs/beartrap/proc/spring_trap(datum/source, AM as mob|obj)
	SIGNAL_HANDLER
	if(armed && isturf(loc))
		if(isliving(AM))
			var/mob/living/L = AM
			var/snap = TRUE
			if(L.movement_type & (FLYING|FLOATING)) //don't close the trap if they're flying/floating over it.
				snap = FALSE

			var/def_zone = BODY_ZONE_CHEST
			if(snap && iscarbon(L))
				var/mob/living/carbon/C = L
				if(C.body_position == STANDING_UP)
					def_zone = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
					if(!C.legcuffed && C.num_legs >= 2) //beartrap can't cuff your leg if there's already a beartrap or legcuffs, or you don't have two legs.
						C.legcuffed = src
						forceMove(C)
						C.update_equipment_speed_mods()
						C.update_inv_legcuffed()
						SSblackbox.record_feedback("tally", "handcuffs", 1, type)
			else if(snap && isanimal(L))
				var/mob/living/simple_animal/SA = L
				if(SA.mob_size <= MOB_SIZE_TINY) //don't close the trap if they're as small as a mouse.
					snap = FALSE
			if(snap)
				close_trap()
				L.visible_message(span_danger("\The [src] ensnares [L]!"), \
					span_userdanger("\The [src] ensnares you!"))
				L.apply_damage(trap_damage, BRUTE, def_zone)

/obj/item/restraints/legcuffs/bola
	name = "bola"
	desc = "A restraining device designed to be thrown at the target. Upon connecting with said target, it will wrap around their legs, making it difficult for them to move quickly."
	icon_state = "bola"
	inhand_icon_state = "bola"
	lefthand_file = 'icons/mob/inhands/weapons/thrown_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/thrown_righthand.dmi'
	breakouttime = 4 SECONDS
	breakoutchance = 100
	gender = NEUTER
	var/knockdown = 0

/obj/item/restraints/legcuffs/bola/throw_at(atom/target, range, speed, mob/thrower, spin=1, diagonals_first = 0, datum/callback/callback, gentle = FALSE, quickstart = TRUE, params)
	if(!..())
		return
	playsound(src.loc,'sound/weapons/bolathrow.ogg', 75, TRUE)

/obj/item/restraints/legcuffs/bola/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(..() || !iscarbon(hit_atom))//if it gets caught or the target can't be cuffed,
		return//abort
	ensnare(hit_atom)

/**
 * Attempts to legcuff someone with the bola
 *
 * Arguments:
 * * C - the carbon that we will try to ensnare
 */
/obj/item/restraints/legcuffs/bola/proc/ensnare(mob/living/carbon/C)
	if(!C.legcuffed && C.num_legs >= 2)
		visible_message(span_danger("\The [src] ensnares [C]!"), span_userdanger("\The [src] ensnares you!"))
		C.legcuffed = src
		forceMove(C)
		C.update_equipment_speed_mods()
		C.update_inv_legcuffed()
		SSblackbox.record_feedback("tally", "handcuffs", 1, type)
		C.Knockdown(knockdown)
		playsound(src, 'sound/effects/snap.ogg', 50, TRUE)

/obj/item/restraints/legcuffs/bola/gonbola
	name = "gonbola"
	desc = "Hey, if you have to be hugged in the legs by anything, it might as well be this little guy."
	icon_state = "gonbola"
	inhand_icon_state = "bola_r"
	breakoutchance = 5
	slowdown = 0
	var/datum/status_effect/gonbola_pacify/effectReference

/obj/item/restraints/legcuffs/bola/gonbola/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(iscarbon(hit_atom))
		var/mob/living/carbon/C = hit_atom
		effectReference = C.apply_status_effect(STATUS_EFFECT_GONBOLAPACIFY)

/obj/item/restraints/legcuffs/bola/gonbola/dropped(mob/user)
	. = ..()
	if(effectReference)
		QDEL_NULL(effectReference)
