// TODO: add particle effects when working; add sounds; add light changes when lighting up

/obj/structure/stove
	name = "stove"
	desc = "Slowfire stove. Great for cooking and boiling stuff."
	icon = 'dwarfs/icons/structures/workshops.dmi'
	icon_state = "stove_closed_empty"
	density = 1
	anchored = 1
	var/open = FALSE
	var/fuel = 0
	var/fuel_consumption = 0.5
	var/working = FALSE
	var/heat = 500
	var/list/timers = list(null, null)
	var/cook_time = 10 SECONDS
	/// To remember which is placed where
	var/obj/item/reagent_containers/glass/left_item
	var/obj/item/reagent_containers/glass/right_item

/obj/structure/stove/Initialize()
	. = ..()
	START_PROCESSING(SSprocessing, src)

/obj/structure/stove/Destroy()
	. = ..()
	STOP_PROCESSING(SSprocessing, src)

/obj/structure/stove/update_icon_state()
	. = ..()
	if(working)
		icon_state = "stove_working"
	else if(open)
		if(fuel)
			icon_state = "stove_open_fueled"
		else
			icon_state = "stove_open_empty"
	else
		if(fuel)
			icon_state = "stove_closed_fueled"
		else
			icon_state = "stove_closed_empty"

/obj/structure/stove/update_overlays()
	. = ..()
	if(!contents.len)
		return
	if(left_item)
		var/mutable_appearance/M
		if(istype(left_item, /obj/item/reagent_containers/glass/cooking_pot))
			var/obj/item/reagent_containers/glass/cooking_pot/P = left_item
			M = mutable_appearance('dwarfs/icons/items/kitchen.dmi', "[P.open ? "cooking_pot_world_open" : "cooking_pot_world_closed"]")
			if(P.reagents.total_volume && P.open)
				var/mutable_appearance/O = mutable_appearance('dwarfs/icons/items/kitchen.dmi', "cooking_pot_world_overlay")
				O.color = mix_color_from_reagents(P.reagents.reagent_list)
				M.overlays+=O
		else
			M = mutable_appearance(left_item.icon, "skillet_world")
		M.pixel_x = clamp(10 - 16, -(world.icon_size/2), world.icon_size/2)
		.+=M
	if(right_item)
		var/mutable_appearance/M
		if(istype(right_item, /obj/item/reagent_containers/glass/cooking_pot))
			var/obj/item/reagent_containers/glass/cooking_pot/P = right_item
			M = mutable_appearance('dwarfs/icons/items/kitchen.dmi', "[P.open ? "cooking_pot_world_open" : "cooking_pot_world_closed"]")
			if(P.reagents.total_volume && P.open)
				var/mutable_appearance/O = mutable_appearance('dwarfs/icons/items/kitchen.dmi', "cooking_pot_world_overlay")
				O.color = mix_color_from_reagents(P.reagents.reagent_list)
				M.overlays+=O
		else
			M = mutable_appearance(right_item.icon, "skillet_world")
		M.pixel_x = clamp(24 - 16, -(world.icon_size/2), world.icon_size/2)
		.+=M

/obj/structure/stove/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/reagent_containers/glass/cooking_pot) || istype(I, /obj/item/reagent_containers/glass/pan))
		if(left_item)
			to_chat(user, span_warning("This place is already occupied by [left_item]."))
			return TRUE
		I.forceMove(src)
		left_item = I
		update_appearance()
		if(working)
			start_cooking(I, 1, user)
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
		start_cooking(user=user)
	else if(I.get_fuel())
		if(!open)
			to_chat(user, span_warning("[src] has to be opened first."))
			return
		fuel += I.get_fuel()
		user.visible_message(span_notice("[user] throws [I] into [src]."), span_notice("You throw [I] into [src]."))
		qdel(I)
		update_appearance()
	else
		. = ..()

