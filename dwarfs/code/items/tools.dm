/*****************Pickaxes & Drills & Shovels****************/
/obj/item/pickaxe
	name = "pickaxe"
	desc = "Strike the earth!"
	icon = 'dwarfs/icons/items/tools.dmi'
	icon_state = "pickaxe"
	slot_flags = ITEM_SLOT_BACK
	force = 15
	atck_type = PIERCE
	throwforce = 10
	inhand_icon_state = "pickaxe"
	worn_icon_state = "pickaxe"
	lefthand_file = 'dwarfs/icons/mob/inhand/lefthand.dmi'
	righthand_file = 'dwarfs/icons/mob/inhand/righthand.dmi'
	worn_icon = 'dwarfs/icons/mob/clothing/back.dmi'
	w_class = WEIGHT_CLASS_BULKY
	tool_behaviour = TOOL_PICKAXE
	toolspeed = 1.5
	usesound = list('sound/effects/picaxe1.ogg', 'sound/effects/picaxe2.ogg', 'sound/effects/picaxe3.ogg')
	attack_verb_continuous = list("hits", "pierces", "slashes", "attacks")
	attack_verb_simple = list("hit", "pierce", "slash", "attacks")

/obj/item/pickaxe/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] begins digging into [user.p_their()] chest! It looks like [user.p_theyre()] trying to commit suicide!"))
	if(use_tool(user, user, 30, volume=50))
		return BRUTELOSS
	user.visible_message(span_suicide("[user] couldn't do it!"))
	return SHAME

/obj/item/shovel
	name = "shovel"
	desc = "Shovel made for excavating soils."
	icon = 'dwarfs/icons/items/tools.dmi'
	icon_state = "shovel"
	worn_icon_state = "shovel"
	lefthand_file = 'dwarfs/icons/mob/inhand/lefthand.dmi'
	righthand_file = 'dwarfs/icons/mob/inhand/righthand.dmi'
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	force = 8
	tool_behaviour = TOOL_SHOVEL
	toolspeed = 1
	usesound = 'sound/effects/shovel_dig.ogg'
	throwforce = 4
	inhand_icon_state = "shovel"
	w_class = WEIGHT_CLASS_NORMAL
	custom_materials = list(/datum/material/iron=50)
	attack_verb_continuous = list("smashes", "hits", "attacks")
	attack_verb_simple = list("smash", "hit", "attack")
	atck_type = SHARP

/obj/item/shovel/Initialize()
	. = ..()
	AddComponent(/datum/component/butchering, 150) //it's sharp, so it works, but barely.

/obj/item/shovel/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] begins digging their own grave! It looks like [user.p_theyre()] trying to commit suicide!"))
	if(use_tool(user, user, 30, volume=50))
		return BRUTELOSS
	user.visible_message(span_suicide("[user] couldn't do it!"))
	return SHAME

/obj/item/axe
	name = "axe"
	desc = "A common tool for chopping down trees."
	icon = 'dwarfs/icons/items/tools.dmi'
	worn_icon = 'dwarfs/icons/mob/clothing/back.dmi'
	lefthand_file = 'dwarfs/icons/mob/inhand/lefthand.dmi'
	righthand_file = 'dwarfs/icons/mob/inhand/righthand.dmi'
	icon_state = "axe"
	tool_behaviour = TOOL_AXE
	force = 10
	throwforce = 5
	atck_type = SHARP
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_BACK
	hitsound = 'sound/weapons/bladeslice.ogg'
	usesound = 'dwarfs/sounds/tools/axe/axe_chop.ogg'

/obj/item/smithing_hammer
	name = "smithing hammer"
	desc = "Used for forging."
	icon = 'dwarfs/icons/items/tools.dmi'
	lefthand_file = 'dwarfs/icons/mob/inhand/lefthand.dmi'
	righthand_file = 'dwarfs/icons/mob/inhand/righthand.dmi'
	icon_state = "smithing_hammer"
	w_class = WEIGHT_CLASS_HUGE
	force = 20
	throwforce = 25
	throw_range = 4
	atck_type = BLUNT

/obj/item/smithing_hammer/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	..()
	if(iswallturf(target) && proximity_flag)
		user.changeNext_move(CLICK_CD_MELEE)
		var/turf/closed/wall/W = target
		var/chance = (W.hardness * 0.5)
		if(chance < 10)
			return FALSE

		if(prob(chance))
			playsound(src, 'sound/effects/meteorimpact.ogg', 100, 1)
			W.dismantle_wall(TRUE)

		else
			playsound(src, 'sound/effects/bang.ogg', 50, 1)
			W.add_dent(WALL_DENT_HIT)
			visible_message(span_danger("<b>[user]</b> hits the <b>[W]</b> with [src]!") , null, COMBAT_MESSAGE_RANGE)
	return TRUE

