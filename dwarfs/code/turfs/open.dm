/turf/open/genturf
	name = "ungenerated turf"
	desc = "If you see this, and you're not a ghost, yell at coders"
	icon = 'icons/turf/debug.dmi'
	icon_state = "genturf"

/turf/open/floor/stone
	name = "stone floor"
	desc = "Classic."
	icon_state = "stone_floor"
	footstep = FOOTSTEP_SAND
	barefootstep = FOOTSTEP_SAND
	clawfootstep = FOOTSTEP_SAND
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	var/busy = FALSE

/turf/open/floor/stone/ScrapeAway(amount, flags)
	return ChangeTurf(/turf/open/floor/rock)

/turf/open/floor/stone/setup_broken_states()
	return list(icon_state)

/turf/open/floor/stone/crowbar_act(mob/living/user, obj/item/I)
	if(pry_tile(I, user))
		new /obj/item/stack/sheet/stone(get_turf(src))
		return TRUE

/turf/open/floor/rock
	name = "rock"
	desc = "Terrible."
	icon_state = "stone"
	slowdown = 0.7
	baseturfs = /turf/open/lava
	var/digged_up = FALSE

/turf/open/floor/rock/ScrapeAway(amount, flags)
	return ChangeTurf(/turf/open/lava)

/turf/open/floor/rock/crowbar_act(mob/living/user, obj/item/I)
	return FALSE

/turf/open/floor/rock/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_PICKAXE)
		if(I.use_tool(src, user, 5 SECONDS))
			if(QDELETED(src))
				return
			if(digged_up)
				try_digdown(I,user)
			else
				for(var/i in 1 to rand(2, 5))
					var/obj/item/S = new /obj/item/stack/ore/stone(src)
					S.pixel_x = rand(-8, 8)
					S.pixel_y = rand(-8, 8)
				digged_up = TRUE
				icon_state = "stone_dug"
				user.visible_message(span_notice("<b>[user]</b> digs up some stones.") , \
									span_notice("You dig up some stones."))
	if(I.tool_behaviour == TOOL_CHISEL)
		if(digged_up)
			to_chat(user, span_warning("Nice try mongoid."))
			return
		var/turf/T = src
		var/time = 5 SECONDS * user.mind.get_skill_modifier(/datum/skill/mining, SKILL_SPEED_MODIFIER)
		to_chat(user, span_notice("You start carving stone floor..."))
		if(I.use_tool(src, user, time, volume=50))
			to_chat(user, span_notice("You finish carving stone floor."))
			user.mind.adjust_experience(/datum/skill/mining, 3)
			T.ChangeTurf(/turf/open/floor/stone)
	else
		. = ..()

/turf/open/floor/sand
	name = "sand"
	desc = "Cheese?"
	icon_state = "sand"
	baseturfs = /turf/open/floor/sand
	slowdown = 0.4
	var/digged_up = FALSE

/turf/open/floor/sand/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_SHOVEL || I.tool_behaviour == TOOL_PICKAXE)
		to_chat(user, span_notice("You start digging [src]..."))
		var/dig_time = I.tool_behaviour == TOOL_SHOVEL ? 5 SECONDS : 10 SECONDS
		if(I.use_tool(src, user, dig_time))
			if(QDELETED(src))
				return
			if(digged_up)
				try_digdown(I,user)
			else
				new/obj/item/stack/ore/smeltable/sand(src, rand(3,6))
				digged_up = TRUE
				icon_state = "sand_dug"
				user.visible_message(span_notice("<b>[user]</b> digs up some stones.") , \
					span_notice("You dig up some stones."))
	else
		. = ..()

/turf/open/floor/dirt
	name = "dirt"
	desc = "Found near bodies of water. Can be farmed on."
	icon_state = "soil"
	slowdown = 1
	var/digged_up = FALSE

