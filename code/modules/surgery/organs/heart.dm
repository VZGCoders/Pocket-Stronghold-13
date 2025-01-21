/obj/item/organ/heart
	name = "heart"
	desc = "I feel bad for the heartless bastard who lost this."
	icon_state = "heart-on"
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_HEART

	healing_factor = STANDARD_ORGAN_HEALING
	decay_factor = 2.5 * STANDARD_ORGAN_DECAY		//designed to fail around 6 minutes after death

	low_threshold_passed = span_info("Prickles of pain appear then die out from within your chest...")
	high_threshold_passed = span_warning("Something inside your chest hurts, and the pain isn't subsiding. You notice yourself breathing far faster than before.")
	now_fixed = span_info("Your heart begins to beat again.")
	high_threshold_cleared = span_info("The pain in your chest has died down, and your breathing becomes more relaxed.")

	// Heart attack code is in code/modules/mob/living/carbon/human/life.dm
	var/beating = 1
	var/icon_base = "heart"
	attack_verb_continuous = list("beats", "thumps")
	attack_verb_simple = list("beat", "thump")
	var/beat = BEAT_NONE//is this mob having a heatbeat sound played? if so, which?
	var/failed = FALSE		//to prevent constantly running failing code
	var/operated = FALSE	//whether the heart's been operated on to fix some of its damages

/obj/item/organ/heart/update_icon_state()
	if(beating)
		icon_state = "[icon_base]-on"
	else
		icon_state = "[icon_base]-off"
	return ..()

/obj/item/organ/heart/Remove(mob/living/carbon/M, special = 0)
	..()
	if(!special)
		addtimer(CALLBACK(src, PROC_REF(stop_if_unowned)), 120)

/obj/item/organ/heart/proc/stop_if_unowned()
	if(!owner)
		Stop()

/obj/item/organ/heart/attack_self(mob/user)
	..()
	if(!beating)
		user.visible_message(span_notice("[user] squeezes [src]!") ,span_notice("You squeeze [src] to make it beat again!"))
		Restart()
		addtimer(CALLBACK(src, PROC_REF(stop_if_unowned)), 80)

/obj/item/organ/heart/proc/Stop()
	beating = 0
	update_icon()
	return 1

/obj/item/organ/heart/proc/Restart()
	beating = 1
	update_icon()
	return 1

/obj/item/organ/heart/OnEatFrom(eater, feeder)
	. = ..()
	beating = FALSE
	update_icon()

/obj/item/organ/heart/on_life(delta_time, times_fired)
	..()

	// If the owner doesn't need a heart, we don't need to do anything with it.
	if(!owner.needs_heart())
		return

	if(owner.client && beating)
		failed = FALSE
		var/sound/slowbeat = sound('sound/health/slowbeat.ogg', repeat = TRUE)
		var/sound/fastbeat = sound('sound/health/fastbeat.ogg', repeat = TRUE)
		var/mob/living/carbon/H = owner


		if(H.health <= H.crit_threshold && beat != BEAT_SLOW)
			beat = BEAT_SLOW
			H.playsound_local(get_turf(H), slowbeat, 40, 0, channel = CHANNEL_HEARTBEAT, use_reverb = FALSE)
			to_chat(owner, span_notice("You feel your heart slow down..."))
		if(beat == BEAT_SLOW && H.health > H.crit_threshold)
			H.stop_sound_channel(CHANNEL_HEARTBEAT)
			beat = BEAT_NONE

		if(H.jitteriness)
			if(H.health > HEALTH_THRESHOLD_FULLCRIT && (!beat || beat == BEAT_SLOW))
				H.playsound_local(get_turf(H), fastbeat, 40, 0, channel = CHANNEL_HEARTBEAT, use_reverb = FALSE)
				beat = BEAT_FAST
		else if(beat == BEAT_FAST)
			H.stop_sound_channel(CHANNEL_HEARTBEAT)
			beat = BEAT_NONE

	if(organ_flags & ORGAN_FAILING)	//heart broke, stopped beating, death imminent
		if(owner.stat == CONSCIOUS)
			owner.visible_message(span_danger("[owner] clutches at [owner.p_their()] chest as if [owner.p_their()] heart is stopping!"), \
				span_userdanger("You feel a terrible pain in your chest, as if your heart has stopped!"))
		owner.set_heartattack(TRUE)
		failed = TRUE

/obj/item/organ/heart/get_availability(datum/species/S)
	return !(NOBLOOD in S.species_traits)
