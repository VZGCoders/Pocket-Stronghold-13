/obj/structure/anvil
	name = "anvil"
	desc = "Sturdy enough to withstand all those missed hits."
	icon = 'dwarfs/icons/structures/workshops.dmi'
	icon_state = "anvil"
	density = TRUE
	anchored = TRUE
	var/obj/item/ingot/current_ingot = null
	var/list/allowed_things = list()

/obj/structure/anvil/update_overlays()
	. = ..()
	if(current_ingot)
		var/mutable_appearance/Ingot = mutable_appearance('dwarfs/icons/structures/workshops.dmi', "anvil_ingot")
		Ingot.color = current_ingot.metal_color
		. += Ingot
		var/mutable_appearance/Ingot_heat = mutable_appearance('dwarfs/icons/structures/workshops.dmi', "anvil_ingot")
		Ingot_heat.color = "#ffb35c"
		Ingot_heat.alpha =  255 * (current_ingot.heattemp / 350)
		. += Ingot_heat

/obj/structure/anvil/Topic(href, list/href_list)
	. = ..()
	if(.)
		return .
	if(!usr.is_holding_item_of_type(/obj/item/smithing_hammer)||!(usr in view(1, src)))
		usr<<browse(null, "window=Anvil")
		return
	if(href_list["hit"])
		hit(usr)
	if(href_list["miss"])
		miss(usr)

/obj/structure/anvil/proc/hit(mob/user)
	if(current_ingot.heattemp <= 0)
		update_appearance()
		to_chat(user, span_warning("\The [current_ingot] is to cold too keep working."))
		usr<<browse(null, "window=Anvil")
		return
	var/mob/living/carbon/human/H = user
	if(current_ingot.progress_current == current_ingot.progress_need)
		current_ingot.progress_current++
		playsound(src, 'dwarfs/sounds/tools/anvil/anvil_hit.ogg', 70, TRUE)
		to_chat(user, span_notice("[current_ingot] is ready. Hit it again to keep smithing or cool it down."))
		user<<browse(null, "window=Anvil")
	else
		playsound(src, 'dwarfs/sounds/tools/anvil/anvil_hit.ogg', 70, TRUE)
		user.visible_message(span_notice("<b>[user]</b> hits \the anvil with \a hammer.") , \
						span_notice("You hit \the anvil with \a hammer."))
		current_ingot.progress_current++
		H.adjustStaminaLoss(rand(1, 1)) //Stamina Used Per Smithing Action (1-5 Default). Reduced to 1-1 to reduce blacksmith rage - Art
		H.mind.adjust_experience(/datum/skill/smithing, rand(0, 4) * current_ingot.grade)

/obj/structure/anvil/proc/miss(mob/user)
	if(current_ingot.heattemp <= 0)
		update_appearance()
		to_chat(user, span_warning("\The [current_ingot] is to cold too keep working."))
		usr<<browse(null, "window=Anvil")
		return
	current_ingot.durability--
	if(current_ingot.durability == 0)
		to_chat(user, span_warning("the ingot crumbles into countless metal pieces..."))
		current_ingot = null
		LAZYCLEARLIST(contents)
		update_appearance()
		user<<browse(null, "window=Anvil")
	playsound(src, 'dwarfs/sounds/tools/anvil/anvil_hit.ogg', 70, TRUE)
	user.visible_message(span_warning("<b>[user]</b> hits \the anvil with \a hammer incorrectly.") , \
						span_warning("You hit \the anvil with \a hammer incorrectly."))
	return

/obj/structure/anvil/Initialize()
	. = ..()
	for(var/item in subtypesof(/datum/smithing_recipe))
		var/datum/smithing_recipe/SR = new item()
		allowed_things += SR

/obj/structure/anvil/proc/load_slider(var/obj/item/smithing_hammer/hammer, var/mob/living/carbon/human/H)
	var/html = file2text('dwarfs/code/modules/blacksmithing/minigames/slider.html')
	var/list/to_replace = list("HITHERE", "MISSHERE", "SPEEDHERE", "WIDTHHERE")
	var/list/replaceble = list("byond://?src=[REF(src)];hit=1", "byond://?src=[REF(src)];miss=1", "[1+current_ingot.grade]", "[20+H.mind.get_skill_modifier(/datum/skill/smithing, SKILL_SMITHING_MODIFIER)+hammer.grade*3]")
	for(var/i in 1 to length(to_replace))
		html = replacetext(html, to_replace[i], replaceble[i])
	return html

/obj/structure/anvil/attackby(obj/item/I, mob/living/user, params)

	if(user.a_intent == INTENT_HARM)
		return ..()

	if(!ishuman(user))
		to_chat(user, span_warning("My hands are too weak to do this!"))
		return

	var/mob/living/carbon/human/H = user

	if(istype(I, /obj/item/smithing_hammer))
		var/obj/item/smithing_hammer/hammer = I
		if(current_ingot)
			if(current_ingot.heattemp <= 0)
				update_appearance()
				to_chat(user, span_warning("\The [current_ingot] is to cold too keep working."))
				return
			if(current_ingot.recipe)
				var/height = 30
				var/html = load_slider(hammer, H)
				html = format_text(html)
				if(current_ingot.progress_current <= current_ingot.progress_need)
					var/datum/browser/popup = new(user, "Anvil", "Anvil", 500, height+120)
					popup.set_content(html)
					popup.open()
					return
				if(current_ingot.progress_current > current_ingot.progress_need)
					current_ingot.progress_current = 0
					current_ingot.grade++
					current_ingot.progress_need = round(current_ingot.progress_need * 1.1)
					to_chat(user, span_notice("You hit \the anvil with \a [hammer]."))
					playsound(src, 'dwarfs/sounds/tools/anvil/anvil_hit.ogg', 70, TRUE)
					to_chat(user, span_notice("You begin to upgrade \the [current_ingot]."))
			else
				var/list/metal_allowed_list = list()
				for(var/datum/smithing_recipe/SR in allowed_things)
					if(SR.metal_type_need == current_ingot.type_metal)
						metal_allowed_list += SR
				var/datum/smithing_recipe/sel_recipe = input("Choose:", "What to forge?", null, null) as null|anything in metal_allowed_list
				if(!sel_recipe)
					to_chat(user, span_warning("You did not decide what to forge yet."))
					return
				if(current_ingot.recipe)
					to_chat(user, span_warning("Too late to change your mind."))
					return
				current_ingot.recipe = new sel_recipe.type()
				playsound(src, 'dwarfs/sounds/tools/anvil/anvil_hit.ogg', 70, TRUE)
				to_chat(user, span_notice("You begin to forge..."))
		else
			to_chat(user, span_warning("Nothing to forge here."))

	else if(istype(I, /obj/item/tongs))
		if(current_ingot)
			if(I.contents.len)
				to_chat(user, span_warning("You are already holding something!"))
				return
			else
				current_ingot.forceMove(I)
				current_ingot = null
				to_chat(user, span_notice("You grab the ingot with \the [I]."))
				I.update_appearance()
				update_appearance()
		else
			if(I.contents.len)
				if(current_ingot)
					to_chat(user, span_warning("You are already holding \a [current_ingot]."))
					return
				var/obj/item/ingot/N = I.contents[I.contents.len]
				N.forceMove(src)
				current_ingot = N
				to_chat(user, span_notice("You place \the [current_ingot] onto \the [src]."))
				update_appearance()
				I.update_appearance()
			else
				to_chat(user, span_warning("Nothing to grab with [I]."))
	else
		return ..()
