/obj/structure/dwarf_altar
	name = "Altar"
	desc = "A place to praise The God of Blood"
	icon = 'dwarfs/icons/structures/32x64.dmi'
	icon_state = "altarus_off"
	density = TRUE
	anchored = TRUE
	layer = ABOVE_MOB_LAYER
	var/busy = FALSE
	var/active = FALSE
	var/resources = 0
	var/list/available_rituals = list(/datum/ritual/summon_tools,/datum/ritual/summon_frog,/datum/ritual/summon_dwarf,/datum/ritual/summon_seeds)
	var/list/allowed_resources = list(/obj/item/ingot/gold=25,
									/obj/item/stack/sheet/mineral/gem/diamond=50,
									/obj/item/stack/sheet/mineral/gem/ruby=40,
									/obj/item/stack/sheet/mineral/gem/sapphire=30)
	var/list/spawnable_seeds = list(/obj/item/growable/seeds/carrot, /obj/item/growable/seeds/cave_wheat, /obj/item/growable/seeds/turnip,
			 					   /obj/item/growable/seeds/pig_tail, /obj/item/growable/seeds/plump_helmet, /obj/item/growable/seeds/sweet_pod,
			  					   /obj/item/growable/seeds/barley, /obj/item/growable/seeds/cotton)

/obj/structure/dwarf_altar/Initialize()
	. = ..()
	set_light(1)

/obj/structure/dwarf_altar/proc/activate()
	icon_state = "altarus_on"

/obj/structure/dwarf_altar/attack_ghost(mob/user)
	summon_dwarf(user)

/obj/structure/dwarf_altar/proc/summon_dwarf(mob/user)
	if(!active)
		return FALSE
	var/dwarf_ask = tgui_alert(usr, "Become a dwarf?", "DIG?", list("Yes", "No"))
	if(dwarf_ask != "Yes" || !src || QDELETED(src) || QDELETED(user))
		return FALSE
	if(!active)
		to_chat(user, span_warning("Already used!"))
		return FALSE
	var/mob/living/carbon/human/D = new /mob/living/carbon/human(loc)
	D.set_species(/datum/species/dwarf)
	D.equipOutfit(/datum/outfit/dwarf)
	D.key = user.key
	D.mind.assigned_role = "Dwarf"
	active = FALSE
	to_chat(D, "<span class='big bold'>I am a dwarf in god knows where.</span>")
	deactivate()

/obj/structure/dwarf_altar/proc/deactivate()
	icon_state = "altarus_off"

/obj/structure/dwarf_altar/attackby(obj/item/I, mob/living/user, params)
	if((I.type in allowed_resources))
		to_chat(user, span_notice("You sacrifice [I.name]"))
		resources+=allowed_resources[I.type]
		qdel(I)
	else if(istype(I, /obj/item/damaz))
		var/obj/item/damaz/D = I
		if(!D.can_use(user))
			return
		ui_interact(user)
	else
		..()

/obj/structure/dwarf_altar/attack_hand(mob/user)
	if(ishuman(user) && !isdwarf(user))
		if(!active)
			to_chat(user, span_warning("[src] is not ready!"))
			return
		var/mob/living/carbon/human/M = user
		var/dwarf_ask = tgui_alert(M, "Become a dwarf?", "DIG?", list("Yes", "No"))
		if(dwarf_ask != "Yes" || !src || QDELETED(src) || QDELETED(M))
			return FALSE
		if(!active)
			to_chat(M, span_warning("Already used!"))
			return FALSE
		M.set_species(/datum/species/dwarf)
		M.unequip_everything()
		M.equipOutfit(/datum/outfit/dwarf)
		active = FALSE
		to_chat(M, span_notice("You become a dwarf."))

/obj/structure/dwarf_altar/proc/perform_rite(rite, mob/user)
	var/datum/ritual/R = new rite
	if(busy)
		return
	busy = TRUE
	to_chat(user, span_notice("You start a ritual."))
	activate()
	if(!do_after(user, 3 SECONDS, target = src))
		busy = FALSE
		deactivate()
		return
	switch(initial(R.true_name))
		if("seeds")
			//spawns from 1 to 4 random seeds
			for(var/i in 1 to rand(2,4))
				var/seed = spawnable_seeds[rand(0,7)]
				new seed(loc)
		if("dwarf")
			active = TRUE
			notify_ghosts("New dwarf is ready.", source = src, action = NOTIFY_ORBIT, flashwindow = FALSE, header = "Dwarf spawn available.")
			webhook_send_respawn_notice(user.ckey, "New dwarf is ready.")
		if("frog")
			new /mob/living/simple_animal/hostile/retaliate/frog(loc)
		if("tools")
			for(var/tool in list(/obj/item/smithing_hammer, /obj/item/tongs, /obj/item/builder_hammer, /obj/item/chisel, /obj/item/pickaxe))
				new tool(loc)
	busy = FALSE
	to_chat(user, span_notice("You finish the ritual."))
	deactivate()
	qdel(R)

/obj/structure/dwarf_altar/proc/generate_rituals()
	var/list/rituals = list()
	for(var/rt in available_rituals)
		var/list/rite = list()
		var/datum/ritual/R = rt
		rite["name"] = initial(R.name)
		rite["cost"] = initial(R.cost)
		rite["desc"] = initial(R.desc)
		rite["path"] = R
		rituals+=list(rite)
	return rituals

/obj/structure/dwarf_altar/ui_interact(mob/user, datum/tgui/ui)
  ui = SStgui.try_update_ui(user, src, ui)
  if(!ui)
    ui = new(user, src, "DwarfAltar")
    ui.open()

/obj/structure/dwarf_altar/ui_data(mob/user)
	var/list/data = list()
	var/list/rituals = generate_rituals()
	data["favor"] = resources
	data["rituals"] = rituals
	return data

/obj/structure/dwarf_altar/ui_act(action, params)
	. = ..()
	var/cost = params["cost"]
	if(cost>resources)
		to_chat(usr, span_warning("Not enough favor!"))
		return
	resources-=cost
	perform_rite(params["path"], usr)
	update_icon()
