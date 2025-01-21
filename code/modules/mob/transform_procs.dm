#define TRANSFORMATION_DURATION 22

/mob/living/carbon/human/Animalize()

	var/list/mobtypes = typesof(/mob/living/simple_animal)
	var/mobpath = tgui_input_list(usr, "Which type of mob should [src] turn into?", "Choose a type", sort_list(mobtypes, GLOBAL_PROC_REF(cmp_typepaths_asc)))

	if(!safe_animal(mobpath))
		to_chat(usr, span_danger("Sorry, but this mob type is currently unavailable."))
		return

	if(notransform)
		return
	notransform = TRUE
	Paralyze(1, ignore_canstun = TRUE)

	for(var/obj/item/W in src)
		dropItemToGround(W)

	regenerate_icons()
	icon = null
	invisibility = INVISIBILITY_MAXIMUM

	for(var/t in bodyparts)
		qdel(t)

	var/mob/new_mob = new mobpath(src.loc)

	new_mob.key = key
	new_mob.a_intent = INTENT_HARM


	to_chat(new_mob, span_boldnotice("You suddenly feel more... animalistic."))
	. = new_mob
	qdel(src)

/mob/proc/Animalize()

	var/list/mobtypes = typesof(/mob/living/simple_animal)
	var/mobpath = tgui_input_list(usr, "Which type of mob should [src] turn into?", "Choose a type", sort_list(mobtypes, GLOBAL_PROC_REF(cmp_typepaths_asc)))

	if(!safe_animal(mobpath))
		to_chat(usr, span_danger("Sorry, but this mob type is currently unavailable."))
		return

	var/mob/new_mob = new mobpath(src.loc)

	new_mob.key = key
	new_mob.a_intent = INTENT_HARM
	to_chat(new_mob, span_boldnotice("You suddenly feel more... animalistic."))

	. = new_mob
	qdel(src)

/* Certain mob types have problems and should not be allowed to be controlled by players.
 *
 * This proc is here to force coders to manually place their mob in this list, hopefully tested.
 * This also gives a place to explain -why- players shouldn't be turn into certain mobs and hopefully someone can fix them.
 */
/mob/proc/safe_animal(MP)

//Bad mobs! - Remember to add a comment explaining what's wrong with the mob
	if(!MP)
		return FALSE	//Sanity, this should never happen.

//Good mobs!
	if(ispath(MP, /mob/living/simple_animal/pet/cat))
		return TRUE

	//Not in here? Must be untested!
	return FALSE

#undef TRANSFORMATION_DURATION