/turf/open/floor/dirt/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_HOE)
		if(digged_up)
			to_chat(user, span_warning("There is no more dirt to be tilled!"))
			return
		to_chat(user, span_notice("You start tilling [src]..."))
		var/channel = playsound(src, 'dwarfs/sounds/tools/hoe/hoe_dig_long.ogg', 50, TRUE)
		if(I.use_tool(src, user, 10 SECONDS))
			stop_sound_channel_nearby(src, channel)
			var/turf/open/floor/tilled/T = ChangeTurf(/turf/open/floor/tilled)
			if(((locate(/turf/open/water) in range(3, T))) || ((locate(/obj/structure/well) in range(3, T))))
				T.waterlevel = T.watermax
				T.update_appearance()
			user.mind.adjust_experience(/datum/skill/farming, 7)
		else
			stop_sound_channel_nearby(src, channel)
	else if(I.tool_behaviour == TOOL_SHOVEL || I.tool_behaviour == TOOL_PICKAXE)
		to_chat(user, span_notice("You start digging [src]..."))
		var/dig_time = I.tool_behaviour == TOOL_SHOVEL ? 5 SECONDS : 10 SECONDS
		if(I.use_tool(src, user, dig_time))
			if(digged_up)
				try_digdown(I,user)
			else
				new/obj/item/stack/dirt(src, rand(2,5))
				user.visible_message(span_notice("<b>[user]</b> digs up some dirt.") , \
					span_notice("You dig up some dirt."))
				digged_up = TRUE
				icon_state = "soil_dug"
	else
	 . = ..()

/turf/open/floor/tilled
	name = "tilled dirt"
	desc = "Ready for plants."
	icon_state = "soil_tilled"
	slowdown = 1
	var/waterlevel = 0
	var/watermax = 100
	var/waterrate = 1
	var/fertlevel = 0
	var/fertmax = 100
	var/fertrate = 1
	var/list/allowed_species
	///The currently planted plant
	var/obj/structure/plant/myplant = null


/turf/open/floor/tilled/examine(mob/user)
	. = ..()
	.+="<hr>"
	if(myplant)
		.+="There is \a [myplant] growing here."
	else
		.+="It's empty."
	var/fert_text = "<br>"
	switch(fertlevel)
		if(60 to 100)
			fert_text+="There is plenty of fertilizer in it."
		if(30 to 59)
			fert_text+="There is some fertilizer in it."
		if(1 to 29)
			fert_text+="There is almost no fertilizer in it."
		else
			fert_text+="There is no fertilizer in it."
	.+=fert_text
	var/water_text = "<br>"
	switch(waterlevel)
		if(60 to 100)
			water_text+="Looks very moist."
		if(30 to 59)
			water_text+="Looks normal."
		if(1 to 29)
			water_text+="Looks a bit dry."
		else
			water_text+="Looks extremely dry."
	.+=water_text

/turf/open/floor/tilled/Destroy()
	if(myplant)
		QDEL_NULL(myplant)
	return ..()

/turf/open/floor/tilled/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/growable/seeds))
		if(!myplant)
			if(istype(O, /obj/item/growable/seeds/tree))
				to_chat(user, span_warning("Cannot plant this here!"))
				return
			var/obj/item/growable/seeds/S = O
			to_chat(user, span_notice("You plant [S]."))
			var/obj/structure/plant/P = new S.plant(src)
			qdel(S)
			myplant = P
			P.plot = src
			myplant.update_appearance()
			RegisterSignal(P, COSMIG_PLANT_DAMAGE_TICK, .proc/on_damage)
			RegisterSignal(P, COSMIG_PLANT_EAT_TICK, .proc/on_eat)
			return
		else
			to_chat(user, span_warning("[capitalize(src.name)] already has seeds in it!"))
			return

	else if(istype(O, /obj/item/shovel))
		user.visible_message(span_notice("[user] starts digging out [src]'s plants...") ,
			span_notice("You start digging out [src]'s plants..."))
		if(O.use_tool(src, user, 50, volume=50) || !myplant)
			user.visible_message(span_notice("[user] digs out the plants in [src]!") , span_notice("You dig out all of [src]'s plants!"))
			if(myplant) //Could be that they're just using it as a de-weeder
				QDEL_NULL(myplant)
				name = initial(name)
				desc = initial(desc)
			update_appearance()
			return
	else if(istype(O, /obj/item/fertilizer))
		user.visible_message(span_notice("[user] adds [O] to \the [src]."), span_notice("You add [O] to \the [src]."))
		var/obj/item/fertilizer/F = O
		fertlevel = clamp(fertlevel+F.fertilizer, 0, fertmax)
		qdel(F)
	else if(O.is_refillable())
		var/datum/reagent/W = O.reagents.has_reagent(/datum/reagent/water)
		if(!W)
			to_chat(user, span_warning("[O] doesn't have water!"))
			return
		var/needed = watermax-waterlevel
		if(needed < 10)
			to_chat(user, span_warning("[src] has enough water already."))
			return
		var/to_remove = W.volume <= needed ? W.volume : needed
		O.reagents.remove_reagent(/datum/reagent/water, to_remove)
		to_chat(user, span_notice("You water [src]."))
		waterlevel = clamp(waterlevel+to_remove, 0, watermax)
		user.mind.adjust_experience(/datum/skill/farming, rand(1,5))
		update_appearance()
	else
		return ..()

