/// Simple, mostly AI-controlled critters, such as pets, bots, and drones.
/mob/living/simple_animal
	name = "animal"
	icon = 'icons/mob/animal.dmi'
	health = 20
	maxHealth = 20
	gender = PLURAL //placeholder
	living_flags = MOVES_ON_ITS_OWN
	status_flags = CANPUSH

	var/icon_living = ""
	///Icon when the animal is dead. Don't use animated icons for this.
	var/icon_dead = ""
	///We only try to show a gibbing animation if this exists.
	var/icon_gib = null
	///Naked animal be like
	var/icon_skinned = null
	///Flip the sprite upside down on death. Mostly here for things lacking custom dead sprites.
	var/flip_on_death = FALSE
	///These will be yielded from butchering in a range specified for each item
	var/list/butcher_results = null
	///What do we get when we skin it
	var/obj/item/stack/sheet/animalhide/hide_type
	///Whether we skinned it
	var/skinned = FALSE
	var/list/speak = list()
	///Emotes while speaking IE: `Ian [emote], [text]` -- `Ian barks, "WOOF!".` Spoken text is generated from the speak variable.
	var/list/speak_emote = list()
	var/speak_chance = 0
	///Hearable emotes
	var/list/emote_hear = list()
	///Unlike speak_emote, the list of things in this variable only show by themselves with no spoken text. IE: Ian barks, Ian yaps
	var/list/emote_see = list()

	var/turns_per_move = 1
	var/turns_since_move = 0
	///Use this to temporarely stop random movement or to if you write special movement code for animals.
	var/stop_automated_movement = 0
	///Does the mob wander around when idle?
	var/wander = 1
	///When set to 1 this stops the animal from moving when someone is pulling it.
	var/stop_automated_movement_when_pulled = 1

	///When someone interacts with the simple animal.
	///Help-intent verb in present continuous tense.
	var/response_help_continuous = "pokes"
	///Help-intent verb in present simple tense.
	var/response_help_simple = "poke"
	///Disarm-intent verb in present continuous tense.
	var/response_disarm_continuous = "pushes"
	///Disarm-intent verb in present simple tense.
	var/response_disarm_simple = "push"
	///Harm-intent verb in present continuous tense.
	var/response_harm_continuous = "hits"
	///Harm-intent verb in present simple tense.
	var/response_harm_simple = "hit"
	var/harm_intent_damage = 3
	///Minimum force required to deal any damage.
	var/force_threshold = 0
	///Maximum amount of stamina damage the mob can be inflicted with total
	var/max_staminaloss = 200
	///How much stamina the mob recovers per second
	var/stamina_recovery = 5

	///Temperature effect.
	var/minbodytemp = 250
	var/maxbodytemp = 350

	///This damage is taken when the body temp is too cold.
	var/unsuitable_cold_damage
	///This damage is taken when the body temp is too hot.
	var/unsuitable_heat_damage

	///Healable by medical stacks? Defaults to yes.
	var/healable = 1

	//Defaults to zero so Ian can still be cuddly. Moved up the tree to living! This allows us to bypass some hardcoded stuff.
	melee_damage_lower = 0
	melee_damage_upper = 0
	///attack type of an animal
	var/atck_type = BLUNT
	///how much damage this simple animal does to objects, if any.
	var/obj_damage = 0
	///How much armour they ignore, as a flat reduction from the targets armour value.
	var/armour_penetration = 0
	///Damage type of a simple mob's melee attack, should it do damage.
	var/melee_damage_type = BRUTE
	///FUCK damaga_coeff; armor is the only way
	var/datum/armor/armor
	///Attacking verb in present continuous tense.
	var/attack_verb_continuous = "attacks"
	///Attacking verb in present simple tense.
	var/attack_verb_simple = "attack"
	var/attack_sound = null
	var/attack_vis_effect
	///Attacking, but without damage, verb in present continuous tense.
	var/friendly_verb_continuous = "pokes"
	///Attacking, but without damage, verb in present simple tense.
	var/friendly_verb_simple = "poke"
	///Set to 1 to allow breaking of crates,lockers,racks,tables; 2 for walls; 3 for Rwalls.
	var/environment_smash = ENVIRONMENT_SMASH_NONE

	///LETS SEE IF I CAN SET SPEEDS FOR SIMPLE MOBS WITHOUT DESTROYING EVERYTHING. Higher speed is slower, negative speed is faster.
	var/speed = 1

	///Hot simple_animal baby making vars.
	var/list/childtype = null
	var/next_scan_time = 0
	///Sorry, no spider+corgi buttbabies.
	var/animal_species

	///In the event that you want to have a buffing effect on the mob, but don't want it to stack with other effects, any outside force that applies a buff to a simple mob should at least set this to 1, so we have something to check against.
	var/buffed = 0
	///If the mob can be spawned with a gold slime core. HOSTILE_SPAWN are spawned with plasma, FRIENDLY_SPAWN are spawned with blood.
	var/gold_core_spawnable = NO_SPAWN

	var/datum/component/spawner/nest

	///Sentience type, for slime potions.
	var/sentience_type = SENTIENCE_ORGANIC

	///List of things spawned at mob's loc when it dies.
	var/list/loot = list()
	///Causes mob to be deleted on death, useful for mobs that spawn lootable corpses.
	var/del_on_death = 0
	var/deathmessage = ""

	var/allow_movement_on_non_turfs = FALSE

	///Played when someone punches the creature.
	var/attacked_sound = "punch"

	///If the creature has, and can use, hands.
	var/dextrous = FALSE
	var/dextrous_hud_type = /datum/hud/dextrous

	///The Status of our AI, can be set to AI_ON (On, usual processing), AI_IDLE (Will not process, but will return to AI_ON if an enemy comes near), AI_OFF (Off, Not processing ever), AI_Z_OFF (Temporarily off due to nonpresence of players).
	var/AIStatus = AI_ON
	///once we have become sentient, we can never go back.
	var/can_have_ai = TRUE

	///convenience var for forcibly waking up an idling AI on next check.
	var/shouldwakeup = FALSE

	///Domestication.
	var/tame = FALSE
	///What the mob eats, typically used for taming or animal husbandry.
	var/list/food_type
	///Starting success chance for taming.
	var/tame_chance
	///Added success chance after every failed tame attempt.
	var/bonus_tame_chance

	///What kind of footstep this mob should have. Null if it shouldn't have any.
	var/footstep_type

	///How much wounding power it has
	var/wound_bonus = CANT_WOUND
	///How much bare wounding power it has
	var/bare_wound_bonus = 0
	///Generic flags
	var/simple_mob_flags = NONE

	/// Used for making mobs show a heart emoji and give a mood boost when pet.
	var/pet_bonus = FALSE
	/// A string for an emote used when pet_bonus == true for the mob being pet.
	var/pet_bonus_emote = ""

	//Discovery
	var/discovery_points = 200
	///Limits how often mobs can hunt other mobs
	COOLDOWN_DECLARE(emote_cooldown)
	var/turns_since_scan = 0

	///Is this animal horrible at hunting?
	var/inept_hunter = FALSE


