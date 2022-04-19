/obj/item/reagent_containers/sack
	name = "sack"
	desc = "sack of balls"
	icon = 'dwarfs/icons/items/kitchen.dmi'
	icon_state = "bag"
	volume = 80
	allowed_reagents = list(/datum/reagent/grain, /datum/reagent/flour)
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list()

/obj/item/reagent_containers/sack/examine(mob/user)
	. = ..()
	if(!reagents.total_volume)
		.+="<br>It's empty."
	else
		.+="<br>It has [reagents.get_reagent_names()] in it."

/obj/item/reagent_containers/sack/update_icon(updates)
	. = ..()
	if(reagents.has_reagent_subtype(/datum/reagent/grain))
		icon_state = "bag_grain"
	else if(reagents.has_reagent_subtype(/datum/reagent/flour))
		icon_state = "bag_flour"
	else
		icon_state = "bag"

/obj/item/reagent_containers/cooking_pot
	name = "cooking pot"
	desc = "boomer"
	icon = 'dwarfs/icons/items/kitchen.dmi'
	icon_state = "cooking_pot_open"
	amount_per_transfer_from_this = 10
	volume = 50
	var/open = TRUE

/obj/item/reagent_containers/cooking_pot/update_overlays()
	. = ..()
	if(open && reagents.total_volume)
		var/mutable_appearance/M = mutable_appearance("dwarfs/icons/items/kitchen.dmi", "cooking_pot_overlay")
		M.color = mix_color_from_reagents(reagents.reagent_list)
		. += M

/obj/item/reagent_containers/cooking_pot/update_icon_state()
	. = ..()
	if(open)
		icon_state = "cooking_pot_open"
	else
		icon_state = "cooking_pot_closed"

/obj/item/reagent_containers/cooking_pot/attack_self_secondary(mob/user, modifiers)
	open = !open
	update_appearance()
	to_chat(user, span_notice("You [open?"open":"close"] [src]."))
	amount_per_transfer_from_this = open ? initial(amount_per_transfer_from_this) : 0 // cannot transfer reagents when closed