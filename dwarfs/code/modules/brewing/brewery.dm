/obj/structure/brewery
	name = "brewery"
	desc = "A highly sophisticated machine that produces precious liquids."
	anchored = 1
	density = 1
	layer = ABOVE_MOB_LAYER
	icon = 'dwarfs/icons/structures/32x64.dmi'

/obj/structure/brewery/spawner
	icon = 'dwarfs/icons/structures/64x64.dmi'
	icon_state = "brewery"

/obj/structure/brewery/spawner/Initialize()
	. = ..()
	var/turf/T = locate(x+1, y, z)
	if(!istype(T, /turf/open))
		qdel(src)
		return
	var/obj/structure/brewery/l/L = new(get_turf(src))
	var/obj/structure/brewery/r/R = new (T)
	L.right = R
	R.left = L
	qdel(src)

/obj/structure/brewery/l
	icon_state = "brewery_l_closed_empty"
	var/obj/structure/brewery/right
	var/open = FALSE
	var/fuel = 0
	var/working = FALSE
	var/temp = 500

/obj/structure/brewery/l/Destroy()
	. = ..()
	STOP_PROCESSING(SSprocessing, src)
	if(right)
		QDEL_NULL(right)

/obj/structure/brewery/l/Initialize()
	. = ..()
	create_reagents(300)
	START_PROCESSING(SSprocessing, src)

/obj/structure/brewery/l/AltClick(mob/user)
	if(in_range(user, src))
		if(working)
			to_chat(user, span_warning("Cannot open [src] while it's working."))
			return
		open = !open
		update_appearance()
		to_chat(user, span_notice("You [open?"open":"close"] [src]."))
		playsound(src, 'dwarfs/sounds/structures/toggle_open.ogg', 50, TRUE)

/obj/structure/brewery/l/attackby(obj/item/I, mob/user, params)
	if(I.get_fuel())
		if(!open)
			to_chat(user, span_warning("[src] has to be opened first!"))
			return
		fuel += I.get_fuel()
		user.visible_message(span_notice("[user] throws [I] into [src]."), span_notice("You throw [I] into [src]."))
		qdel(I)
		update_appearance()
	else if(istype(I, /obj/item/reagent_containers))
		var/obj/item/reagent_containers/C = I
		var/vol = C.reagents.trans_to(src, C.amount_per_transfer_from_this, transfered_by=user)
		if(!vol)
			return TRUE
		to_chat(user, span_notice("You transfer [vol]u from [C]."))
	else if(I.get_temperature())
		if(!fuel)
			to_chat(user, span_warning("[src] has no fuel."))
			return TRUE
		if(open)
			to_chat(user, span_warning("[src] has to be closed first."))
			return TRUE
		if(working)
			to_chat(user, span_warning("[src] is already lit."))
			return TRUE
		working = TRUE
		update_appearance()
		to_chat(user, span_notice("You light up [src]."))
		playsound(src, 'dwarfs/sounds/effects/ignite.ogg', 50, TRUE)
	else
		return ..()

/obj/structure/brewery/l/attackby_secondary(obj/item/I, mob/user, params)
	. = SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(istype(I, /obj/item/reagent_containers))
		var/obj/item/reagent_containers/C = I
		var/vol = reagents.trans_to(C, C.amount_per_transfer_from_this, transfered_by=user)
		if(!vol)
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		to_chat(user, span_notice("You transfer [vol]u from [src]."))

/obj/structure/brewery/l/update_icon_state()
	. = ..()
	if(working)
		icon_state = "brewery_l_working"
	else if(open)
		if(fuel)
			icon_state = "brewery_l_open_fueled"
		else
			icon_state = "brewery_l_open_empty"
	else
		if(fuel)
			icon_state = "brewery_l_closed_fueled"
		else
			icon_state = "brewery_l_closed_empty"


/obj/structure/brewery/l/process(delta_time)
	if(!working)
		return
	if(prob(20))
		playsound(src, 'dwarfs/sounds/effects/fire_cracking_short.ogg', 100, TRUE)
	fuel = max(fuel-1, 0)
	if(!fuel)
		working = FALSE
		update_appearance()
		return
	reagents.expose_temperature(temp)
	var/datum/reagent/young = reagents.has_reagent_subtype(/datum/reagent/consumable/ethanol/young)
	if(young)
		right.reagents.add_reagent(young.type, young.volume)
		reagents.remove_reagent(young.type, young.volume)

/obj/structure/brewery/r
	icon_state = "brewery_r_empty"
	var/obj/structure/brewery/left
	var/busy = FALSE

/obj/structure/brewery/r/Initialize()
	. = ..()
	create_reagents(300)
	START_PROCESSING(SSprocessing, src)

/obj/structure/brewery/r/Destroy()
	. = ..()
	STOP_PROCESSING(SSprocessing, src)
	if(left)
		QDEL_NULL(left)

/obj/structure/brewery/r/update_icon_state()
	. = ..()
	if(contents.len)
		icon_state = "brewery_r_container"
	else
		icon_state = initial(icon_state)

/obj/structure/brewery/r/process(delta_time)
	if(!contents.len)
		return
	var/datum/reagent/beer = reagents.has_reagent_subtype(/datum/reagent/consumable/ethanol/beer)
	if(beer)
		contents[1].reagents.add_reagent(beer.type, beer.volume)
		reagents.remove_reagent(beer.type, beer.volume)

/obj/structure/brewery/r/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/liftable))
		var/obj/item/liftable/L = I
		if(!istype(L.parent, /obj/structure/barrel))
			return
		if(contents.len)
			to_chat(user, span_warning("There is aready a barrel here."))
			return
		var/mob/living/carbon/human/H = user
		H.dropItemToGround(I)
		L.parent.forceMove(src)
		update_appearance()
	else
		return ..()

/obj/structure/brewery/r/attack_hand(mob/user)
	if(!contents.len)
		return
	if(busy)
		to_chat(user, span_warning("Somebody else is picking it up."))
		return
	var/datum/component/liftable/C = contents[1].GetComponent(/datum/component/liftable)
	C.dragged(contents[1], user, user, forced=TRUE)
	update_appearance()