/turf/open/floor/tilled/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	if(myplant)
		if(myplant.dead)
			to_chat(user, span_notice("You remove the dead plant from [src]."))
			QDEL_NULL(myplant)
			update_appearance()
	else
		if(user)
			user.examinate(src)

/turf/open/floor/tilled/proc/on_damage(obj/structure/plant/source)
	SIGNAL_HANDLER
	if(!waterlevel)
		source.health -= rand(1,3)
	if(allowed_species && !(source.species in allowed_species))
		source.health -= rand(1,3)

/turf/open/floor/tilled/proc/on_eat(obj/structure/plant/source)
	SIGNAL_HANDLER
    if(((locate(/turf/open/water) in range(3, src))) || ((locate(/obj/structure/well) in range(3, src))))
		waterlevel = watermax
	waterlevel = clamp(waterlevel-waterrate, 0, watermax)
	update_appearance()
	fertlevel = clamp(fertlevel-fertrate, 0, fertmax)
	source.growth_modifiers["fertilizer"] = fertlevel ? 0.8 : 1

/turf/open/floor/tilled/update_icon_state()
	. = ..()
	if((waterlevel/watermax) < 0.3)
		icon_state = "soil_tilled"
	else
		icon_state = "soil_tilled_wet"

/turf/open/water
	name = "water"
	desc = "Stay hydrated."
	icon = 'dwarfs/icons/turf/water.dmi'
	icon_state = "water-255"
	base_icon_state = "water"
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_TURF_OPEN, SMOOTH_GROUP_FLOOR_WATER)
	canSmoothWith = list(SMOOTH_GROUP_FLOOR_WATER)
	slowdown = 2

/turf/open/water/Initialize(mapload)
	. = ..()
	create_reagents(100, DRAINABLE)
	reagents.add_reagent(/datum/reagent/water, 100)

/turf/open/water/attackby(obj/item/C, mob/user, params)
	if(C.is_refillable())
		var/obj/item/reagent_containers/CC = C
		if(CC.reagents.total_volume == CC.volume)
			to_chat(user, span_warning("[CC] is full!"))
			return
		to_chat(user, span_notice("You fill [CC] with water."))
		CC.reagents.add_reagent(/datum/reagent/water, CC.volume - CC.reagents.total_volume)
	else
		reagents.expose(C)
		for(var/atom/A in C)
			reagents.expose(A)

/turf/open/water/attack_hand(mob/user)
	if(ishuman(user))
		to_chat(user, span_notice("You start drinking from [src]..."))
		if(do_after(user, 5 SECONDS, src))
			playsound(user,'sound/items/drink.ogg', rand(10,50), TRUE)
			user.hydration = clamp(user.hydration+rand(50,90), 0, HYDRATION_LEVEL_MAX)
			to_chat(user, span_notice("You drink from [src]."))

/turf/open/water/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	if(reagents)
		reagents.expose(arrived)
		for(var/atom/A in arrived)
			reagents.expose(A)
