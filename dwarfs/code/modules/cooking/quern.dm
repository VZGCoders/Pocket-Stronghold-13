/obj/structure/quern
	name = "quern"
	desc = "Manual whole grain mill. At least you eat healthy."
	icon = 'dwarfs/icons/structures/workshops.dmi'
	icon_state = "millstone"
	density = TRUE
	anchored = TRUE
	var/max_volume = 150
	var/work_time = 3 SECONDS
	var/open = FALSE
	var/busy_operating = FALSE

/obj/structure/quern/Initialize()
	. = ..()
	create_reagents(max_volume)

/obj/structure/quern/examine(mob/user)
	. = ..()
	if(length(contents))
		.+="<br>It has "
		for(var/obj/O in uniquePathList(contents))
			var/amt = count_by_type(contents, O.type)
			.+="[amt] [O.name][amt > 1 ? "s" : ""]"
		.+=" in it."
	if(reagents.total_volume)
		.+="<br>It has [reagents.get_reagent_names()] in it."
	if(!length(contents) && !reagents.total_volume)
		.+="<br>It's empty."

/obj/structure/quern/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/growable))
		var/obj/item/growable/G = I
		if(!G.GetComponent(/datum/component/grindable))
			return TRUE
		if(!open)
			to_chat(user, span_warning("[src] has to be opened first."))
			return TRUE
		if(contents.len > 3)
			to_chat(user, span_warning("[src] is already full."))
			return TRUE
		G.forceMove(src)
	else if(istype(I, /obj/item/reagent_containers/glass/sack))
		if(!reagents.total_volume)
			to_chat(user, span_warning("[src] is empty."))
			return TRUE
		if(!open)
			to_chat(user, span_warning("[src] has to be opened first."))
			return TRUE
		var/obj/item/reagent_containers/glass/sack/S = I
		var/vol = reagents.trans_to(S, S.amount_per_transfer_from_this, transfered_by=user)
		if(vol)
			to_chat(user, span_notice("You scoop [vol]u from [src]"))
		S.update_appearance()
	update_appearance()

/obj/structure/quern/attackby_secondary(obj/item/I, mob/user, params)
	. = SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(istype(I, /obj/item/reagent_containers/glass/sack))
		var/obj/item/reagent_containers/glass/sack/S = I
		if(!S.reagents.total_volume)
			to_chat(user, span_warning("[S] is empty."))
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		if(!open)
			to_chat(user, span_warning("[src] has to be opened first."))
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		var/vol = S.reagents.trans_to(src, S.amount_per_transfer_from_this, transfered_by=user)
		if(vol)
			to_chat(user, span_notice("You transfer [vol]u to [src]"))
		S.update_appearance()
		update_appearance()

/obj/structure/quern/attack_hand(mob/user)
	if(open)
		to_chat(user, span_warning("[src] has to be closed first."))
		return
	if(!contents.len && !reagents.has_reagent_subtype(/datum/reagent/grain))
		to_chat(user, span_warning("[src] has nothing to grind."))
		return
	if(busy_operating)
		to_chat(user, span_warning("Somebody is already working on [src]."))
		return
	busy_operating = TRUE
	update_appearance()
	to_chat(user, span_notice("You start working at [src]."))
	var/channel = playsound(src, 'dwarfs/sounds/tools/quern/quern_mill_long.ogg', 70, TRUE)
	if(do_after(user, work_time, src))
		if(contents.len)
			var/obj/item/growable/G = contents[1]
			SEND_SIGNAL(G, COSMIG_ITEM_GRINDED, src)
		else // has grain reagents
			var/datum/reagent/grain/G =  reagents.has_reagent_subtype(/datum/reagent/grain)
			SEND_SIGNAL(G, COSMIG_REAGENT_GRINDED, src)
	else
		stop_sound_channel_nearby(src, channel)
	busy_operating = FALSE
	update_appearance()
	to_chat(user, span_notice("You finish working at [src]."))

/obj/structure/quern/AltClick(mob/user)
	if(busy_operating)
		to_chat(user, span_warning("Cannot open [src] while it's rotating."))
		return
	open = !open
	to_chat(user, span_notice("You [open?"open":"close"] [src]."))
	update_appearance()

/obj/structure/quern/CtrlClick(mob/user)
	. = ..()
	if(!contents.len)
		to_chat(user, span_warning("[src] is empty."))
		return
	to_chat(user, span_notice("You empty [src]."))
	for(var/obj/item/I in contents)
		I.forceMove(get_turf(src))
	update_appearance()

/obj/structure/quern/update_icon_state()
	. = ..()
	if(busy_operating)
		icon_state = "millstone_working"
	else if(open)
		if(contents.len || reagents.has_reagent_subtype(/datum/reagent/grain))
			icon_state = "millstone_open_grain"
		else if(reagents.has_reagent_subtype(/datum/reagent/flour))
			icon_state = "millstone_open_flour"
		else
			icon_state = "millstone_open"
	else
		icon_state = "millstone"
