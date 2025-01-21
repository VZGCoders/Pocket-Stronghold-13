/mob/living/carbon/Life(delta_time = SSMOBS_DT, times_fired)

	if(notransform)
		return

	if(damageoverlaytemp)
		damageoverlaytemp = 0
		update_damage_hud()

	//Reagent processing needs to come before breathing, to prevent edge cases.
	handle_organs(delta_time, times_fired)

	. = ..()
	if(QDELETED(src))
		return

	if(.) //not dead
		handle_blood(delta_time, times_fired)
		handle_hydration(delta_time, times_fired)

	if(stat == DEAD)
		stop_sound_channel(CHANNEL_HEARTBEAT)
	else
		var/bprv = handle_bodyparts(delta_time, times_fired)
		if(bprv & BODYPART_LIFE_UPDATE_HEALTH)
			update_stamina() //needs to go before updatehealth to remove stamcrit
			updatehealth()

	check_cremation(delta_time, times_fired)

	if(. && mind) //. == not dead
		for(var/key in mind.addiction_points)
			var/datum/addiction/addiction = SSaddiction.all_addictions[key]
			addiction.process_addiction(src, delta_time, times_fired)
	if(stat != DEAD)
		return 1

///////////////
// BREATHING //
///////////////

//Start of a breath chain, calls breathe()
/mob/living/carbon/handle_breathing(delta_time, times_fired)
	var/next_breath = 4
	var/obj/item/organ/lungs/L = getorganslot(ORGAN_SLOT_LUNGS)
	var/obj/item/organ/heart/H = getorganslot(ORGAN_SLOT_HEART)
	if(L)
		if(L.damage > L.high_threshold)
			next_breath--
	if(H)
		if(H.damage > H.high_threshold)
			next_breath--

	if((times_fired % next_breath) == 0 || failed_last_breath)
		breathe(delta_time, times_fired) //Breathe per 4 ticks if healthy, down to 2 if our lungs or heart are damaged, unless suffocating
		if(failed_last_breath)
			SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "suffocation", /datum/mood_event/suffocation)
		else
			SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "suffocation")
	else
		if(istype(loc, /obj/))
			var/obj/location_as_object = loc
			location_as_object.handle_internal_lifeform(src,0)

/mob/living/carbon/proc/breathe(delta_time, times_fired)
	var/obj/item/organ/lungs = getorganslot(ORGAN_SLOT_LUNGS)

	if(!getorganslot(ORGAN_SLOT_BREATHING_TUBE))
		if(health <= HEALTH_THRESHOLD_FULLCRIT || (pulledby && pulledby.grab_state >= GRAB_KILL) || HAS_TRAIT(src, TRAIT_MAGIC_CHOKE) || (lungs && lungs.organ_flags & ORGAN_FAILING))
			losebreath++  //You can't breath at all when in critical or when being choked, so you're going to miss a breath

		else if(health <= crit_threshold)
			losebreath += 0.25 //You're having trouble breathing in soft crit, so you'll miss a breath one in four times

	//Suffocate
	if(losebreath >= 1) //You've missed a breath, take oxy damage
		losebreath--
		if(prob(10))
			INVOKE_ASYNC(src, PROC_REF(emote), "gasp")

/mob/living/carbon/proc/has_smoke_protection()
	if(HAS_TRAIT(src, TRAIT_NOBREATH))
		return TRUE
	return FALSE

/mob/living/carbon/proc/handle_blood(delta_time, times_fired)
	return

/mob/living/carbon/proc/handle_hydration(delta_time, times_fired)
	return

/mob/living/carbon/human/handle_hydration(delta_time, times_fired)
	if(IsSleeping())
		return
	if((NOBLOOD in dna.species.species_traits) || HAS_TRAIT(src, TRAIT_NOBLEED) || (HAS_TRAIT(src, TRAIT_FAKEDEATH)))
		hydration = HYDRATION_LEVEL_START_MIN
		return
	hydration = max(hydration-HYDRATION_LOSS_PER_SECOND*delta_time, 0)