/mob/living/simple_animal/Initialize(mapload)
	. = ..()
	GLOB.simple_animals[AIStatus] += src
	if (islist(armor))
		armor = getArmor(arglist(armor))
	else if (!armor)
		armor = getArmor()
	if(gender == PLURAL)
		gender = pick(MALE,FEMALE)
	if(!real_name)
		real_name = name
	if(!loc)
		stack_trace("Simple animal being instantiated in nullspace")
	update_simplemob_varspeed()
	if(dextrous)
		// AddComponent(/datum/component/personal_crafting)
		ADD_TRAIT(src, TRAIT_ADVANCEDTOOLUSER, ROUNDSTART_TRAIT)
		ADD_TRAIT(src, TRAIT_CAN_STRIP, ROUNDSTART_TRAIT)

	if(speak)
		speak = string_list(speak)
	if(speak_emote)
		speak_emote = string_list(speak_emote)
	if(emote_hear)
		emote_hear = string_list(emote_hear)
	if(emote_see)
		emote_see = string_list(emote_hear)
	if(footstep_type)
		AddElement(/datum/element/footstep, footstep_type)

/mob/living/simple_animal/Life(delta_time = SSMOBS_DT, times_fired)
	. = ..()
	if(staminaloss > 0)
		adjustStaminaLoss(-stamina_recovery * delta_time, FALSE, TRUE)

