/mob/living/simple_animal/hostile/troll
	name = "cave troll"
	desc = "Monstrous, and smelly."
	icon = 'dwarfs/icons/mob/hostile.dmi'
	icon_state = "troll"
	icon_living = "troll"
	icon_dead = "troll_dead"
	gender = NEUTER
	movement_shake_radius = 5
	speak_chance = 0
	turns_per_move = 2
	speed = 0.75
	maxHealth = 950
	health = 950
	faction = list("mining")
	weather_immunities = list("lava","ash")
	see_in_dark = 1
	butcher_results = list(/obj/item/food/meat/slab/troll = list(4,8), /obj/item/stack/ore/stone = list(4,8), /obj/item/stack/sheet/mineral/coal = list(2,6),/obj/item/food/intestines=list(3,6))
	hide_type = /obj/item/stack/sheet/animalhide/troll
	response_help_continuous = "pushes"
	response_help_simple = "pushes"
	response_disarm_continuous = "pushes"
	response_disarm_simple = "pushes"
	response_harm_continuous = "hits"
	response_harm_simple = "hits"
	melee_damage_lower = 35
	melee_damage_upper = 40
	attack_verb_continuous = "attacks"
	attack_verb_simple = "attacks"
	minbodytemp = 0
	maxbodytemp = INFINITY
	gold_core_spawnable = HOSTILE_SPAWN
	pixel_x = -16
	var/rockfalling_last = 0
	discovery_points = 10000
	New()
		..()
		pixel_x = -16

/mob/living/simple_animal/hostile/troll/Initialize()
	. = ..()
	flick("troll_spawn", src)

/mob/living/simple_animal/hostile/troll/Life()
	. = ..()
	if(target && rockfalling_last < world.time && prob(50))
		rockfalling_last = world.time + 60 SECONDS
		for(var/turf/open/T in view(7, src))
			if(prob(5))
				new /obj/effect/temp_visual/rockfall(T)
				spawn(rand(30, 60))
					for(var/mob/living/L in T.contents)
						L.apply_damage_type(20, BRUTE)
						L.Paralyze(100)
						to_chat(L, span_userdanger("A PILE OF STONE IS FALLING ON ME!"))
					var/turf/closed/mineral/random/dwarf_lustress/t = /turf/closed/mineral/random/dwarf_lustress
					T.ChangeTurf(t, initial(t.baseturfs))

/obj/effect/temp_visual/rockfall
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	light_range = 2
	duration = 9

/obj/effect/temp_visual/rockfall/ex_act()
	return

/obj/effect/temp_visual/rockfall/Initialize(mapload)
	. = ..()
	INVOKE_ASYNC(src, .proc/fall)

/obj/effect/temp_visual/rockfall/proc/fall()
	var/turf/T = get_turf(src)
	playsound(T,'sound/magic/fleshtostone.ogg', 80, TRUE)

/mob/living/simple_animal/hostile/troll/death(gibbed)
	. = ..()
	playsound(src, 'dwarfs/sounds/mobs/troll/troll_death.ogg', 70, TRUE)

/mob/living/simple_animal/hostile/troll/pale
	name = "pale cave troll"
	desc = "Extremely white, it seems highly agitated."
	icon = 'dwarfs/icons/mob/hostile.dmi'
	icon_state = "paletroll"
	icon_living = "paletroll"
	icon_dead = "paletroll_dead"
	gender = NEUTER
	movement_shake_radius = 6
	speak_chance = 1
	speak_emote = list("grumbles")
	speak = list("ukner", "aghna", "thruntaki!", "krimp", "kull munn")
	turns_per_move = 2
	speed = 0.55
	maxHealth = 2500
	health = 2500
	faction = list("mining")
	weather_immunities = list("lava","ash")
	see_in_dark = 1
	butcher_results = list(/obj/item/food/meat/slab/troll = list(6,10), /obj/item/stack/ore/stone = list(4,8), /obj/item/stack/sheet/mineral/coal = list(2,6),/obj/item/food/intestines=list(3,6))
	hide_type = /obj/item/stack/sheet/animalhide/troll
	response_help_continuous = "pushes"
	response_help_simple = "pushes"
	response_disarm_continuous = "pushes"
	response_disarm_simple = "pushes"
	response_harm_continuous = "hits"
	response_harm_simple = "hits"
	melee_damage_lower = 45
	melee_damage_upper = 60
	attack_verb_continuous = "bashes"
	attack_verb_simple = "bashes"
	minbodytemp = 0
	maxbodytemp = INFINITY
	gold_core_spawnable = HOSTILE_SPAWN
	pixel_x = -16