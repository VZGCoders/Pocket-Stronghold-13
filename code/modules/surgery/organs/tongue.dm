/obj/item/organ/tongue
	name = "tongue"
	desc = "A muscle mainly used for lying."
	icon_state = "tonguenormal"
	zone = BODY_ZONE_PRECISE_MOUTH
	slot = ORGAN_SLOT_TONGUE
	attack_verb_continuous = list("licks", "slaps", "tongues")
	attack_verb_simple = list("lick", "slap", "tongue")
	var/list/languages_possible
	var/say_mod = null

	/// Whether the owner of this tongue can taste anything. Being set to FALSE will mean no taste feedback will be provided.
	var/sense_of_taste = TRUE

	var/taste_sensitivity = 15 // lower is more sensitive.
	var/modifies_speech = FALSE
	var/static/list/languages_possible_base = typecacheof(list(
		/datum/language/common
	))

/obj/item/organ/tongue/Initialize(mapload)
	. = ..()
	languages_possible = languages_possible_base

/obj/item/organ/tongue/proc/handle_speech(datum/source, list/speech_args)

/obj/item/organ/tongue/Insert(mob/living/carbon/M, special = 0)
	..()
	if(say_mod && M.dna && M.dna.species)
		M.dna.species.say_mod = say_mod
	if (modifies_speech)
		RegisterSignal(M, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	M.UnregisterSignal(M, COMSIG_MOB_SAY)

	/* This could be slightly simpler, by making the removal of the
	* NO_TONGUE_TRAIT conditional on the tongue's `sense_of_taste`, but
	* then you can distinguish between ageusia from no tongue, and
	* ageusia from having a non-tasting tongue.
	*/
	REMOVE_TRAIT(M, TRAIT_AGEUSIA, NO_TONGUE_TRAIT)
	if(!sense_of_taste)
		ADD_TRAIT(M, TRAIT_AGEUSIA, ORGAN_TRAIT)

/obj/item/organ/tongue/Remove(mob/living/carbon/M, special = 0)
	..()
	if(say_mod && M.dna && M.dna.species)
		M.dna.species.say_mod = initial(M.dna.species.say_mod)
	UnregisterSignal(M, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	M.RegisterSignal(M, COMSIG_MOB_SAY, TYPE_PROC_REF(/mob/living/carbon/, handle_tongueless_speech))
	REMOVE_TRAIT(M, TRAIT_AGEUSIA, ORGAN_TRAIT)
	// Carbons by default start with NO_TONGUE_TRAIT caused TRAIT_AGEUSIA
	ADD_TRAIT(M, TRAIT_AGEUSIA, NO_TONGUE_TRAIT)

/obj/item/organ/tongue/could_speak_language(language)
	return is_type_in_typecache(language, languages_possible)
