/obj/structure/sapling_pot
	name = "sapling pot"
	desc = "For some reason it only accepts tree seeds."
	icon = 'dwarfs/icons/structures/32x64.dmi'
	icon_state = "tree_pot"
	density = 1
	var/has_dirt = FALSE
	var/waterlevel = 0
	var/watermax = 100
	var/list/allowed_species
	///The currently planted plant
	var/obj/structure/plant/myplant = null
	var/target_growthstage = 3

/obj/structure/sapling_pot/Initialize()
	. = ..()
	AddComponent(/datum/component/liftable, slowdown = 5, worn_icon='dwarfs/icons/mob/inhand/righthand_32x64.dmi', inhand_icon_state=icon_state)

/obj/structure/sapling_pot/Destroy()
	if(myplant)
		QDEL_NULL(myplant)
	. = ..()

/obj/structure/sapling_pot/proc/on_damage(obj/structure/plant/source)
	SIGNAL_HANDLER
	if(!waterlevel)
		source.health -= rand(1, 3)
	if(source.age >= 2)
		source.health -= rand(1, 3)

/obj/structure/sapling_pot/proc/on_grow(obj/structure/plant/source)
	SIGNAL_HANDLER
	spawn(20) update_appearance() // update appearance after parent proc finishes processing
	if(!waterlevel)
		// Completely block growing when there's no water
		return COMPONENT_CANCEL_PLANT_GROW
	if(source.growthstage == target_growthstage)
		source.age++
		return COMPONENT_CANCEL_PLANT_GROW

/obj/structure/sapling_pot/proc/on_death(obj/structure/plant/source)
	SIGNAL_HANDLER
	visible_message(span_warning("[myplant] withers away!"))
	UnregisterSignal(myplant, list(COSMIG_PLANT_DAMAGE_TICK, COSMIG_PLANT_ON_GROW, COSMIG_PLANT_DIES))
	QDEL_NULL(myplant)
	update_appearance()

/obj/structure/sapling_pot/examine(mob/user)
	. = ..()
	.+="<hr>"
	if(myplant)
		.+="There is \a [myplant] growing here."
		.+="<br>"
		switch(myplant.health/myplant.maxhealth)
			if(1)
				.+="[myplant] looks healthy."
			if(0.6 to 0.9)
				.+="[myplant] looks ill."
			if(0.3 to 0.6)
				.+="[myplant] looks very ill."
			if(0.1 to 0.3)
				.+="[myplant] looks like it's about to die."
			else
				.+="[myplant] is dead."
	else
		.+="It's empty."
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

/obj/structure/sapling_pot/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/growable/seeds))
		if(!myplant)
			if(!istype(O, /obj/item/growable/seeds/tree))
				to_chat(user, span_warning("Cannot plant this here!"))
				return
			if(!has_dirt)
				to_chat(user, span_warning("[src] doens't have any soil inside!"))
				return
			var/obj/item/growable/seeds/S = O
			to_chat(user, span_notice("You plant [S]."))
			var/obj/structure/plant/P = new S.plant()
			qdel(S)
			myplant = P
			P.plot = src
			myplant.update_appearance()
			RegisterSignal(P, COSMIG_PLANT_DAMAGE_TICK, PROC_REF(on_damage))
			RegisterSignal(P, COSMIG_PLANT_ON_GROW, PROC_REF(on_grow))
			RegisterSignal(P, COSMIG_PLANT_DIES, PROC_REF(on_death))
			update_appearance()
			return
		else
			to_chat(user, span_warning("[capitalize(src.name)] already has seeds in it!"))
			return
	else if(O.tool_behaviour == TOOL_SHOVEL)
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
	else if(istype(O, /obj/item/stack/dirt))
		if(has_dirt)
			to_chat(user, span_warning("[src] already has dirt inside!"))
			return
		var/obj/item/stack/D = O
		if(D.use(5))
			to_chat(user, span_notice("You fill [src] with dirt."))
			has_dirt = TRUE
			update_appearance()
		else
			to_chat(user, span_notice("You need at least 5 dirt to fill [src]!"))
	else if(O.is_refillable())
		var/datum/reagent/W = O.reagents.has_reagent(/datum/reagent/water)
		if(!W)
			to_chat(user, span_warning("[O] doesn't have any water."))
			return
		if(!has_dirt)
			to_chat(user, span_warning("[src] doesn't have any dirt."))
			return
		var/needed = watermax-waterlevel
		if(needed < 10)
			to_chat(user, span_warning("[src] has enough water already."))
			return
		var/to_trans = W.volume <= needed ? W.volume : needed
		O.reagents.remove_reagent(/datum/reagent/water, to_trans)
		waterlevel += to_trans
		to_chat(user, span_notice("You water [src]."))
		user.mind.adjust_experience(/datum/skill/farming, rand(1,5))
		update_appearance()
	else
		return ..()

/obj/structure/sapling_pot/attack_hand(mob/user)
	if(myplant && myplant.growthstage == target_growthstage)
		to_chat(user, span_notice("You start removing the sapling from [src]..."))
		if(do_after(user, 10 SECONDS, src))
			var/mob/living/carbon/human/H = user
			var/obj/item/sapling/S = new()
			S.health = myplant.health
			S.maxhealth = myplant.maxhealth
			S.name = "[myplant.species] sapling"
			S.plant_type = myplant.type
			S.growthstage = myplant.growthstage
			S.icon_state = "[myplant.species]_sapling"
			START_PROCESSING(SSprocessing, S)
			UnregisterSignal(myplant, list(COSMIG_PLANT_DAMAGE_TICK, COSMIG_PLANT_ON_GROW, COSMIG_PLANT_DIES))
			QDEL_NULL(myplant)
			H.put_in_active_hand(S)
			to_chat(user, span_notice("You remove [S] from [src]."))
			user.mind.adjust_experience(/datum/skill/farming, rand(10, 25))
			update_appearance()

/obj/structure/sapling_pot/update_icon_state()
	. = ..()
	if(has_dirt)
		if(waterlevel)
			icon_state = "tree_pot_soil"
		else
			icon_state = "tree_pot_soil_dry"
	else
		icon_state = initial(icon_state)

/obj/structure/sapling_pot/update_overlays()
	. = ..()
	if(myplant)
		var/mutable_appearance/sapling = mutable_appearance('dwarfs/icons/structures/tree_pot_plants.dmi', "[myplant.species]_[myplant.growthstage]")
		. += sapling
