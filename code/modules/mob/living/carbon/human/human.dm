/mob/living/carbon/human/Initialize()
	add_verb(src, /mob/living/proc/mob_sleep)
	add_verb(src, /mob/living/proc/toggle_resting)

	icon_state = ""		//Remove the inherent human icon that is visible on the map editor. We're rendering ourselves limb by limb, having it still be there results in a bug where the basic human icon appears below as south in all directions and generally looks nasty.

	//initialize limbs first
	create_bodyparts()

	setup_human_dna()

	if(dna.species)
		INVOKE_ASYNC(src, PROC_REF(set_species), dna.species.type)


	//initialise organs
	create_internal_organs() //most of it is done in set_species now, this is only for parent call

	. = ..()

	RegisterSignal(src, COMSIG_COMPONENT_CLEAN_FACE_ACT, PROC_REF(clean_face))
	// AddComponent(/datum/component/personal_crafting)
	AddElement(/datum/element/footstep, FOOTSTEP_MOB_HUMAN, 1, -6)
	AddComponent(/datum/component/bloodysoles/feet)
	AddElement(/datum/element/ridable, /datum/component/riding/creature/human)
	AddElement(/datum/element/strippable, GLOB.strippable_human_items, TYPE_PROC_REF(/mob/living/carbon/human/, should_strip))
	GLOB.human_list += src
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/mob/living/carbon/human/proc/setup_human_dna()
	//initialize dna. for spawned humans; overwritten by other code
	create_dna(src)
	randomize_human(src)
	dna.initialize_dna()

/mob/living/carbon/human/ComponentInitialize()
	. = ..()
	if(!CONFIG_GET(flag/disable_human_mood))
		AddComponent(/datum/component/mood)

/mob/living/carbon/human/Destroy()
	QDEL_LIST(bioware)
	GLOB.human_list -= src
	return ..()

/mob/living/carbon/human/ZImpactDamage(turf/T, levels)
	if(!HAS_TRAIT(src, TRAIT_FREERUNNING) || levels > 1) // falling off one level
		return ..()
	visible_message(span_danger("[src] makes a hard landing on [T] but remains unharmed from the fall."), \
						span_userdanger("You brace for the fall. You make a hard landing on [T] but remain unharmed."))
	Knockdown(levels * 50)

/mob/living/carbon/human/prepare_data_huds()
	//Update med hud images...
	..()
	//...and display them.
	add_to_all_human_data_huds()

/mob/living/carbon/human/get_status_tab_items()
	. = ..()
	. += "Intent: [a_intent]"
	. += "Mode: [m_intent]"

// called when something steps onto a human
/mob/living/carbon/human/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	spreadFire(AM)

/mob/living/carbon/human/proc/canUseHUD()
	return (mobility_flags & MOBILITY_USE)

/mob/living/carbon/human/can_inject(mob/user, target_zone, injection_flags)
	. = TRUE // Default to returning true.
	if(user && !target_zone)
		target_zone = user.zone_selected
	// we may choose to ignore species trait pierce immunity in case we still want to check skellies for thick clothing without insta failing them (wounds)
	if(injection_flags & INJECT_CHECK_IGNORE_SPECIES)
		if(HAS_TRAIT_NOT_FROM(src, TRAIT_PIERCEIMMUNE, SPECIES_TRAIT))
			. = FALSE
	else if(HAS_TRAIT(src, TRAIT_PIERCEIMMUNE))
		. = FALSE
	var/obj/item/bodypart/the_part = get_bodypart(target_zone) || get_bodypart(BODY_ZONE_CHEST)
	// Loop through the clothing covering this bodypart and see if there's any thiccmaterials
	if(!(injection_flags & INJECT_CHECK_PENETRATE_THICK))
		for(var/obj/item/clothing/iter_clothing in clothingonpart(the_part))
			if(iter_clothing.clothing_flags & THICKMATERIAL)
				. = FALSE
				break