/obj/item/chisel
	name = "chisel"
	desc = "Chisel, used by masons to process stone goods."
	icon = 'dwarfs/icons/items/tools.dmi'
	icon_state = "chisel"
	lefthand_file = 'dwarfs/icons/mob/inhand/lefthand.dmi'
	righthand_file = 'dwarfs/icons/mob/inhand/righthand.dmi'
	hitsound = 'sound/weapons/bladeslice.ogg'
	usesound = 'dwarfs/sounds/tools/chisel/chisel_hit.ogg'
	tool_behaviour = TOOL_CHISEL
	atck_type = PIERCE
	w_class = WEIGHT_CLASS_SMALL
	force = 10
	throwforce = 12
	throw_range = 7

/obj/item/tongs
	name = "tongs"
	desc = "Essential tool for smithing."
	icon = 'dwarfs/icons/items/tools.dmi'
	lefthand_file = 'dwarfs/icons/mob/inhand/lefthand.dmi'
	righthand_file = 'dwarfs/icons/mob/inhand/righthand.dmi'
	inhand_icon_state = "tongs"
	icon_state = "tongs_open"
	w_class = WEIGHT_CLASS_SMALL
	force = 4
	atck_type = BLUNT
	throwforce = 6
	throw_range = 7

/obj/item/tongs/update_icon_state()
	. = ..()
	if(contents.len)
		icon_state = "tongs_closed"
	else
		icon_state = "tongs_open"

/obj/item/tongs/update_overlays()
	. = ..()
	if(contents.len)
		var/obj/item/ingot/I = contents[1]
		var/mutable_appearance/Ingot = mutable_appearance('dwarfs/icons/items/tools.dmi', "tongs_ingot")
		Ingot.color = I.metal_color
		. += Ingot
		var/mutable_appearance/Ingot_heat = mutable_appearance('dwarfs/icons/items/tools.dmi', "tongs_ingot")
		Ingot_heat.color = "#ffb35c"
		Ingot_heat.alpha =  255 * (I.heattemp / 350)
		. += Ingot_heat

/obj/item/tongs/worn_overlays(isinhands, icon_file)
	. = ..()
	if(contents.len)
		var/obj/item/ingot/I = contents[1]
		var/mutable_appearance/Ingot = mutable_appearance(icon_file, "tongs_ingot")
		Ingot.color = I.metal_color
		. += Ingot
		var/mutable_appearance/Ingot_heat = mutable_appearance(icon_file, "tongs_ingot")
		Ingot_heat.color = "#ffb35c"
		Ingot_heat.alpha =  255 * (I.heattemp / 350)
		. += Ingot_heat

/obj/item/tongs/update_appearance(updates)
	. = ..()
	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_hands()

/obj/item/tongs/attack_self(mob/user)
	. = ..()
	if(contents.len)
		var/obj/O = contents[contents.len]
		O.forceMove(drop_location())
		update_appearance()

#define TROWEL_BUILD_FLOOR 1
#define TROWEL_BUILD_WALL 2
#define TROWEL_BUILD_DOOR 3
#define TROWEL_BUILD_TABLE 4
#define TROWEL_BUILD_CHAIR 5
#define TROWEL_BUILD_STAIRS 6

/obj/item/trowel
	name = "trowel"
	desc = "Used for building purposes."
	icon = 'dwarfs/icons/items/tools.dmi'
	icon_state = "trowel"
	lefthand_file = 'dwarfs/icons/mob/inhand/lefthand.dmi'
	righthand_file = 'dwarfs/icons/mob/inhand/righthand.dmi'
	usesound = 'dwarfs/sounds/tools/trowel/trowel_dig.ogg'
	w_class = WEIGHT_CLASS_SMALL
	force = 8
	atck_type = PIERCE
	throwforce = 12
	throw_range = 3
	var/mode = TROWEL_BUILD_FLOOR
	var/mat_need = 0

