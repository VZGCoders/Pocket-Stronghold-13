/obj/structure/demijohn
	name = "demijohn"
	desc = "A rigid container used in brewing."
	density = 1
	layer = ABOVE_MOB_LAYER
	icon = 'dwarfs/icons/structures/workshops.dmi'
	icon_state = "demijohn"
	var/max_volume = 300
	var/timerid
	var/wait_before_start = 1 MINUTES // amount of time to wait before starting the work; also wait before starting to convert a converted product (juice->wine->vinegar)

/obj/structure/demijohn/Initialize()
	. = ..()
	AddComponent(/datum/component/liftable, slowdown = 5, worn_icon='dwarfs/icons/mob/inhand/righthand.dmi', inhand_icon_state="demijohn")
	create_reagents(max_volume)
	RegisterSignal(src, COSMIG_DEMIJOHN_STOP, PROC_REF(restart_fermentation))

/obj/structure/demijohn/Destroy()
	. = ..()
	remove_timer()

/obj/structure/demijohn/proc/remove_timer()
	if(active_timers)
		deltimer(timerid)

/obj/structure/demijohn/attackby(obj/item/I, mob/user, params) // /obj/item/liftable then use parent for interaction and update appearance
	if(istype(I, /obj/item/reagent_containers))
		var/obj/item/reagent_containers/C = I
		var/transfered = C.reagents.trans_to(src, C.amount_per_transfer_from_this, transfered_by=user)
		if(!transfered)
			return FALSE
		stop_fermentation()
		timerid = addtimer(CALLBACK(src, PROC_REF(start_fermentation)), wait_before_start, TIMER_STOPPABLE)
		to_chat(user, span_notice("You transfer [transfered]u to [src]."))
		update_appearance()
	else if(istype(I, /obj/item/liftable))
		var/obj/item/liftable/L = I
		if(!L.parent.reagents)
			return
		var/transfered = L.parent.reagents.trans_to(src, 10, transfered_by=user)
		if(!transfered)
			return FALSE
		stop_fermentation()
		timerid = addtimer(CALLBACK(src, PROC_REF(start_fermentation)), wait_before_start, TIMER_STOPPABLE)
		to_chat(user, span_notice("You transfer [transfered]u to [src]."))
		L.parent.update_appearance()
		update_appearance()
	else
		return ..()

/obj/structure/demijohn/attackby_secondary(obj/item/weapon, mob/user, params)
	. = SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(istype(weapon, /obj/item/reagent_containers))
		var/obj/item/reagent_containers/C = weapon
		var/transfered = reagents.trans_to(C, 10, transfered_by=user)
		if(!transfered)
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		stop_fermentation()
		if(reagents.total_volume)
			timerid = addtimer(CALLBACK(src, PROC_REF(start_fermentation)), wait_before_start, TIMER_STOPPABLE)
		to_chat(user, span_notice("You take [transfered]u from [src]."))
		update_appearance()
	else if(istype(weapon, /obj/item/liftable))
		var/obj/item/liftable/L = weapon
		if(!L.parent.reagents)
			return
		var/transfered = reagents.trans_to(L.parent, 10, transfered_by=user)
		if(!transfered)
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		stop_fermentation()
		if(reagents.total_volume)
			timerid = addtimer(CALLBACK(src, PROC_REF(start_fermentation)), wait_before_start, TIMER_STOPPABLE)
		to_chat(user, span_notice("You take [transfered]u from [src]."))
		L.parent.update_appearance()
		update_appearance()
	else
		return ..()

/obj/structure/demijohn/update_overlays()
	. = ..()
	if(reagents.total_volume)
		var/mutable_appearance/M = mutable_appearance('dwarfs/icons/structures/workshops.dmi', "demijohn_overlay", -FLOAT_LAYER)
		M.color = mix_color_from_reagents(reagents.reagent_list)
		. += M

/obj/structure/demijohn/proc/start_fermentation()
	for(var/datum/reagent/R in reagents.reagent_list)
		SEND_SIGNAL(R, COSMIG_REAGENT_START_FERMENTING, src)

/obj/structure/demijohn/proc/stop_fermentation()
	SIGNAL_HANDLER
	remove_timer() //in case there is a timer running
	for(var/datum/reagent/R in reagents.reagent_list)
		SEND_SIGNAL(R, COSMIG_REAGENT_STOP_FERMENTING, src)

/obj/structure/demijohn/proc/restart_fermentation()
	SIGNAL_HANDLER
	stop_fermentation()
	if(reagents.total_volume)
		timerid = addtimer(CALLBACK(src, PROC_REF(start_fermentation)), wait_before_start, TIMER_STOPPABLE)
