
/obj/item/reagent_containers/glass
	name = "glass"
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5, 10, 15, 20, 25, 30, 50)
	volume = 50
	reagent_flags = OPENCONTAINER | DUNKABLE
	spillable = TRUE
	resistance_flags = ACID_PROOF


/obj/item/reagent_containers/glass/attack(mob/living/M, mob/user, obj/target)
	if(!canconsume(M, user))
		return

	if(!spillable)
		return

	if(!reagents || !reagents.total_volume)
		to_chat(user, span_warning("[capitalize(src.name)] is empty!"))
		return

	if(istype(M))
		if(user.a_intent == INTENT_HARM)
			var/R
			M.visible_message(span_danger("[user] splashes [src]'s contents onto \the [M]!") , \
							span_userdanger("[user] splashes [src]'s contents onto you!"))
			if(reagents)
				for(var/datum/reagent/A in reagents.reagent_list)
					R += "[A] ([num2text(A.volume)]),"

			if(isturf(target) && reagents.reagent_list.len && thrownby)
				log_combat(thrownby, target, "splashed (thrown) [english_list(reagents.reagent_list)]")
				message_admins("[ADMIN_LOOKUPFLW(thrownby)] splashed (thrown) [english_list(reagents.reagent_list)] on [target] at [ADMIN_VERBOSEJMP(target)].")
			reagents.expose(M, TOUCH)
			log_combat(user, M, "splashed", R)
			reagents.clear_reagents()
		else
			if(M != user)
				if(M.hydration >= HYDRATION_LEVEL_OVERHYDRATED)
					M.visible_message(span_danger("[user] cannot force any more of [src]'s contents down [M]'s throat."), \
					span_userdanger("[user] cannot force any more of [src]'s contents down your throat."))
					return
				M.visible_message(span_danger("[user] attempts to feed [M] something from [src].") , \
							span_userdanger("[user] attempts to feed you something from [src]."))
				if(!do_mob(user, M))
					return
				if(!reagents || !reagents.total_volume)
					return // The drink might be empty after the delay, such as by spam-feeding
				M.visible_message(span_danger("[user] feeds [M] something from [src].") , \
							span_userdanger("[user] feeds you something from [src]."))
				log_combat(user, M, "fed", reagents.log_list())
			else
				if(user.hydration >= HYDRATION_LEVEL_OVERHYDRATED)
					to_chat(M, span_warning("You cannot force any more of [src]'s contents down your throat!"))
					return
				to_chat(user, span_notice("You swallow a gulp from [src]."))

			for(var/datum/reagent/R in reagents.reagent_list)
				if(R in M.known_reagent_sounds)
					continue
				M.known_reagent_sounds += R
				SEND_SOUND(M, R.special_sound)
				break

			SEND_SIGNAL(src, COMSIG_GLASS_DRANK, M, user)
			addtimer(CALLBACK(reagents, /datum/reagents.proc/trans_to, M, 5, TRUE, TRUE, FALSE, user, FALSE, INGEST), 5)
			playsound(M.loc,'sound/items/drink.ogg', rand(10,50), TRUE)

/obj/item/reagent_containers/glass/afterattack(obj/target, mob/user, proximity)
	. = ..()
	if((!proximity) || !check_allowed_items(target,target_self=1))
		return

	if(!spillable)
		return

	if(target.is_refillable()) //Something like a glass. Player probably wants to transfer TO it.
		if(!reagents.total_volume)
			to_chat(user, span_warning("[capitalize(src.name)] is empty!"))
			return

		if(target.reagents.holder_full())
			to_chat(user, span_warning("[target] is full."))
			return

		var/trans = reagents.trans_to(target, amount_per_transfer_from_this, transfered_by = user)
		to_chat(user, span_notice("You transfer [trans] unit\s of the contents to [target]."))


	else if(target.is_drainable()) //A dispenser. Transfer FROM it TO us.
		if(!target.reagents.total_volume)
			to_chat(user, span_warning("[target] is empty and cannot be refilled!"))
			return

		if(reagents.holder_full())
			to_chat(user, span_warning("[capitalize(src.name)] is full."))
			return

		var/trans = target.reagents.trans_to(src, amount_per_transfer_from_this, transfered_by = user)
		to_chat(user, span_notice("You fill [src] with [trans] units from [target]."))


	else if(reagents.total_volume)
		if(user.a_intent == INTENT_HARM)
			user.visible_message(span_danger("[user] splashes [src]'s contents on [target]!") , \
								span_notice("You splash [src]'s contents on [target]."))
			reagents.expose(target, TOUCH)
			reagents.clear_reagents()

/obj/item/reagent_containers/glass/attackby(obj/item/I, mob/user, params)
	var/hotness = I.get_temperature()
	if(hotness && reagents)
		reagents.expose_temperature(hotness)
		to_chat(user, span_notice("You heat [name] with [I]!"))
	..()

/*
 * On accidental consumption, make sure the container is partially glass, and continue to the reagent_container proc
 */
/obj/item/reagent_containers/glass/on_accidental_consumption(mob/living/carbon/M, mob/living/carbon/user, obj/item/source_item, discover_after = TRUE)
	return ..()