/mob/living/carbon/human/try_inject(mob/user, target_zone, injection_flags)
	. = ..()
	if(!. && (injection_flags & INJECT_TRY_SHOW_ERROR_MESSAGE) && user)
		var/obj/item/bodypart/the_part = get_bodypart(target_zone) || get_bodypart(BODY_ZONE_CHEST)

		to_chat(user, span_alert("There is no exposed flesh or thin material on [p_their()] [the_part.name]."))


//Used for new human mobs created by cloning/goleming/podding
/mob/living/carbon/human/proc/set_cloned_appearance()
	if(gender == MALE)
		facial_hairstyle = "Full Beard"
	else
		facial_hairstyle = "Shaved"
	hairstyle = pick("Bedhead", "Bedhead 2", "Bedhead 3")
	underwear = "Nude"
	update_body()
	update_hair()

#define CPR_PANIC_SPEED (0.8 SECONDS)

/// Performs CPR on the target after a delay.
/mob/living/carbon/human/proc/do_cpr(mob/living/carbon/target)
	if(target == src)
		return

	var/panicking = FALSE

	do
		CHECK_DNA_AND_SPECIES(target)

		if (DOING_INTERACTION_WITH_TARGET(src,target))
			return FALSE

		if (target.stat == DEAD || HAS_TRAIT(target, TRAIT_FAKEDEATH))
			to_chat(src, span_warning("[target.name] is dead!"))
			return FALSE

		if (is_mouth_covered())
			to_chat(src, span_warning("Remove your mask first!"))
			return FALSE

		if (target.is_mouth_covered())
			to_chat(src, span_warning("Remove [p_their()] mask first!"))
			return FALSE

		if (!getorganslot(ORGAN_SLOT_LUNGS))
			to_chat(src, span_warning("You have no lungs to breathe with, so you cannot perform CPR!"))
			return FALSE

		if (HAS_TRAIT(src, TRAIT_NOBREATH))
			to_chat(src, span_warning("You do not breathe, so you cannot perform CPR!"))
			return FALSE

		visible_message(span_notice("[src] is trying to perform CPR on [target.name]!"), \
						span_notice("You try to perform CPR on [target.name]... Hold still!"))

		if (!do_mob(src, target, time = panicking ? CPR_PANIC_SPEED : (3 SECONDS)))
			to_chat(src, span_warning("You fail to perform CPR on [target]!"))
			return FALSE

		if (target.health > target.crit_threshold)
			return FALSE

		visible_message(span_notice("[src] performs CPR on [target.name]!"), span_notice("You perform CPR on [target.name]."))
		SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "saved_life", /datum/mood_event/saved_life)
		log_combat(src, target, "CPRed")

		if (HAS_TRAIT(target, TRAIT_NOBREATH))
			to_chat(target, span_unconscious("You feel a breath of fresh air... which is a sensation you don't recognise..."))
		else if (!target.getorganslot(ORGAN_SLOT_LUNGS))
			to_chat(target, span_unconscious("You feel a breath of fresh air... but you don't feel any better..."))
		else
			target.adjustOxyLoss(-min(target.getOxyLoss(), 7))
			to_chat(target, span_unconscious("You feel a breath of fresh air enter your lungs... It feels good..."))

		if (target.health <= target.crit_threshold)
			if (!panicking)
				to_chat(src, span_warning("[target] still isn't up! You try harder!"))
			panicking = TRUE
		else
			panicking = FALSE
	while (panicking)

#undef CPR_PANIC_SPEED

/mob/living/carbon/human/cuff_resist(obj/item/I)
	if(..())
		dropItemToGround(I)

/**
 * Wash the hands, cleaning either the gloves if equipped and not obscured, otherwise the hands themselves if they're not obscured.
 *
 * Returns false if we couldn't wash our hands due to them being obscured, otherwise true
 */
/mob/living/carbon/human/proc/wash_hands(clean_types)
	var/obscured = check_obscured_slots()
	if(obscured & ITEM_SLOT_GLOVES)
		return FALSE

	if(gloves)
		if(gloves.wash(clean_types))
			update_inv_gloves()
	else if((clean_types & CLEAN_TYPE_BLOOD) && blood_in_hands > 0)
		blood_in_hands = 0
		update_inv_gloves()

	return TRUE