/mob/living/simple_animal/Destroy()
	GLOB.simple_animals[AIStatus] -= src
	if (SSnpcpool.state == SS_PAUSED && LAZYLEN(SSnpcpool.currentrun))
		SSnpcpool.currentrun -= src

	if(nest)
		nest.spawned_mobs -= src
		nest = null

	var/turf/T = get_turf(src)
	if (T && AIStatus == AI_Z_OFF)
		SSidlenpcpool.idle_mobs_by_zlevel[T.z] -= src

	return ..()

/mob/living/simple_animal/attackby(obj/item/O, mob/user, params)
	if(!is_type_in_list(O, food_type))
		return ..()

	user.visible_message(span_notice("<b>[user]</b> hand feeds <b>[src]</b> with [O].") , span_notice("You hand feed <b>[src]</b> with [O]."))
	qdel(O)
	if(tame)
		return
	if (prob(tame_chance)) //note: lack of feedback message is deliberate, keep them guessing!
		tame = TRUE
		tamed(user)
	else
		tame_chance += bonus_tame_chance


///Extra effects to add when the mob is tamed, such as adding a riding component
/mob/living/simple_animal/proc/tamed(whomst)
	tame = TRUE

/mob/living/simple_animal/examine(mob/user)
	. = ..()
	if(stat == DEAD)
		. += span_deadsay("Upon closer examination, [p_they()] appear[p_s()] to be dead.")

/mob/living/simple_animal/update_stat()
	if(status_flags & GODMODE)
		return
	if(stat != DEAD)
		if(health <= 0)
			death()
		else
			set_stat(CONSCIOUS)
	med_hud_set_status()

/mob/living/simple_animal/handle_status_effects(delta_time, times_fired)
	..()
	if(stuttering)
		stuttering = 0

/**
 * Updates the simple mob's stamina loss.
 *
 * Updates the speed and staminaloss of a given simplemob.
 * Reduces the stamina loss by stamina_recovery
 */
/mob/living/simple_animal/update_stamina()
	set_varspeed(initial(speed) + (staminaloss * 0.06))

/mob/living/simple_animal/proc/handle_automated_action()
	set waitfor = FALSE
	return

/mob/living/simple_animal/proc/handle_automated_movement()
	set waitfor = FALSE
	if(!stop_automated_movement && wander)
		if((isturf(loc) || allow_movement_on_non_turfs) && (mobility_flags & MOBILITY_MOVE))		//This is so it only moves if it's not inside a closet, gentics machine, etc.
			turns_since_move++
			if(turns_since_move >= turns_per_move)
				if(!(stop_automated_movement_when_pulled && pulledby)) //Some animals don't move when pulled
					var/anydir = pick(GLOB.cardinals)
					Move(get_step(src, anydir), anydir)
					turns_since_move = 0
			return 1

/mob/living/simple_animal/proc/handle_automated_speech(override)
	set waitfor = FALSE
	if(speak_chance)
		if(prob(speak_chance) || override)
			if(speak?.len)
				if((emote_hear?.len) || (emote_see?.len))
					var/length = speak.len
					if(emote_hear?.len)
						length += emote_hear.len
					if(emote_see?.len)
						length += emote_see.len
					var/randomValue = rand(1,length)
					if(randomValue <= speak.len)
						say(sanitize_simple(pick(speak)), forced = "poly")
					else
						randomValue -= speak.len
						if(emote_see && randomValue <= emote_see.len)
							manual_emote(pick(emote_see))
						else
							manual_emote(pick(emote_hear))
				else
					say(sanitize_simple(pick(speak)), forced = "poly")
			else
				if(!(emote_hear?.len) && (emote_see?.len))
					manual_emote(pick(emote_see))
				if((emote_hear?.len) && !(emote_see?.len))
					manual_emote(pick(emote_hear))
				if((emote_hear?.len) && (emote_see?.len))
					var/length = emote_hear.len + emote_see.len
					var/pick = rand(1,length)
					if(pick <= emote_see.len)
						manual_emote(pick(emote_see))
					else
						manual_emote(pick(emote_hear))

