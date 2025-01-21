//Cat
GLOBAL_LIST_EMPTY(cats)
#define MAX_CATS 300
#define MAX_CLOSE_CATS 15
#define CLOSE_CATS_RANGE 25

/mob/living/simple_animal/pet/cat
	name = "cat"
	desc = "Kitty!!"
	icon = 'dwarfs/icons/mob/animals.dmi'
	icon_state = "cat"
	icon_living = "cat"
	icon_dead = "cat_dead"
	speak = list("Meow!", "Esp!", "Purr!", "HSSSSS")
	speak_emote = list("purrs", "meows")
	emote_hear = list("meows.", "mews.")
	emote_see = list("shakes its head.", "shivers.")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	pass_flags = PASSTABLE
	mob_size = MOB_SIZE_SMALL
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	minbodytemp = 200
	maxbodytemp = 400
	animal_species = /mob/living/simple_animal/pet/cat
	childtype = list(/mob/living/simple_animal/pet/cat/kitten)
	butcher_results = list(/obj/item/food/meat/slab = list(1,2), /obj/item/stack/sheet/tallow = list(0,2))
	hide_type = /obj/item/stack/sheet/animalhide/cat
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	mobility_flags = MOBILITY_FLAGS_REST_CAPABLE_DEFAULT
	var/mob/living/simple_animal/mouse/movement_target
	gold_core_spawnable = FRIENDLY_SPAWN
	can_be_held = TRUE
	held_state = "cat"
	pet_bonus = TRUE
	pet_bonus_emote = "purrs!"
	///In the case 'melee_damage_upper' is somehow raised above 0
	attack_verb_continuous = "scratches"
	attack_verb_simple = "scratch"
	attack_sound = 'sound/weapons/slash.ogg'
	attack_vis_effect = ATTACK_EFFECT_CLAW

	footstep_type = FOOTSTEP_MOB_CLAW
	deathsound = 'sound/creatures/death.ogg'
	var/list/meowlist =list('sound/creatures/meow1.ogg',
							'sound/creatures/meow2.ogg',
							'sound/creatures/meow3.ogg',
							'sound/creatures/meow4.ogg',
							'sound/creatures/meow5.ogg',
							'sound/creatures/meow6.ogg',
							'sound/creatures/meow7.ogg',
							'sound/creatures/meow8.ogg')

/mob/living/simple_animal/pet/cat/male
/mob/living/simple_animal/pet/cat/male/Initialize(_gender=null)
	.=..(MALE)
/mob/living/simple_animal/pet/cat/female
/mob/living/simple_animal/pet/cat/female/Initialize(_gender=null)
	.=..(FEMALE)

/mob/living/simple_animal/pet/cat/Initialize(_gender=null)
	. = ..()
	GLOB.cats+=src
	add_verb(src, /mob/living/proc/toggle_resting)
	add_cell_sample()
	if(_gender in list(FEMALE, MALE, PLURAL))
		gender = _gender
	else
		gender = pick(MALE, FEMALE)

/mob/living/simple_animal/pet/cat/death(gibbed)
	. = ..()
	GLOB.cats.Remove(src)

/mob/living/simple_animal/pet/cat/make_babies()
	if(GLOB.cats.len >= MAX_CATS)
		return

	var/cat_count = 0
	for(var/mob/living/simple_animal/pet/cat/C in range(CLOSE_CATS_RANGE, src))
		if(cat_count >= MAX_CLOSE_CATS)
			return
		cat_count++
		continue
	. = ..()

/mob/living/simple_animal/pet/cat/examine(mob/user)
	. = ..()
	.+= "<hr>It seems to be \a [gender]"

/mob/living/simple_animal/pet/cat/kitten
	name = "kitten"
	desc = "D'aaawwww."
	icon_state = "kitten"
	icon_living = "kitten"
	icon_dead = "kitten_dead"
	density = FALSE
	pass_flags = PASSMOB
	mob_size = MOB_SIZE_SMALL

/mob/living/simple_animal/pet/cat/kitten/Initialize(_gender=null)
	. = ..(null)
	addtimer(CALLBACK(src, PROC_REF(grow)), 2.5 MINUTES)

/mob/living/simple_animal/pet/cat/kitten/proc/grow()
	if(stat == DEAD)
		return
	var/mob/living/M = new animal_species(loc)
	M.gender = gender
	qdel(src)

/mob/living/simple_animal/pet/cat/update_resting()
	. = ..()
	if(stat == DEAD)
		return
	if (resting)
		icon_state = "[icon_living]_rest"
	else
		icon_state = "[icon_living]"
	regenerate_icons()


/mob/living/simple_animal/pet/cat/Life(delta_time = SSMOBS_DT, times_fired)
	if(!stat && !buckled && !client)
		if(DT_PROB(0.5, delta_time))
			manual_emote(pick("stretches out for a belly rub.", "wags its tail.", "lies down."))
			set_resting(TRUE)
			playsound(src, pick(meowlist), 50, TRUE)
		else if(DT_PROB(0.5, delta_time))
			manual_emote(pick("sits down.", "crouches on its hind legs.", "looks alert."))
			set_resting(TRUE)
			icon_state = "[icon_living]_sit"
			playsound(src, pick(meowlist), 25, TRUE)
		else if(DT_PROB(0.5, delta_time))
			if (resting)
				manual_emote(pick("gets up and meows.", "walks around.", "stops resting."))
				set_resting(FALSE)
				playsound(src, pick(meowlist), 25, TRUE)
			else
				manual_emote(pick("grooms its fur.", "twitches its whiskers.", "shakes out its coat."))
				playsound(src, pick(meowlist), 40, TRUE)
	..()

	if(DT_PROB(0.02, delta_time)) // Roughly 10% chance to breed
		make_babies()

	if(!stat && !resting && !buckled)
		turns_since_scan++
		if(turns_since_scan > 5)
			walk_to(src, 0)
			turns_since_scan = 0

#undef MAX_CATS