/**
 * Cleans the lips of any lipstick. Returns TRUE if the lips had any lipstick and was thus cleaned
 */
/mob/living/carbon/human/proc/clean_lips()
	if(isnull(lip_style) && lip_color == initial(lip_color))
		return FALSE
	lip_style = null
	lip_color = initial(lip_color)
	update_body()
	return TRUE

/**
 * Called on the COMSIG_COMPONENT_CLEAN_FACE_ACT signal
 */
/mob/living/carbon/human/proc/clean_face(datum/source, clean_types)
	if(!is_mouth_covered() && clean_lips())
		. = TRUE

	if(glasses && is_eyes_covered(FALSE, TRUE, TRUE) && glasses.wash(clean_types))
		update_inv_glasses()
		. = TRUE

	var/obscured = check_obscured_slots()
	if(wear_mask && !(obscured & ITEM_SLOT_MASK) && wear_mask.wash(clean_types))
		update_inv_wear_mask()
		. = TRUE

/**
 * Called when this human should be washed
 */
/mob/living/carbon/human/wash(clean_types)
	. = ..()

	// Wash equipped stuff that cannot be covered
	if(wear_suit?.wash(clean_types))
		update_inv_wear_suit()
		. = TRUE

	if(belt?.wash(clean_types))
		update_inv_belt()
		. = TRUE

	// Check and wash stuff that can be covered
	var/obscured = check_obscured_slots()

	if(w_uniform && !(obscured & ITEM_SLOT_ICLOTHING) && w_uniform.wash(clean_types))
		update_inv_w_uniform()
		. = TRUE

	if(!is_mouth_covered() && clean_lips())
		. = TRUE

	// Wash hands if exposed
	if(!gloves && (clean_types & CLEAN_TYPE_BLOOD) && blood_in_hands > 0 && !(obscured & ITEM_SLOT_GLOVES))
		blood_in_hands = 0
		update_inv_gloves()
		. = TRUE

//Turns a mob black, flashes a skeleton overlay
//Just like a cartoon!
/mob/living/carbon/human/proc/electrocution_animation(anim_duration)
	//Handle mutant parts if possible
	if(dna?.species)
		add_atom_colour("#000000", TEMPORARY_COLOUR_PRIORITY)
		var/static/mutable_appearance/electrocution_skeleton_anim
		if(!electrocution_skeleton_anim)
			electrocution_skeleton_anim = mutable_appearance(icon, "electrocuted_base")
			electrocution_skeleton_anim.appearance_flags |= RESET_COLOR|KEEP_APART
		add_overlay(electrocution_skeleton_anim)
		addtimer(CALLBACK(src, PROC_REF(end_electrocution_animation), electrocution_skeleton_anim), anim_duration)

	else //or just do a generic animation
		flick_overlay_view(image(icon,src,"electrocuted_generic",ABOVE_MOB_LAYER), src, anim_duration)

/mob/living/carbon/human/proc/end_electrocution_animation(mutable_appearance/MA)
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#000000")
	cut_overlay(MA)

/mob/living/carbon/human/resist_restraints()
	if(wear_suit?.breakoutchance)
		changeNext_move(CLICK_CD_BREAKOUT)
		last_special = world.time + CLICK_CD_BREAKOUT
		cuff_resist(wear_suit)
	else
		..()

/mob/living/carbon/human/clear_cuffs(obj/item/I, cuff_break)
	. = ..()
	if(.)
		return
	if(!I.loc || buckled)
		return FALSE
	if(I == wear_suit)
		visible_message(span_danger("[capitalize(src.name)] manages to [cuff_break ? "break" : "remove"] [I]!"))
		to_chat(src, span_notice("You successfully [cuff_break ? "break" : "remove"] [I]."))
		return TRUE

/mob/living/carbon/human/get_total_tint()
	. = ..()
	if(glasses)
		. += glasses.tint

