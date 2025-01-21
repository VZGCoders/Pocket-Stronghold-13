/* This file contains standalone items for debug purposes. */

/obj/item/debug/human_spawner
	name = "human spawner"
	desc = "Spawn a human by aiming at a turf and clicking. Use in hand to change type."
	icon = 'icons/obj/guns/magic.dmi'
	icon_state = "nothingwand"
	inhand_icon_state = "wand"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	var/datum/species/selected_species
	var/valid_species = list()

/obj/item/debug/human_spawner/afterattack(atom/target, mob/user, proximity)
	..()
	if(isturf(target))
		var/mob/living/carbon/human/H = new /mob/living/carbon/human(target)
		if(selected_species)
			H.set_species(selected_species)

/obj/item/debug/human_spawner/attack_self(mob/user)
	..()
	var/choice = input("Select a species", "Human Spawner", null) in GLOB.species_list
	selected_species = GLOB.species_list[choice]

/obj/item/debug/omnitool
	name = "omnitool"
	desc = "The original hypertool, born before them all. Use it in hand to unleash its true power."
	icon_state = "hypertool"
	inhand_icon_state = "hypertool"
	toolspeed = 0.1
	tool_behaviour = null

/obj/item/debug/omnitool/examine()
	. = ..()
	. += "<hr>The mode is: [tool_behaviour]"

/obj/item/debug/omnitool/proc/check_menu(mob/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

/obj/item/debug/omnitool/attack_self(mob/user)
	if(!user)
		return
	var/list/tool_list = list(
		"Pickaxe" = image(icon = 'icons/obj/mining.dmi', icon_state = "pickaxe"),
		"Shovel" = image(icon = 'icons/obj/mining.dmi', icon_state = "shovel"),
		"Knife" = image(icon = 'icons/obj/tools.dmi', icon_state = "knife"),
		"Rolling Pin" = image(icon = 'icons/obj/tools.dmi', icon_state = "rolling_pin")
		)
	var/tool_result = show_radial_menu(user, src, tool_list, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(tool_result)
		if("Pickaxe")
			tool_behaviour = TOOL_PICKAXE
		if("Shovel")
			tool_behaviour = TOOL_SHOVEL
		if("Knife")
			tool_behaviour = TOOL_KNIFE
		if("Rolling Pin")
			tool_behaviour = TOOL_ROLLINGPIN