/mob/living/simple_animal/gib()
	if(butcher_results)
		var/atom/Tsec = drop_location()
		for(var/path in butcher_results)
			for(var/i in 1 to butcher_results[path][1])//Lowest possible amount
				new path(Tsec)
	..()

/mob/living/simple_animal/gib_animation()
	if(icon_gib)
		new /obj/effect/temp_visual/gib_animation/animal(loc, icon_gib)


/mob/living/simple_animal/say_mod(input, list/message_mods = list())
	if(length(speak_emote))
		verb_say = pick(speak_emote)
	return ..()


/mob/living/simple_animal/emote(act, m_type=1, message = null, intentional = FALSE)
	if(stat)
		return FALSE
	return ..()

/mob/living/simple_animal/proc/set_varspeed(var_value)
	speed = var_value
	update_simplemob_varspeed()

/mob/living/simple_animal/proc/update_simplemob_varspeed()
	if(speed == 0)
		remove_movespeed_modifier(/datum/movespeed_modifier/simplemob_varspeed)
	add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/simplemob_varspeed, multiplicative_slowdown = speed)

/mob/living/simple_animal/get_status_tab_items()
	. = ..()
	. += ""
	. += "Health: [round((health / maxHealth) * 100)]%"

/mob/living/simple_animal/proc/drop_loot()
	if(loot.len)
		for(var/i in loot)
			new i(loc)

/mob/living/simple_animal/death(gibbed)
	if(nest)
		nest.spawned_mobs -= src
		nest = null
	drop_loot()
	if(dextrous)
		drop_all_held_items()
	if(!gibbed)
		if(deathsound || deathmessage || !del_on_death)
			emote("deathgasp")
	if(del_on_death)
		..()
		//Prevent infinite loops if the mob Destroy() is overridden in such
		//a manner as to cause a call to death() again
		del_on_death = FALSE
		qdel(src)
	else
		health = 0
		icon_state = icon_dead
		if(flip_on_death)
			transform = transform.Turn(180)
		set_density(FALSE)
		..()

/mob/living/simple_animal/proc/CanAttack(atom/the_target)
	if(see_invisible < the_target.invisibility)
		return FALSE
	if(ismob(the_target))
		var/mob/M = the_target
		if(M.status_flags & GODMODE)
			return FALSE
	if (isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat != CONSCIOUS)
			return FALSE
	return TRUE

/mob/living/simple_animal/handle_fire(delta_time, times_fired)
	return TRUE

/mob/living/simple_animal/IgniteMob()
	return FALSE

/mob/living/simple_animal/extinguish_mob()
	return

/mob/living/simple_animal/revive(full_heal = FALSE, admin_revive = FALSE)
	. = ..()
	if(!.)
		return
	icon = initial(icon)
	icon_state = icon_living
	set_density(initial(density))

/mob/living/simple_animal/proc/make_babies() // <3 <3 <3
	if(gender != FEMALE || stat || next_scan_time > world.time || !childtype || !animal_species || !SSticker.IsRoundInProgress())
		return
	next_scan_time = world.time + 400
	var/alone = TRUE
	var/mob/living/simple_animal/partner
	var/children = 0
	var/friends = 0
	for(var/mob/M in view(7, src))
		if(M.stat != CONSCIOUS) //Check if it's conscious FIRST.
			continue
		var/is_child = is_type_in_list(M, childtype)
		var/is_same_species = istype(M, animal_species)
		if(is_child) //Check for children SECOND.
			children++
		else if(is_same_species)
			friends++
			if(M.ckey)
				continue
			else if(!is_child && M.gender == MALE && !(M.flags_1 & HOLOGRAM_1)) //Better safe than sorry ;_;
				partner = M

		else if(isliving(M) && !faction_check_mob(M)) //shyness check. we're not shy in front of things that share a faction with us.
			return //we never mate when not alone, so just abort early
	if(alone && partner && (children < 3) && (friends < 8))
		var/childspawn = pickweight(childtype)
		var/turf/target = get_turf(loc)
		if(target)
			return new childspawn(target)