// /mob/living/carbon/human/handle_hydration(delta_time, times_fired)
// 	if(IsSleeping())
// 		return
// 	nutrition = max(nutrition-NUTRITION_LOSS_PER_SECOND*delta_time, 0)

/mob/living/carbon/proc/handle_bodyparts(delta_time, times_fired)
	var/stam_regen = FALSE
	if(stam_regen_start_time <= world.time)
		stam_regen = TRUE
		if(HAS_TRAIT_FROM(src, TRAIT_INCAPACITATED, STAMINA))
			. |= BODYPART_LIFE_UPDATE_HEALTH //make sure we remove the stamcrit
	for(var/I in bodyparts)
		var/obj/item/bodypart/BP = I
		if(BP.needs_processing)
			. |= BP.on_life(delta_time, times_fired, stam_regen)

/mob/living/carbon/proc/handle_organs(delta_time, times_fired)
	if(stat != DEAD)
		for(var/organ_slot in GLOB.organ_process_order)
			var/obj/item/organ/organ = getorganslot(organ_slot)
			if(organ?.owner) // This exist mostly because reagent metabolization can cause organ reshuffling
				organ.on_life(delta_time, times_fired)
	else
		for(var/V in internal_organs)
			var/obj/item/organ/O = V
			O.on_death(delta_time, times_fired) //Needed so organs decay while inside the body.

/*
Alcohol Poisoning Chart
Note that all higher effects of alcohol poisoning will inherit effects for smaller amounts (i.e. light poisoning inherts from slight poisoning)
In addition, severe effects won't always trigger unless the drink is poisonously strong
All effects don't start immediately, but rather get worse over time; the rate is affected by the imbiber's alcohol tolerance

0: Non-alcoholic
1-10: Barely classifiable as alcohol - occassional slurring
11-20: Slight alcohol content - slurring
21-30: Below average - imbiber begins to look slightly drunk
31-40: Just below average - no unique effects
41-50: Average - mild disorientation, imbiber begins to look drunk
51-60: Just above average - disorientation, vomiting, imbiber begins to look heavily drunk
61-70: Above average - small chance of blurry vision, imbiber begins to look smashed
71-80: High alcohol content - blurry vision, imbiber completely shitfaced
81-90: Extremely high alcohol content - light brain damage, passing out
91-100: Dangerously toxic - swift death
*/
#define BALLMER_POINTS 5

