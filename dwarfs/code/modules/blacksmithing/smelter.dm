/obj/structure/smelter
	name = "smelter"
	desc = "Smelts that precious mineral you mined into useful ingot."
	icon = 'dwarfs/icons/structures/workshops.dmi'
	icon_state = "smelter"
	density = TRUE
	anchored = TRUE
	light_range = 0
	light_color = "#BB661E"
	var/working = FALSE
	var/fuel = 0
	var/fuel_consumption = 0.5
	var/smelting_time = 30 SECONDS
	var/max_items = 5
	var/timerid

/obj/structure/smelter/Initialize()
	. = ..()
	START_PROCESSING(SSprocessing, src)

/obj/structure/smelter/Destroy()
	. = ..()
	STOP_PROCESSING(SSprocessing, src)

/obj/structure/smelter/examine(mob/user)
	. = ..()
	if(contents.len)
		. += "<br> \The [src] is smelting \a [contents[1]]."
	else
		. += "<br> \The [src] is empty!"

/obj/structure/smelter/update_icon_state()
	. = ..()
	if(working)
		icon_state = "smelter_working"
	else if(fuel)
		icon_state = "smelter_fueled"
	else
		icon_state = "smelter"

/obj/structure/smelter/proc/_update_light()
	if(working)
		light_range = 3
	else
		light_range = 0

/obj/structure/smelter/update_appearance(updates)
	. = ..()
	_update_light()

/obj/structure/smelter/proc/smelted_thing()
	var/obj/item/I = contents[1]
	I.forceMove(get_turf(src))
	if(contents.len)
		start_smelting()

/obj/structure/smelter/proc/start_smelting()
	timerid = addtimer(CALLBACK(src, PROC_REF(smelted_thing)), smelting_time, TIMER_STOPPABLE)

/obj/structure/smelter/proc/remove_timer()
	if(active_timers)
		deltimer(timerid)

/obj/structure/smelter/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/stack/ore/smeltable))
		var/obj/item/stack/ore/smeltable/S = I
		if(contents.len == max_items)
			to_chat(user, span_warning("[src] is full!"))
			return
		if(!S.use(5))
			to_chat(user, span_warning("You need at leat 5 pieces."))
			return
		to_chat(user, span_notice("[src] you place [S] into [src]."))
		if(working && !contents.len)
			start_smelting()
		new S.refined_type(src)
	else if(I.get_temperature())
		if(!fuel)
			to_chat(user, span_warning("[src] has no fuel."))
			return
		if(working)
			to_chat(user, span_warning("[src] is already lit."))
			return
		to_chat(user, span_notice("You light up [src]."))
		playsound(src, 'dwarfs/sounds/effects/ignite.ogg', 50, TRUE)
		working = TRUE
		if(contents.len)
			start_smelting()
		update_appearance()
	else if(I.get_fuel())
		fuel += I.get_fuel()
		qdel(I)
		user.visible_message(span_notice("[user] throws [I] into [src]."), span_notice("You throw [I] into [src]."))
		update_appearance()
	else
		. = ..()

/obj/structure/smelter/process(delta_time)
	if(!working)
		return
	if(prob(20))
		playsound(src, 'dwarfs/sounds/effects/fire_cracking_short.ogg', 100, TRUE)
	if(!fuel)
		working = FALSE
		update_appearance()
		remove_timer()
		return
	fuel = max(fuel-fuel_consumption, 0)