/mob/living/simple_animal/stripPanelUnequip(obj/item/what, mob/who, where)
	if(!canUseTopic(who, BE_CLOSE))
		return
	else
		..()

/mob/living/simple_animal/stripPanelEquip(obj/item/what, mob/who, where)
	if(!canUseTopic(who, BE_CLOSE))
		return
	else
		..()


/mob/living/simple_animal/update_resting()
	if(resting)
		ADD_TRAIT(src, TRAIT_IMMOBILIZED, RESTING_TRAIT)
	else
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, RESTING_TRAIT)
	return ..()


/mob/living/simple_animal/update_transform()
	var/matrix/ntransform = matrix(transform) //aka transform.Copy()
	var/changed = FALSE

	if(resize != RESIZE_DEFAULT_SIZE)
		changed = TRUE
		ntransform.Scale(resize)
		resize = RESIZE_DEFAULT_SIZE

	if(changed)
		animate(src, transform = ntransform, time = 2, easing = EASE_IN|EASE_OUT)

/mob/living/simple_animal/proc/sentience_act() //Called when a simple animal gains sentience via gold slime potion
	toggle_ai(AI_OFF) // To prevent any weirdness.
	can_have_ai = FALSE

/mob/living/simple_animal/update_sight()
	if(!client)
		return
	if(stat == DEAD)
		sight = (SEE_TURFS|SEE_MOBS|SEE_OBJS)
		see_in_dark = 8
		see_invisible = SEE_INVISIBLE_OBSERVER
		return

	see_invisible = initial(see_invisible)
	see_in_dark = initial(see_in_dark)
	sight = initial(sight)

	if(client.eye != src)
		var/atom/A = client.eye
		if(A.update_remote_sight(src)) //returns 1 if we override all other sight updates.
			return
	sync_lighting_plane_alpha()

/mob/living/simple_animal/can_hold_items(obj/item/I)
	return dextrous && ..()

/mob/living/simple_animal/activate_hand(selhand)
	if(!dextrous)
		return ..()
	if(!selhand)
		selhand = (active_hand_index % held_items.len)+1
	if(istext(selhand))
		selhand = lowertext(selhand)
		if(selhand == "right" || selhand == "r")
			selhand = 2
		if(selhand == "left" || selhand == "l")
			selhand = 1
	if(selhand != active_hand_index)
		swap_hand(selhand)
	else
		mode()

/mob/living/simple_animal/swap_hand(hand_index)
	. = ..()
	if(!.)
		return
	if(!dextrous)
		return
	if(!hand_index)
		hand_index = (active_hand_index % held_items.len)+1
	var/oindex = active_hand_index
	active_hand_index = hand_index
	if(hud_used)
		var/atom/movable/screen/inventory/hand/H
		H = hud_used.hand_slots["[hand_index]"]
		if(H)
			H.update_icon()
		H = hud_used.hand_slots["[oindex]"]
		if(H)
			H.update_icon()

/mob/living/simple_animal/put_in_hands(obj/item/I, del_on_fail = FALSE, merge_stacks = TRUE)
	. = ..(I, del_on_fail, merge_stacks)
	update_inv_hands()

/mob/living/simple_animal/update_inv_hands()
	if(client && hud_used && hud_used.hud_version != HUD_STYLE_NOHUD)
		for(var/obj/item/I in held_items)
			var/index = get_held_index_of_item(I)
			I.plane = ABOVE_HUD_PLANE
			I.screen_loc = ui_hand_position(index)
			client.screen |= I

//ANIMAL RIDING

/mob/living/simple_animal/user_buckle_mob(mob/living/M, mob/user, check_loc = TRUE)
	if(user.incapacitated())
		return
	for(var/atom/movable/A in get_turf(src))
		if(A != src && A != M && A.density)
			return

	return ..()

