/obj/item/reagent_containers/glass/sack
	name = "sack"
	desc = "Storage sack, for seeds or something."
	icon = 'dwarfs/icons/items/kitchen.dmi'
	icon_state = "bag"
	volume = 80
	allowed_reagents = list(/datum/reagent/grain, /datum/reagent/flour)
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list()

/obj/item/reagent_containers/glass/sack/examine(mob/user)
	. = ..()
	if(!reagents.total_volume)
		.+="<br>It's empty."
	else
		.+="<br>It has [reagents.get_reagent_names()] in it."

/obj/item/reagent_containers/glass/sack/update_icon(updates)
	. = ..()
	if(reagents.has_reagent_subtype(/datum/reagent/grain))
		icon_state = "bag_grain"
	else if(reagents.has_reagent_subtype(/datum/reagent/flour))
		icon_state = "bag_flour"
	else
		icon_state = "bag"

/obj/item/reagent_containers/glass/cooking_pot
	name = "cooking pot"
	desc = "A Midsummer Night's Dream of Chilli Pot"
	icon = 'dwarfs/icons/items/kitchen.dmi'
	lefthand_file = 'dwarfs/icons/mob/inhand/lefthand.dmi'
	righthand_file = 'dwarfs/icons/mob/inhand/righthand.dmi'
	inhand_icon_state = "cooking_pot"
	icon_state = "cooking_pot_open"
	amount_per_transfer_from_this = 10
	volume = 100
	var/open = TRUE

/obj/item/reagent_containers/glass/cooking_pot/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/storage/concrete/cooking/pot)

/obj/item/reagent_containers/glass/cooking_pot/update_overlays()
	. = ..()
	if(open && reagents.total_volume)
		var/mutable_appearance/M = mutable_appearance("dwarfs/icons/items/kitchen.dmi", "cooking_pot_overlay")
		M.color = mix_color_from_reagents(reagents.reagent_list)
		. += M

/obj/item/reagent_containers/glass/cooking_pot/update_icon_state()
	. = ..()
	if(open)
		icon_state = "cooking_pot_open"
	else
		icon_state = "cooking_pot_closed"

/obj/item/reagent_containers/glass/cooking_pot/attack_self_secondary(mob/user, modifiers)
	open = !open
	update_appearance()
	to_chat(user, span_notice("You [open?"open":"close"] [src]."))
	amount_per_transfer_from_this = open ? initial(amount_per_transfer_from_this) : 0 // cannot transfer reagents when closed

/obj/item/reagent_containers/glass/plate
	icon = 'dwarfs/icons/items/kitchen.dmi'
	volume = 20

/obj/item/reagent_containers/glass/plate/Initialize(mapload, vol)
	. = ..()
	AddComponent(/datum/component/storage/concrete/cooking/plate)

/obj/item/reagent_containers/glass/plate/regular
	name = "plate"
	desc = "Good for holding some food inside it."
	icon_state = "wooden_plate"
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list()

/obj/item/reagent_containers/glass/plate/regular/update_overlays()
	. = ..()
	for(var/i=1;i<=min(contents.len,4);i++)
		var/obj/item/I = contents[i]
		var/mutable_appearance/M = mutable_appearance(I.icon, I.icon_state)
		M.pixel_x = -10
		M.pixel_y = -10
		switch(i)
			if(3)
				M.pixel_x += 8
				M.pixel_y += 11
				M.layer = FLOAT_LAYER-1
			if(4)
				M.pixel_x += 13
				M.pixel_y += 11
				M.layer = FLOAT_LAYER-1
			if(1)
				M.pixel_x += 8
				M.pixel_y += 8
			if(2)
				M.pixel_x += 13
				M.pixel_y += 8
		M.transform *= 0.6
		. += M

/obj/item/reagent_containers/glass/plate/flat
	name = "flat plate"
	desc = "Holds food a bit worse than a ragular plate."
	icon_state = "fancy_plate"

/obj/item/reagent_containers/glass/plate/flat/update_overlays()
	. = ..()
	for(var/i=1;i<=min(contents.len,4);i++)
		var/obj/item/I = contents[i]
		var/mutable_appearance/M = mutable_appearance(I.icon, I.icon_state)
		M.pixel_x = -10
		M.pixel_y = -11
		switch(i)
			if(1)
				M.pixel_x += 8
				M.pixel_y += 11
			if(2)
				M.pixel_x += 13
				M.pixel_y += 11
			if(3)
				M.pixel_x += 8
				M.pixel_y += 8
			if(4)
				M.pixel_x += 13
				M.pixel_y += 8
		M.transform *= 0.6
		. += M