/mob/living/carbon/human/update_health_hud()
	if(!client || !hud_used)
		return
	if(dna.species.update_health_hud())
		return
	else
		if(hud_used.healths)
			if(..()) //not dead
				switch(hal_screwyhud)
					if(SCREWYHUD_CRIT)
						hud_used.healths.icon_state = "health6"
					if(SCREWYHUD_DEAD)
						hud_used.healths.icon_state = "health7"
					if(SCREWYHUD_HEALTHY)
						hud_used.healths.icon_state = "health0"
		if(hud_used.healthdoll)
			hud_used.healthdoll.cut_overlays()
			if(stat != DEAD)
				hud_used.healthdoll.icon_state = "healthdoll_OVERLAY"
				for(var/obj/item/bodypart/body_part as anything in bodyparts)
					var/icon_num = 0
					//Hallucinations
					if(body_part.type in hal_screwydoll)
						icon_num = hal_screwydoll[body_part.type]
						hud_used.healthdoll.add_overlay(mutable_appearance('icons/hud/screen_gen.dmi', "[body_part.body_zone][icon_num]"))
						continue
					//Not hallucinating
					var/damage = body_part.burn_dam + body_part.brute_dam
					var/comparison = (body_part.max_damage/5)
					if(damage)
						icon_num = 1
					if(damage > (comparison))
						icon_num = 2
					if(damage > (comparison*2))
						icon_num = 3
					if(damage > (comparison*3))
						icon_num = 4
					if(damage > (comparison*4))
						icon_num = 5
					if(hal_screwyhud == SCREWYHUD_HEALTHY)
						icon_num = 0
					if(icon_num)
						hud_used.healthdoll.add_overlay(mutable_appearance('icons/hud/screen_gen.dmi', "[body_part.body_zone][icon_num]"))
				for(var/t in get_missing_limbs()) //Missing limbs
					hud_used.healthdoll.add_overlay(mutable_appearance('icons/hud/screen_gen.dmi', "[t]6"))
				for(var/t in get_disabled_limbs()) //Disabled limbs
					hud_used.healthdoll.add_overlay(mutable_appearance('icons/hud/screen_gen.dmi', "[t]7"))
			else
				hud_used.healthdoll.icon_state = "healthdoll_DEAD"

/mob/living/carbon/human/fully_heal(admin_revive = FALSE)
	dna?.species.spec_fully_heal(src)
	if(admin_revive)
		regenerate_limbs()
		regenerate_organs()
	remove_all_embedded_objects()
	set_heartattack(FALSE)
	drunkenness = 0
	coretemperature = get_body_temp_normal(apply_change=FALSE)
	heat_exposure_stacks = 0
	return ..()

/mob/living/carbon/human/is_literate()
	return TRUE

/mob/living/carbon/human/vomit(lost_nutrition = 10, blood = FALSE, stun = TRUE, distance = 1, message = TRUE, vomit_type = VOMIT_TOXIC, harm = TRUE, force = FALSE, purge_ratio = 0.1)
	if(blood && (NOBLOOD in dna.species.species_traits) && !HAS_TRAIT(src, TRAIT_TOXINLOVER))
		if(message)
			visible_message(span_warning("[src] dry heaves!"), \
							span_userdanger("You try to throw up, but there's nothing in your stomach!"))
		if(stun)
			Paralyze(200)
		return 1
	..()

/mob/living/carbon/human/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "---------")
	VV_DROPDOWN_OPTION(VV_HK_COPY_OUTFIT, "Copy Outfit")
	VV_DROPDOWN_OPTION(VV_HK_MOD_MUTATIONS, "Add/Remove Mutation")
	VV_DROPDOWN_OPTION(VV_HK_MOD_QUIRKS, "Add/Remove Quirks")
	VV_DROPDOWN_OPTION(VV_HK_MAKE_MONKEY, "Make Monkey")
	VV_DROPDOWN_OPTION(VV_HK_MAKE_CYBORG, "Make Cyborg")
	VV_DROPDOWN_OPTION(VV_HK_MAKE_SLIME, "Make Slime")
	VV_DROPDOWN_OPTION(VV_HK_MAKE_ALIEN, "Make Alien")
	VV_DROPDOWN_OPTION(VV_HK_SET_SPECIES, "Set Species")
	VV_DROPDOWN_OPTION(VV_HK_PURRBATION, "Toggle Purrbation")