/mob/living/simple_animal/proc/toggle_ai(togglestatus)
	if(!can_have_ai && (togglestatus != AI_OFF))
		return
	if (AIStatus != togglestatus)
		if (togglestatus > 0 && togglestatus < 5)
			if (togglestatus == AI_Z_OFF || AIStatus == AI_Z_OFF)
				var/turf/T = get_turf(src)
				if (AIStatus == AI_Z_OFF)
					SSidlenpcpool.idle_mobs_by_zlevel[T?.z] -= src
				else
					SSidlenpcpool.idle_mobs_by_zlevel[T?.z] += src
			GLOB.simple_animals[AIStatus] -= src
			GLOB.simple_animals[togglestatus] += src
			AIStatus = togglestatus
		else
			stack_trace("Something attempted to set simple animals AI to an invalid state: [togglestatus]")

/mob/living/simple_animal/proc/consider_wakeup()
	if (pulledby || shouldwakeup)
		toggle_ai(AI_ON)

/mob/living/simple_animal/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(!ckey && !stat)//Not unconscious
		if(AIStatus == AI_IDLE)
			toggle_ai(AI_ON)


/mob/living/simple_animal/onTransitZ(old_z, new_z)
	..()
	if (AIStatus == AI_Z_OFF)
		SSidlenpcpool.idle_mobs_by_zlevel[old_z] -= src
		toggle_ai(initial(AIStatus))

///This proc is used for adding the swabbale element to mobs so that they are able to be biopsied and making sure holograpic and butter-based creatures don't yield viable cells samples.
/mob/living/simple_animal/proc/add_cell_sample()
	return

/mob/living/simple_animal/relaymove(mob/living/user, direction)
	if(user.incapacitated())
		return
	return relaydrive(user, direction)

/mob/living/simple_animal/deadchat_plays(mode = ANARCHY_MODE, cooldown = 12 SECONDS)
	. = AddComponent(/datum/component/deadchat_control/cardinal_movement, mode, list(), cooldown, CALLBACK(src, PROC_REF(stop_deadchat_plays)))

	if(. == COMPONENT_INCOMPATIBLE)
		return

	stop_automated_movement = TRUE

/mob/living/simple_animal/proc/stop_deadchat_plays()
	stop_automated_movement = FALSE


//Makes this mob hunt the prey, be it living or an object. Will kill living creatures, and delete objects.
/mob/living/simple_animal/proc/hunt(hunted)
	if(src == hunted) //Make sure it doesn't eat itself. While not likely to ever happen, might as well check just in case.
		return
	stop_automated_movement = FALSE
	if(!isturf(src.loc)) // Are we on a proper turf?
		return
	if(stat || resting || buckled) // Are we concious, upright, and not buckled?
		return
	if(!COOLDOWN_FINISHED(src, emote_cooldown)) // Has the cooldown on this ended?
		return
	if(!Adjacent(hunted))
		stop_automated_movement = TRUE
		walk_to(src,hunted,0,3)
		if(Adjacent(hunted))
			hunt(hunted) // In case it gets next to the target immediately, skip the scan timer and kill it.
		return
	if(isliving(hunted)) // Are we hunting a living mob?
		var/mob/living/prey = hunted
		if(inept_hunter) // Make your hunter inept to have them unable to catch their prey.
			visible_message(span_warning("[src] chases [prey] around, to no avail!"))
			step(prey, pick(GLOB.cardinals))
			COOLDOWN_START(src, emote_cooldown, 1 MINUTES)
			return
		if(!(prey.stat))
			manual_emote("chomps [prey]!")
			prey.death()
			prey = null
			COOLDOWN_START(src, emote_cooldown, 1 MINUTES)
			return
	else // We're hunting an object, and should delete it instead of killing it. Mostly useful for decal bugs like ants or spider webs.
		manual_emote("chomps [hunted]!")
		qdel(hunted)
		hunted = null
		COOLDOWN_START(src, emote_cooldown, 1 MINUTES)
		return