/obj/structure/stove/attackby_secondary(obj/item/I, mob/user, params)
	. = SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(istype(I, /obj/item/reagent_containers/glass/cooking_pot) || istype(I, /obj/item/reagent_containers/glass/pan))
		if(right_item)
			to_chat(user, span_warning("This place is already occupied by [right_item]."))
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		I.forceMove(src)
		right_item = I
		update_appearance()
		if(working)
			start_cooking(I, 2, user)
	else
		. = ..()

/obj/structure/stove/attack_hand(mob/user)
	if(!left_item)
		return
	if(!user.put_in_active_hand(left_item, FALSE, FALSE))
		user.dropItemToGround(left_item)
		return
	left_item = null
	update_appearance()
	remove_timer(1)

/obj/structure/stove/attack_hand_secondary(mob/user, list/modifiers)
	. = SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(!right_item)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(!user.put_in_active_hand(right_item, FALSE, FALSE))
		user.dropItemToGround(right_item)
		return
	right_item = null
	update_appearance()
	remove_timer(2)

/obj/structure/stove/AltClick(mob/user)
	if(in_range(user, src))
		if(working)
			to_chat(user, span_warning("Cannot open while [src] is working."))
			return
		open = !open
		update_appearance()
		to_chat(user, span_notice("You [open?"open":"close"] [src]."))
		playsound(src, 'dwarfs/sounds/structures/toggle_open.ogg', 50, TRUE)

/obj/structure/stove/process(delta_time)
	if(!working)
		return
	if(prob(20))
		playsound(src, 'dwarfs/sounds/effects/fire_cracking_short.ogg', 100, TRUE)
	if(!fuel)
		working = FALSE
		visible_message(span_notice("[src]'s flames die out."))
		update_appearance()
		return
	fuel = max(fuel-fuel_consumption, 0)

/obj/structure/stove/proc/remove_timer(item_slot)
	if(active_timers)
		switch(item_slot)
			if(1,2)
				if(timers[item_slot])
					deltimer(timers[item_slot])
					timers[item_slot] = null
			if(3)
				for(var/i=1;i<=2;i++)
					if(timers[i])
						deltimer(timers[item_slot])
						timers[i] = null
	else
		timers = list(null, null)


/obj/structure/stove/proc/start_cooking(obj/item/I=null, item_slot=null, mob/user)
	if(item_slot && I)
		timers[item_slot] = addtimer(CALLBACK(src, .proc/try_cook, I, user), cook_time, TIMER_STOPPABLE)
	else
		if(left_item)
			timers[1] = addtimer(CALLBACK(src, .proc/try_cook, left_item, user), cook_time, TIMER_STOPPABLE)
		if(right_item)
			timers[2] = addtimer(CALLBACK(src, .proc/try_cook, right_item, user), cook_time, TIMER_STOPPABLE)

/obj/structure/stove/proc/try_cook(obj/item/I, mob/user)
	var/list/possible_recipes = list()
	if(istype(I, /obj/item/reagent_containers/glass/cooking_pot))
		possible_recipes = subtypesof(/datum/cooking_recipe/pot)
	else if(istype(I, /obj/item/reagent_containers/glass/pan))
		possible_recipes = subtypesof(/datum/cooking_recipe/pan)
	var/datum/cooking_recipe/R = find_recipe(possible_recipes, I.contents, I.reagents.reagent_list)
	if(!R)
		LAZYCLEARLIST(I.contents)
		I.reagents.clear_reagents()
		user.mind.adjust_experience(/datum/skill/cooking, 2)
		new /obj/item/food/badrecipe(get_turf(src))
		return
	if(left_item == I)
		left_item = null
	else if(right_item == I)
		right_item = null
	update_appearance()
	var/obj/item/food/F = initial(R.result)
	user.mind.adjust_experience(/datum/skill/cooking, rand(10, 30))
	new F(get_turf(src))
	qdel(I)
	update_appearance()