/obj/item/reagent_containers/glass/bucket
	name = "bucket"
	desc = "It's a bucket."
	icon = 'dwarfs/icons/items/containers.dmi'
	worn_icon = 'dwarfs/icons/mob/clothing/head.dmi'
	icon_state = "bucket"
	inhand_icon_state = "bucket"
	lefthand_file = 'dwarfs/icons/mob/inhand/lefthand.dmi'
	righthand_file = 'dwarfs/icons/mob/inhand/righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	amount_per_transfer_from_this = 20
	possible_transfer_amounts = list(5,10,15,20,25,30,50,100)
	volume = 100
	flags_inv = HIDEHAIR
	slot_flags = ITEM_SLOT_HEAD
	resistance_flags = NONE
	slot_equipment_priority = list( \
		ITEM_SLOT_BACK,
		ITEM_SLOT_ICLOTHING, ITEM_SLOT_OCLOTHING,\
		ITEM_SLOT_MASK, ITEM_SLOT_HEAD, ITEM_SLOT_NECK,\
		ITEM_SLOT_FEET, ITEM_SLOT_GLOVES,\
		ITEM_SLOT_EARS, ITEM_SLOT_EYES,\
		ITEM_SLOT_BELT, ITEM_SLOT_SUITSTORE,\
		ITEM_SLOT_LPOCKET, ITEM_SLOT_RPOCKET,\
		ITEM_SLOT_DEX_STORAGE
	)

#define SQUEEZING_DISPERSAL_PERCENT 0.75

/obj/item/reagent_containers/glass/bucket/attackby(obj/O, mob/living/user, params)
	if(istype(O, /obj/item/mop))
		if(user.a_intent == INTENT_HARM)
			if(O.reagents.total_volume == 0)
				to_chat(user, span_warning("[capitalize(O.name)] is empty!"))
				return
			if(reagents.total_volume == reagents.maximum_volume)
				to_chat(user, span_warning("[capitalize(src.name)] is full!"))
				return
			O.reagents.remove_any(O.reagents.total_volume*SQUEEZING_DISPERSAL_PERCENT)
			O.reagents.trans_to(src, O.reagents.total_volume, transfered_by = user)
			to_chat(user, span_notice("You wet [O.name] in [src.name]."))
		else
			if(reagents.total_volume < 1)
				to_chat(user, span_warning("[capitalize(src.name)] is empty!"))
			else
				reagents.trans_to(O, 5, transfered_by = user)
				to_chat(user, span_notice("You wet [O.name] in [src.name]."))
				playsound(loc, 'sound/effects/slosh.ogg', 25, TRUE)
	else
		..()

#undef SQUEEZING_DISPERSAL_PERCENT

/obj/item/reagent_containers/glass/bucket/equipped(mob/user, slot)
	..()
	if (slot == ITEM_SLOT_HEAD)
		if(reagents.total_volume)
			to_chat(user, span_userdanger("[capitalize(src.name)]'s contents spill all over you!"))
			reagents.expose(user, TOUCH)
			reagents.clear_reagents()
		reagents.flags = NONE

/obj/item/reagent_containers/glass/bucket/dropped(mob/user)
	. = ..()
	reagents.flags = initial(reagent_flags)

/obj/item/reagent_containers/glass/bucket/equip_to_best_slot(mob/M)
	if(reagents.total_volume) //If there is water in a bucket, don't quick equip it to the head
		var/index = slot_equipment_priority.Find(ITEM_SLOT_HEAD)
		slot_equipment_priority.Remove(ITEM_SLOT_HEAD)
		. = ..()
		slot_equipment_priority.Insert(index, ITEM_SLOT_HEAD)
		return
	return ..()

/obj/item/reagent_containers/glass/bucket/update_overlays()
	. = ..()
	if(reagents.total_volume)
		var/mutable_appearance/M = mutable_appearance(icon, "bucket_overlay")
		M.color = mix_color_from_reagents(reagents.reagent_list)
		.+=M

/obj/item/pestle
	name = "pestle"
	desc = "An ancient, simple tool used in conjunction with a mortar to grind or juice items."
	w_class = WEIGHT_CLASS_SMALL
	icon_state = "pestle"
	force = 7

/obj/item/reagent_containers/glass/mortar
	name = "mortar"
	desc = "A specially formed bowl of ancient design. It is possible to crush or juice items placed in it using a pestle; however the process, unlike modern methods, is slow and physically exhausting. Alt click to eject the item."
	icon_state = "mortar"
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5, 10, 15, 20, 25, 30, 50, 100)
	volume = 100
	reagent_flags = OPENCONTAINER
	spillable = TRUE
	var/obj/item/grinded

/obj/item/reagent_containers/glass/mortar/AltClick(mob/user)
	if(in_range(user, src))
		if(grinded)
			grinded.forceMove(drop_location())
			grinded = null
			to_chat(user, span_notice("You eject the item inside."))

/obj/item/reagent_containers/glass/mortar/attackby(obj/item/I, mob/living/carbon/human/user)
	..()
	if(istype(I,/obj/item/pestle))
		if(grinded)
			if(user.getStaminaLoss() > 50)
				to_chat(user, span_warning("You are too tired to work!"))
				return
			to_chat(user, span_notice("You start grinding..."))
			if((do_after(user, 25, target = src)) && grinded)
				user.adjustStaminaLoss(40)
				if(grinded.juice_results) //prioritize juicing
					grinded.on_juice()
					reagents.add_reagent_list(grinded.juice_results)
					to_chat(user, span_notice("You juice [grinded] into a fine liquid."))
					QDEL_NULL(grinded)
					return
				grinded.on_grind()
				reagents.add_reagent_list(grinded.grind_results)
				if(grinded.reagents) //food and pills
					grinded.reagents.trans_to(src, grinded.reagents.total_volume, transfered_by = user)
				to_chat(user, span_notice("You break [grinded] into powder."))
				QDEL_NULL(grinded)
				return
			return
		else
			to_chat(user, span_warning("There is nothing to grind!"))
			return
	if(grinded)
		to_chat(user, span_warning("There is something inside already!"))
		return
	if(I.juice_results || I.grind_results)
		I.forceMove(src)
		grinded = I
		return
	to_chat(user, span_warning("You can't grind this!"))