//this updates all special effects: stun, sleeping, knockdown, druggy, stuttering, etc..
/mob/living/carbon/handle_status_effects(delta_time, times_fired)
	..()

	var/restingpwr = 0.5 + 2 * resting

	//Dizziness
	if(dizziness)
		var/client/C = client
		var/pixel_x_diff = 0
		var/pixel_y_diff = 0
		var/temp
		var/saved_dizz = dizziness
		if(C)
			var/oldsrc = src
			var/amplitude = dizziness*(sin(dizziness * world.time) + 1) // This shit is annoying at high strength
			src = null
			spawn(0) // AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
				if(C)
					temp = amplitude * sin(saved_dizz * world.time)
					pixel_x_diff += temp
					C.pixel_x += temp
					temp = amplitude * cos(saved_dizz * world.time)
					pixel_y_diff += temp
					C.pixel_y += temp
					sleep(3)
					if(C)
						temp = amplitude * sin(saved_dizz * world.time)
						pixel_x_diff += temp
						C.pixel_x += temp
						temp = amplitude * cos(saved_dizz * world.time)
						pixel_y_diff += temp
						C.pixel_y += temp
					sleep(3)
					if(C)
						C.pixel_x -= pixel_x_diff
						C.pixel_y -= pixel_y_diff
			src = oldsrc
		dizziness = max(dizziness - (restingpwr * delta_time), 0)

	if(drowsyness)
		drowsyness = max(drowsyness - (restingpwr * delta_time), 0)
		blur_eyes(1 * delta_time)
		if(DT_PROB(2.5, delta_time))
			AdjustSleeping(100)

	//Jitteriness
	if(jitteriness)
		do_jitter_animation(jitteriness)
		jitteriness = max(jitteriness - (restingpwr * delta_time), 0)
		SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "jittery", /datum/mood_event/jittery)
	else
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "jittery")

	if(stuttering)
		stuttering = max(stuttering - (0.5 * delta_time), 0)

	if(slurring)
		slurring = max(slurring - (0.5 * delta_time),0)

	if(cultslurring)
		cultslurring = max(cultslurring - (0.5 * delta_time), 0)

	if(silent)
		silent = max(silent - (0.5 * delta_time), 0)

	if(druggy)
		adjust_drugginess(-0.5 * delta_time)

	if(hallucination)
		handle_hallucinations(delta_time, times_fired)

	if(drunkenness)
		drunkenness = max(drunkenness - ((0.005 + (drunkenness * 0.02)) * delta_time), 0)
		if(drunkenness >= 6)
			SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "drunk", /datum/mood_event/drunk)
			if(DT_PROB(16, delta_time))
				slurring += 2
			jitteriness = max(jitteriness - (1.5 * delta_time), 0)
			throw_alert("drunk", /atom/movable/screen/alert/drunk)
			sound_environment_override = SOUND_ENVIRONMENT_PSYCHOTIC
		else
			SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "drunk")
			clear_alert("drunk")
			sound_environment_override = SOUND_ENVIRONMENT_NONE

		if(drunkenness >= 11 && slurring < 5)
			slurring += 0.6 * delta_time

		if(drunkenness >= 41)
			if(DT_PROB(16, delta_time))
				add_confusion(2)
			Dizzy(5 * delta_time)

		if(drunkenness >= 51)
			if(DT_PROB(1.5, delta_time))
				add_confusion(15)
				vomit() // vomiting clears toxloss, consider this a blessing
			Dizzy(12.5 * delta_time)

		if(drunkenness >= 61)
			if(DT_PROB(30, delta_time))
				blur_eyes(5)

		if(drunkenness >= 71)
			blur_eyes(2.5 * delta_time)

		if(drunkenness >= 81)
			adjustToxLoss(0.5 * delta_time)
			if(!stat && DT_PROB(2.5, delta_time))
				to_chat(src, span_warning("Just a quick nap..."))

		if(drunkenness >= 91)
			adjustToxLoss(0.5 * delta_time)
			adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.2 * delta_time)

		if(drunkenness >= 101)
			adjustToxLoss(1 * delta_time) //Let's be honest you shouldn't be alive by now

/**
 * Get the insulation that is appropriate to the temperature you're being exposed to.
 * All clothing, natural insulation, and traits are combined returning a single value.
 *
 * required temperature The Temperature that you're being exposed to
 *
 * return the percentage of protection as a value from 0 - 1
**/
/mob/living/carbon/proc/get_insulation_protection(temperature)
	return (temperature > bodytemperature) ? get_heat_protection(temperature) : get_cold_protection(temperature)

/// This returns the percentage of protection from heat as a value from 0 - 1
/// temperature is the temperature you're being exposed to
/mob/living/carbon/proc/get_heat_protection(temperature)
	return heat_protection

/// This returns the percentage of protection from cold as a value from 0 - 1
/// temperature is the temperature you're being exposed to
/mob/living/carbon/proc/get_cold_protection(temperature)
	return cold_protection

/**
 * Have two mobs share body heat between each other.
 * Account for the insulation and max temperature change range for the mob
 *
 * vars:
 * * M The mob/living/carbon that is sharing body heat
 */
/mob/living/carbon/proc/share_bodytemperature(mob/living/carbon/M)
	var/temp_diff = bodytemperature - M.bodytemperature
	if(temp_diff > 0) // you are warm share the heat of life
		M.adjust_bodytemperature((temp_diff * 0.5), use_insulation=TRUE, use_steps=TRUE) // warm up the giver
		adjust_bodytemperature((temp_diff * -0.5), use_insulation=TRUE, use_steps=TRUE) // cool down the reciver

	else // they are warmer leech from them
		adjust_bodytemperature((temp_diff * -0.5) , use_insulation=TRUE, use_steps=TRUE) // warm up the reciver
		M.adjust_bodytemperature((temp_diff * 0.5), use_insulation=TRUE, use_steps=TRUE) // cool down the giver

