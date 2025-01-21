/datum/element/art
	element_flags = ELEMENT_BESPOKE|ELEMENT_DETACH
	id_arg_index = 2
	var/impressiveness = 0

/datum/element/art/Attach(datum/target, impress)
	. = ..()
	if(!isatom(target) || isarea(target))
		return ELEMENT_INCOMPATIBLE
	impressiveness = impress
	RegisterSignal(target, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/element/art/Detach(datum/target)
	UnregisterSignal(target, COMSIG_PARENT_EXAMINE)
	return ..()

/datum/element/art/proc/apply_moodlet(atom/source, mob/user, impress)
	SIGNAL_HANDLER

	var/msg
	switch(impress)
		if(GREAT_ART to INFINITY)
			SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "artgreat", /datum/mood_event/artgreat)
			msg = "What \a [pick("masterpiece", "chef-d'oeuvre")]. So [pick("trascended", "awe-inspiring", "bewitching", "impeccable")]!"
		if (GOOD_ART to GREAT_ART)
			SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "artgood", /datum/mood_event/artgood)
			msg = "[source.p_theyre(TRUE)] a [pick("respectable", "commendable", "laudable")] art piece, easy on the keen eye."
		if (BAD_ART to GOOD_ART)
			SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "artok", /datum/mood_event/artok)
			msg = "[source.p_theyre(TRUE)] fair to middling, enough to be called an \"art object\"."
		if (0 to BAD_ART)
			SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "artbad", /datum/mood_event/artbad)
			msg = "Wow, [source.p_they()] sucks."

	user.visible_message(span_notice("[user] stops and looks intently at [source]."), \
		span_notice("You appraise [source]... [msg]"))

/datum/element/art/proc/on_examine(atom/source, mob/user, list/examine_texts)
	SIGNAL_HANDLER

	if(!DOING_INTERACTION_WITH_TARGET(user, source))
		INVOKE_ASYNC(src, PROC_REF(appraise), source, user) //Do not sleep the proc.

/datum/element/art/proc/appraise(atom/source, mob/user)
	to_chat(user, span_notice("You start appraising [source]..."))
	if(!do_after(user, 2 SECONDS, target = source))
		return
	var/mult = 1
	if(isobj(source))
		var/obj/art_piece = source
		mult = art_piece.get_integrity() / art_piece.max_integrity

	apply_moodlet(source, user, impressiveness * mult)