/obj/item/reagent_containers/glass/plate/bowl
	name = "bowl"
	desc = "Deep plate."
	icon_state = "wooden_bowl"

/obj/item/reagent_containers/glass/plate/bowl/update_overlays()
	. = ..()
	for(var/i=1;i<=min(contents.len,4);i++)
		var/obj/item/I = contents[i]
		var/mutable_appearance/M = mutable_appearance(I.icon, I.icon_state)
		M.pixel_x = -10
		M.pixel_y = -10
		switch(i)
			if(3)
				M.pixel_x += 8
				M.pixel_y += 11
				M.layer = FLOAT_LAYER-1
			if(4)
				M.pixel_x += 13
				M.pixel_y += 11
				M.layer = FLOAT_LAYER-1
			if(1)
				M.pixel_x += 8
				M.pixel_y += 8
			if(2)
				M.pixel_x += 13
				M.pixel_y += 8
		M.transform *= 0.6
		. += M
	. += mutable_appearance(icon, "wooden_bowl_overlay")

/obj/item/reagent_containers/glass/plate/bowl/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/kitchen/knife))
		var/datum/cooking_recipe/R = find_recipe(subtypesof(/datum/cooking_recipe/plate), contents)
		var/mob/living/carbon/human/H = user
		if(!R)
			var/held_index = H.is_holding(src)
			if(held_index)
				qdel(src)
				var/obj/item/food/badrecipe/S = new
				H.put_in_hand(S, held_index)
			else
				new /obj/item/food/badrecipe(loc)
				qdel(src)
			user.mind.adjust_experience(/datum/skill/cooking, 2)

		var/obj/item/food/F = new R.result
		user.mind.adjust_experience(/datum/skill/cooking, rand(10, 30))
		var/held_index = H.is_holding(src)
		if(held_index)
			qdel(src)
			H.put_in_hand(F, held_index)
		else
			F.forceMove(loc)
			qdel(src)
	else
		. = ..()

/obj/item/reagent_containers/glass/pan
	name = "frying pan"
	desc = "Used to fry stuff."
	icon = 'dwarfs/icons/items/kitchen.dmi'
	lefthand_file = 'dwarfs/icons/mob/inhand/lefthand.dmi'
	righthand_file = 'dwarfs/icons/mob/inhand/righthand.dmi'
	icon_state = "skillet"
	volume = 30

/obj/item/reagent_containers/glass/pan/update_overlays()
	. = ..()
	for(var/i=1;i<=min(contents.len,4);i++)
		var/obj/item/I = contents[i]
		var/mutable_appearance/M = mutable_appearance(I.icon, I.icon_state)
		M.pixel_x = -14
		M.pixel_y = -14
		switch(i)
			if(1)
				M.pixel_x += 8
				M.pixel_y += 11
			if(2)
				M.pixel_x += 13
				M.pixel_y += 11
			if(3)
				M.pixel_x += 8
				M.pixel_y += 8
			if(4)
				M.pixel_x += 13
				M.pixel_y += 8
		M.transform *= 0.6
		. += M

/obj/item/reagent_containers/glass/pan/Initialize(mapload, vol)
	. = ..()
	AddComponent(/datum/component/storage/concrete/cooking/pan)

/obj/item/reagent_containers/glass/cup
	name = "wooden cup"
	icon = 'dwarfs/icons/items/containers.dmi'
	icon_state = "wooden_cup"

/obj/item/reagent_containers/glass/cup/update_overlays()
	. = ..()
	if(reagents.total_volume)
		var/mutable_appearance/M = mutable_appearance(icon, "cup_overlay")
		M.color = mix_color_from_reagents(reagents.reagent_list)
		. += M

/obj/item/reagent_containers/glass/cup/iron
	name = "iron cup"
	icon_state = "iron_cup"

/// Flagon is pretty WIP///

/obj/item/reagent_containers/glass/flagon
	name = "flagon"
	icon = 'dwarfs/icons/items/containers.dmi'
	icon_state = "flagon"

/obj/item/reagent_containers/glass/flagon/update_overlays()
	. = ..()
	if(reagents.total_volume)
		var/mutable_appearance/M = mutable_appearance(icon, "flagon_overlay")
		M.color = mix_color_from_reagents(reagents.reagent_list)
		. += M

/obj/item/reagent_containers/glass/flagon/on_reagent_change()
	update_icon()

/obj/item/reagent_containers/glass/flagon/update_icon()
	. = ..()
	overlays.Cut()
	if (!is_open_container())
		var/image/lid = image(icon, src, "[initial(icon_state)]_closed")
		overlays += lid

/////////////////////////////////////////////////////////////////////////