/mob/living/carbon/human/vv_do_topic(list/href_list)
	. = ..()
	if(href_list[VV_HK_COPY_OUTFIT])
		if(!check_rights(R_SPAWN))
			return
		copy_outfit()
	if(href_list[VV_HK_MAKE_MONKEY])
		if(!check_rights(R_SPAWN))
			return
		if(tgui_alert(usr,"Confirm mob type change?",,list("Transform","Cancel")) != "Transform")
			return
		usr.client.holder.Topic("vv_override", list("monkeyone"=href_list[VV_HK_TARGET]))
	if(href_list[VV_HK_MAKE_CYBORG])
		if(!check_rights(R_SPAWN))
			return
		if(tgui_alert(usr,"Confirm mob type change?",,list("Transform","Cancel")) != "Transform")
			return
		usr.client.holder.Topic("vv_override", list("makerobot"=href_list[VV_HK_TARGET]))
	if(href_list[VV_HK_MAKE_ALIEN])
		if(!check_rights(R_SPAWN))
			return
		if(tgui_alert(usr,"Confirm mob type change?",,list("Transform","Cancel")) != "Transform")
			return
		usr.client.holder.Topic("vv_override", list("makealien"=href_list[VV_HK_TARGET]))
	if(href_list[VV_HK_MAKE_SLIME])
		if(!check_rights(R_SPAWN))
			return
		if(tgui_alert(usr,"Confirm mob type change?",,list("Transform","Cancel")) != "Transform")
			return
		usr.client.holder.Topic("vv_override", list("makeslime"=href_list[VV_HK_TARGET]))
	if(href_list[VV_HK_SET_SPECIES])
		if(!check_rights(R_SPAWN))
			return

		var/result = input(usr, "Please choose a new species","Species") as null|anything in GLOB.species_list
		if(result)
			var/newtype = GLOB.species_list[result]
			admin_ticket_log("[key_name_admin(usr)] has modified the bodyparts of [src] to [result]")
			set_species(newtype)

/mob/living/carbon/human/limb_attack_self()
	var/obj/item/bodypart/arm = hand_bodyparts[active_hand_index]
	if(arm)
		arm.attack_self(src)
	return ..()

/mob/living/carbon/human/mouse_buckle_handling(mob/living/M, mob/living/user)
	if(pulling != M || grab_state != GRAB_AGGRESSIVE || stat != CONSCIOUS || a_intent != INTENT_GRAB)
		return FALSE

	//If they dragged themselves to you and you're currently aggressively grabbing them try to piggyback
	if(user == M && can_piggyback(M))
		piggyback(M)
		return TRUE

	//If you dragged them to you and you're aggressively grabbing try to fireman carry them
	if(can_be_firemanned(M))
		fireman_carry(M)
		return TRUE

//src is the user that will be carrying, target is the mob to be carried
/mob/living/carbon/human/proc/can_piggyback(mob/living/carbon/target)
	return (istype(target) && target.stat == CONSCIOUS)

/mob/living/carbon/human/proc/can_be_firemanned(mob/living/carbon/target)
	return ishuman(target) && target.body_position == LYING_DOWN