/**
 * Adjust the body temperature of a mob
 * expanded for carbon mobs allowing the use of insulation and change steps
 *
 * vars:
 * * amount The amount of degrees to change body temperature by
 * * min_temp (optional) The minimum body temperature after adjustment
 * * max_temp (optional) The maximum body temperature after adjustment
 * * use_insulation (optional) modifies the amount based on the amount of insulation the mob has
 * * use_steps (optional) Use the body temp divisors and max change rates
 * * capped (optional) default True used to cap step mode
 */
/mob/living/carbon/adjust_bodytemperature(amount, min_temp=0, max_temp=INFINITY, use_insulation=FALSE, use_steps=FALSE, capped=TRUE)
	// apply insulation to the amount of change
	if(use_insulation)
		amount *= (1 - get_insulation_protection(bodytemperature + amount))

	// Use the bodytemp divisors to get the change step, with max step size
	if(use_steps)
		amount = (amount > 0) ? (amount / 15) : (amount / 15)
		// Clamp the results to the min and max step size
		if(capped)
			amount = (amount > 0) ? min(amount, 30) : max(amount, -30)

	if(bodytemperature >= min_temp && bodytemperature <= max_temp)
		bodytemperature = clamp(bodytemperature + amount, min_temp, max_temp)

		// TODO: remove that, add real temperature damage scalling, TEMPORARY SOLUTION
		if(bodytemperature >= temperature_resistance)
			apply_damage( 5, BURN, spread_damage = TRUE)
			bodytemperature = temperature_resistance




///////////
//Stomach//
///////////

/mob/living/carbon/get_fullness()
	var/fullness = nutrition

	var/obj/item/organ/stomach/belly = getorganslot(ORGAN_SLOT_STOMACH)
	if(!belly) //nothing to see here if we do not have a stomach
		return fullness

	for(var/bile in belly.reagents.reagent_list)
		var/datum/reagent/bits = bile
		if(istype(bits, /datum/reagent/consumable))
			var/datum/reagent/consumable/goodbit = bile
			fullness += goodbit.nutriment_factor * goodbit.volume / goodbit.metabolization_rate
			continue
		fullness += 0.6 * bits.volume / bits.metabolization_rate //not food takes up space

	return fullness

/mob/living/carbon/has_reagent(reagent, amount = -1, needs_metabolizing = FALSE)
	. = ..()
	if(.)
		return
	var/obj/item/organ/stomach/belly = getorganslot(ORGAN_SLOT_STOMACH)
	if(!belly)
		return FALSE
	return belly.reagents.has_reagent(reagent, amount, needs_metabolizing)

/////////
//LIVER//
/////////

///Check to see if we have the liver, if not automatically gives you last-stage effects of lacking a liver.

/mob/living/carbon/proc/handle_liver(delta_time, times_fired)
	if(!dna)
		return

	var/obj/item/organ/liver/liver = getorganslot(ORGAN_SLOT_LIVER)
	if(liver)
		return

	reagents.end_metabolization(src, keep_liverless = TRUE) //Stops trait-based effects on reagents, to prevent permanent buffs
	reagents.metabolize(src, delta_time, times_fired, can_overdose=FALSE, liverless = TRUE)

	if(HAS_TRAIT(src, TRAIT_STABLELIVER) || HAS_TRAIT(src, TRAIT_NOMETABOLISM))
		return

	adjustToxLoss(0.6 * delta_time, TRUE,  TRUE)
	adjustOrganLoss(pick(ORGAN_SLOT_HEART, ORGAN_SLOT_LUNGS, ORGAN_SLOT_STOMACH, ORGAN_SLOT_EYES, ORGAN_SLOT_EARS), 0.5* delta_time)

