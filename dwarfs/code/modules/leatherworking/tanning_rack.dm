/obj/structure/tanning_rack
	name = "tanning rack"
	desc = "Used for drying wet hide."
	icon = 'dwarfs/icons/structures/workshops.dmi'
	icon_state = "tanning_rack"
	anchored = TRUE
	density = TRUE
	var/tanning_time = 1 MINUTES
	var/timerid

/obj/structure/tanning_rack/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/wethide))
		if(contents.len)
			to_chat(user, span_warning("There is already something on [src]."))
			return
		I.forceMove(src)
		to_chat(user, span_notice("You attach [I] to [src]."))
		update_appearance()
		timerid = addtimer(CALLBACK(src, PROC_REF(dry)), tanning_time, TIMER_STOPPABLE)
	else
		. = ..()

/obj/structure/tanning_rack/attack_hand(mob/user)
	if(contents.len)
		to_chat(user, span_notice("You remove [contents[1]] from [src]."))
		var/mob/living/carbon/human/H = user
		H.put_in_active_hand(contents[1])
		if(active_timers)
			deltimer(timerid)
		update_appearance()

/obj/structure/tanning_rack/proc/dry()
	var/obj/item/stack/sheet/wethide/W = contents[1]
	var/obj/item/stack/sheet/dryhide/D = new(src)
	D.leather_amount = W.leather_amount
	qdel(W)
	update_appearance()

/obj/structure/tanning_rack/update_icon_state()
	. = ..()
	if(!contents.len)
		icon_state = "tanning_rack"
	else
		if(istype(contents[1], /obj/item/stack/sheet/wethide))
			icon_state = "tanning_rack_wet_hide"
		else if(istype(contents[1], /obj/item/stack/sheet/dryhide))
			icon_state = "tanning_rack_dry_hide"