/mob/living/carbon/human/proc/fireman_carry(mob/living/carbon/target)
	if(!can_be_firemanned(target) || incapacitated(FALSE, TRUE))
		to_chat(src, span_warning("You can't fireman carry [target] while [target.p_they()] [target.p_are()] standing!"))
		return

	var/carrydelay = 5 SECONDS //if you have latex you are faster at grabbing
	var/skills_space = "" //cobby told me to do this
	if(HAS_TRAIT(src, TRAIT_QUICKER_CARRY))
		carrydelay = 3 SECONDS
		skills_space = " very quickly"
	else if(HAS_TRAIT(src, TRAIT_QUICK_CARRY))
		carrydelay = 4 SECONDS
		skills_space = " quickly"

	visible_message(span_notice("[src] starts[skills_space] lifting [target] onto [p_their()] back..."),
		span_notice("You[skills_space] start to lift [target] onto your back..."))//(Using your gloves' nanochips, you/You) ( /quickly/expertly) start to lift Grey Tider onto your back(, while assisted by the nanochips in your gloves../...)
	if(!do_after(src, carrydelay, target))
		visible_message(span_warning("[src] fails to fireman carry [target]!"))
		return

	//Second check to make sure they're still valid to be carried
	if(!can_be_firemanned(target) || incapacitated(FALSE, TRUE) || target.buckled)
		visible_message(span_warning("[src] fails to fireman carry [target]!"))
		return

	if(target.loc != loc)
		var/old_density = density
		density = FALSE // Hacky and doesn't use set_density()
		step_towards(target, loc)
		density = old_density // Avoid changing density directly in normal circumstances, without the setter.

	if(target.loc == loc)
		return buckle_mob(target, TRUE, TRUE, CARRIER_NEEDS_ARM)

/mob/living/carbon/human/proc/piggyback(mob/living/carbon/target)
	if(!can_piggyback(target))
		to_chat(target, span_warning("You can't piggyback ride [src] right now!"))
		return

	visible_message(span_notice("[target] starts to climb onto [src]..."))
	if(!do_after(target, 1.5 SECONDS, target = src) || !can_piggyback(target))
		visible_message(span_warning("[target] fails to climb onto [src]!"))
		return

	if(target.incapacitated(FALSE, TRUE) || incapacitated(FALSE, TRUE))
		target.visible_message(span_warning("[target] can't hang onto [src]!"))
		return

	return buckle_mob(target, TRUE, TRUE, RIDER_NEEDS_ARMS)

/mob/living/carbon/human/buckle_mob(mob/living/target, force = FALSE, check_loc = TRUE, buckle_mob_flags= NONE)
	if(!is_type_in_typecache(target, can_ride_typecache))
		target.visible_message(span_warning("[target] really can't seem to mount [src]..."))
		return

	if(!force)//humans are only meant to be ridden through piggybacking and special cases
		return

	return ..()

/mob/living/carbon/human/updatehealth()
	. = ..()
	dna?.species.spec_updatehealth(src)
	if(HAS_TRAIT(src, TRAIT_IGNOREDAMAGESLOWDOWN))
		remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown)
		remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown_flying)
		return
	var/health_deficiency = max((maxHealth - health), staminaloss)
	if(health_deficiency >= 40)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown, TRUE, multiplicative_slowdown = health_deficiency / 75)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown_flying, TRUE, multiplicative_slowdown = health_deficiency / 25)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown)
		remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown_flying)

/mob/living/carbon/human/adjust_nutrition(change) //Honestly FUCK the oldcoders for putting nutrition on /mob someone else can move it up because holy hell I'd have to fix SO many typechecks
	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		return FALSE
	if((NOBLOOD in dna.species.species_traits))
		nutrition = NUTRITION_LEVEL_START_MAX
		return FALSE
	return ..()

/mob/living/carbon/human/set_nutrition(change) //Seriously fuck you oldcoders.
	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		return FALSE
	return ..()

/mob/living/carbon/human/is_bleeding()
	if(NOBLOOD in dna.species.species_traits)
		return FALSE
	return ..()

/mob/living/carbon/human/get_total_bleed_rate()
	if(NOBLOOD in dna.species.species_traits)
		return FALSE
	return ..()

/mob/living/carbon/human/monkeybrain
	ai_controller = /datum/ai_controller/monkey

/mob/living/carbon/human/species
	var/race = null
	var/use_random_name = TRUE

/mob/living/carbon/human/species/Initialize()
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(set_species), race)

/mob/living/carbon/human/species/set_species(datum/species/mrace, icon_update, pref_load)
	. = ..()
	if(use_random_name)
		fully_replace_character_name(real_name, dna.species.random_name())

/mob/living/carbon/human/species/dwarf
	race = /datum/species/dwarf

/mob/living/carbon/human/species/goblin
	race = /datum/species/goblin
