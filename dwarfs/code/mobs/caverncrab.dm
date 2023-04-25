/mob/living/simple_animal/hostile/retaliate/caverncrab
	name = "cavern crab"
	desc = "A giant subterranian crab."
	icon = 'dwarfs/icons/mob/animals.dmi'
	icon_state = "crab"
	icon_dead = "crab_dead"
	speak_chance = 2
	speak = list("cet", "kek", "tik")
	speak_emote = list("citters")
	turns_per_move = 1
	maxHealth = 95
	health = 95
	faction = list("mining")
	weather_immunities = list("ash")
	see_in_dark = 1
	butcher_results = list(/obj/item/food/meat/slab = list(4,6))
	response_help_continuous = "pushes"
	response_help_simple = "pushes"
	response_disarm_continuous = "knocks"
	response_disarm_simple = "knocks"
	response_harm_continuous = "cuts"
	response_harm_simple = "pinches"
	melee_damage_lower = 25
	melee_damage_upper = 35
	attack_verb_continuous = "attacks"
	attack_verb_simple = "attacks"
	minbodytemp = 0
	maxbodytemp = 1600