/mob/living/carbon/proc/undergoing_liver_failure()
	var/obj/item/organ/liver/liver = getorganslot(ORGAN_SLOT_LIVER)
	if(liver?.organ_flags & ORGAN_FAILING)
		return TRUE

/////////////
//CREMATION//
/////////////
/mob/living/carbon/proc/check_cremation(delta_time, times_fired)
	//Only cremate while actively on fire
	if(!on_fire)
		return

	//Only starts when the chest has taken full damage
	var/obj/item/bodypart/chest = get_bodypart(BODY_ZONE_CHEST)
	if(!(chest.get_damage() >= chest.max_damage))
		return

	//Burn off limbs one by one
	var/obj/item/bodypart/limb
	var/list/limb_list = list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	var/still_has_limbs = FALSE
	for(var/zone in limb_list)
		limb = get_bodypart(zone)
		if(limb)
			still_has_limbs = TRUE
			if(limb.get_damage() >= limb.max_damage)
				limb.cremation_progress += rand(1 * delta_time, 2.5 * delta_time)
				if(limb.cremation_progress >= 100)
					if(limb.status == BODYPART_ORGANIC) //Non-organic limbs don't burn
						limb.drop_limb()
						limb.visible_message(span_warning("[src]'s [limb.name] crumbles into ash!"))
						qdel(limb)
					else
						limb.drop_limb()
						limb.visible_message(span_warning("[src]'s [limb.name] detaches from [p_their()] body!"))
	if(still_has_limbs)
		return

	//Burn the head last
	var/obj/item/bodypart/head = get_bodypart(BODY_ZONE_HEAD)
	if(head)
		if(head.get_damage() >= head.max_damage)
			head.cremation_progress += rand(1 * delta_time, 2.5 * delta_time)
			if(head.cremation_progress >= 100)
				if(head.status == BODYPART_ORGANIC) //Non-organic limbs don't burn
					head.drop_limb()
					head.visible_message(span_warning("[src]'s head crumbles into ash!"))
					qdel(head)
				else
					head.drop_limb()
					head.visible_message(span_warning("[src]'s head detaches from [p_their()] body!"))
		return

	//Nothing left: dust the body, drop the items (if they're flammable they'll burn on their own)
	chest.cremation_progress += rand(1 * delta_time, 2.5 * delta_time)
	if(chest.cremation_progress >= 100)
		visible_message(span_warning("[src]'s body crumbles into a pile of ash!"))
		dust(TRUE, TRUE)

/////////////////////////////////////
//MONKEYS WITH TOO MUCH CHOLOESTROL//
/////////////////////////////////////

/mob/living/carbon/proc/can_heartattack()
	if(!needs_heart())
		return FALSE
	var/obj/item/organ/heart/heart = getorganslot(ORGAN_SLOT_HEART)
	if(!heart || (heart.organ_flags & ORGAN_SYNTHETIC))
		return FALSE
	return TRUE

/mob/living/carbon/proc/needs_heart()
	if(HAS_TRAIT(src, TRAIT_STABLEHEART))
		return FALSE
	if(dna && dna.species && (NOBLOOD in dna.species.species_traits)) //not all carbons have species!
		return FALSE
	return TRUE

/*
 * The mob is having a heart attack
 *
 * NOTE: this is true if the mob has no heart and needs one, which can be suprising,
 * you are meant to use it in combination with can_heartattack for heart attack
 * related situations (i.e not just cardiac arrest)
 */
/mob/living/carbon/proc/undergoing_cardiac_arrest()
	var/obj/item/organ/heart/heart = getorganslot(ORGAN_SLOT_HEART)
	if(istype(heart) && heart.beating)
		return FALSE
	else if(!needs_heart())
		return FALSE
	return TRUE

/mob/living/carbon/proc/set_heartattack(status)
	if(!can_heartattack())
		return FALSE

	var/obj/item/organ/heart/heart = getorganslot(ORGAN_SLOT_HEART)
	if(!istype(heart))
		return

	heart.beating = !status