/obj/item/trowel/afterattack(atom/A, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	do_job(A, user)

/obj/item/trowel/proc/check_resources()
	var/mat_to = 0
	mat_need = 0
	for(var/obj/item/stack/sheet/stone/B in view(1))
		mat_to += B.amount
	switch(mode)
		if(TROWEL_BUILD_WALL) mat_need = 4
		if(TROWEL_BUILD_FLOOR) mat_need = 1
		if(TROWEL_BUILD_STAIRS) mat_need = 3
		if(TROWEL_BUILD_DOOR) mat_need = 3
	if(mat_to >= mat_need)
		return TRUE
	else
		return FALSE

/obj/item/trowel/proc/use_resources(turf/T, mob/user)
	var/needed = mat_need
	for(var/obj/item/stack/sheet/stone/B in view(1))
		var/temp_needed = needed
		while(!B.use(temp_needed))
			temp_needed--
		needed -= temp_needed
		if(needed == 0) break
	switch(mode)
		if(TROWEL_BUILD_WALL)
			T.ChangeTurf(/turf/closed/wall/stone, /turf/open/floor/rock)
			user.visible_message(span_notice("<b>[user]</b> constructs a stone wall.") , \
								span_notice("You construct a stone wall."))
		if(TROWEL_BUILD_FLOOR)
			if(isopenspace(T))
				var/obj/L = locate(/obj/structure/lattice) in T
				if(!L)
					to_chat(user, span_warning("[src] requires a lattice to build floor."))
					return
				else
					qdel(L)
			T.ChangeTurf(/turf/open/floor/stone)
			user.visible_message(span_notice("<b>[user]</b> constructs stone floor.") , \
								span_notice("You construct stone floor."))
		if(TROWEL_BUILD_STAIRS)
			var/obj/structure/stairs/S = new(T)
			S.dir = user.dir
			user.visible_message(span_notice("<b>[user]</b> constructs stone stairs."), span_notice("You construct stone stairs."))
		if(TROWEL_BUILD_DOOR)
			var/obj/structure/mineral_door/heavystone/D = new(T)
			D.dir = user.dir
			user.visible_message(span_notice("<b>[user]</b> constructs stone door."), span_notice("You construct stone door."))

/obj/item/trowel/proc/do_job(atom/A, mob/user)
	if(mode != TROWEL_BUILD_FLOOR && !isfloorturf(A))
		to_chat(user, span_warning("Can't build here!"))
		return
	else if((mode == TROWEL_BUILD_FLOOR && !isfloorturf(A) && !isopenspace(A)) || (mode == TROWEL_BUILD_FLOOR && isopenspace(A) && !(locate(/obj/structure/lattice) in A)))
		to_chat(user, span_warning("Can't build here!"))
		return
	else if(mode == TROWEL_BUILD_DOOR && !isfloorturf(A))
		to_chat(user, span_warning("Can't build here!"))
		return
	var/turf/T = get_turf(A)
	if(check_resources())
		var/channel = playsound(src.loc, 'dwarfs/sounds/tools/trowel/trowel_dig.ogg', 50, TRUE)
		if(do_after(user, 5 SECONDS, target = A))
			stop_sound_channel_nearby(src, channel)
			if(check_resources())
				use_resources(T, user)
				playsound(src.loc, 'sound/machines/click.ogg', 50, TRUE)
				return TRUE
	else
		to_chat(user, span_warning("Not enough materials!"))

/obj/item/trowel/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

/obj/item/trowel/attack_self(mob/user)
	..()
	var/list/choices = list(
		"Floor" = image(icon = 'dwarfs/icons/turf/floors.dmi', icon_state = "stone_floor"),
		"Wall" = image(icon = 'dwarfs/icons/turf/walls_dwarven.dmi', icon_state = "rich_wall-0"),
		"Stairs" = image(icon='dwarfs/icons/structures/stone_stairs.dmi', icon_state = "stairs_t"),
		"Door" = image(icon='dwarfs/icons/structures/stonedoor.dmi', icon_state = "heavystone")
	)
	var/choice = show_radial_menu(user, src, choices, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(choice)
		if("Floor")
			mode = TROWEL_BUILD_FLOOR
		if("Wall")
			mode = TROWEL_BUILD_WALL
		if("Stairs")
			mode = TROWEL_BUILD_STAIRS
		if("Door")
			mode = TROWEL_BUILD_DOOR

#undef TROWEL_BUILD_FLOOR
#undef TROWEL_BUILD_WALL
#undef TROWEL_BUILD_DOOR
#undef TROWEL_BUILD_TABLE
#undef TROWEL_BUILD_CHAIR

/obj/item/hoe
	name = "hoe"
	desc = "Till the earth!"
	tool_behaviour = TOOL_HOE
	usesound = 'dwarfs/sounds/tools/hoe/hoe_dig.ogg'
	icon = 'dwarfs/icons/items/tools.dmi'
	icon_state = "hoe"
	lefthand_file = 'dwarfs/icons/mob/inhand/lefthand.dmi'
	righthand_file = 'dwarfs/icons/mob/inhand/righthand.dmi'
	atck_type = PIERCE
	force = 7
