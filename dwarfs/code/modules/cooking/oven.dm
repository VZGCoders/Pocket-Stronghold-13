/obj/structure/oven
	name = "oven"
	desc = "One of essentials for delicious cuisine. Warm meal is what you need."
	icon = 'dwarfs/icons/structures/32x64.dmi'
	icon_state = "oven_empty"
	anchored = TRUE
	density = TRUE
	layer = BELOW_OBJ_LAYER
	var/fuel = 0
	var/fuel_consumption = 0.5
	var/working = FALSE
	var/cooking_time = 10 SECONDS
	var/timerid

/obj/structure/oven/Initialize()
	. = ..()
	START_PROCESSING(SSprocessing, src)
	update_appearance()

/obj/structure/oven/Destroy()
	. = ..()
	STOP_PROCESSING(SSprocessing, src)

/obj/structure/oven/update_icon_state()
	. = ..()
	if(working)
		icon_state = "oven_on_lower"
	else if(fuel)
		icon_state = "oven_fueled_lower"
	else
		icon_state = "oven_empty_lower"

/obj/structure/oven/update_overlays()
	. = ..()
	var/mutable_appearance/M = mutable_appearance(initial(icon), layer=ABOVE_MOB_LAYER)
	if(working)
		M.icon_state = "oven_on_upper"
	else if(fuel)
		M.icon_state = "oven_fueled_upper"
	else
		M.icon_state = "oven_empty_upper"
	. += M

/obj/structure/oven/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/reagent_containers/glass/plate))
		if(contents.len)
			to_chat(user, span_warning("There is already something cooking inside."))
			return
		I.forceMove(src)
		to_chat(user, span_notice("You place \the [I] inside [src]."))
		if(working)
			timerid = addtimer(CALLBACK(src, PROC_REF(try_cook), I, user), cooking_time, TIMER_STOPPABLE)
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
			timerid = addtimer(CALLBACK(src, PROC_REF(try_cook), contents[1], user), cooking_time, TIMER_STOPPABLE)
		update_appearance()
	else if(I.get_fuel())
		fuel += I.get_fuel()
		qdel(I)
		user.visible_message(span_notice("[user] throws [I] into [src]."), span_notice("You throw [I] into [src]."))
		update_appearance()

/obj/structure/oven/proc/try_cook(obj/item/I, mob/user)
	var/list/possible_recipes = list()
	if(istype(I, /obj/item/reagent_containers/glass/plate/regular))
		possible_recipes = subtypesof(/datum/cooking_recipe/oven/plate)
	else if(istype(I, /obj/item/reagent_containers/glass/plate/flat))
		possible_recipes = subtypesof(/datum/cooking_recipe/oven/flat_plate)
	else if(istype(I, /obj/item/reagent_containers/glass/plate/bowl))
		possible_recipes = subtypesof(/datum/cooking_recipe/oven/bowl)
	var/datum/cooking_recipe/R = find_recipe(possible_recipes, I.contents, I.reagents.reagent_list)
	if(!R)
		qdel(I)
		new /obj/item/food/badrecipe(get_turf(src))
		user.mind.adjust_experience(/datum/skill/cooking, 2)
		return
	user.mind.adjust_experience(/datum/skill/cooking, rand(10, 30))
	new R.result(get_turf(src))
	qdel(I)

/obj/structure/oven/process(delta_time)
	if(!working)
		return
	if(prob(20))
		playsound(src, 'dwarfs/sounds/effects/fire_cracking_short.ogg', 100, TRUE)
	if(fuel<1)
		working = FALSE
		update_appearance()
	fuel = max(fuel-fuel_consumption, 0)
