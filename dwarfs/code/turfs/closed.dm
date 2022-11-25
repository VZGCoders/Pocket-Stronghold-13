/turf/closed/mineral/random/dwarf_lustress
	icon = 'dwarfs/icons/turf/walls_cavern.dmi'
	smooth_icon = 'dwarfs/icons/turf/walls_cavern.dmi'
	icon_state = "rockwall-0"
	base_icon_state = "rockwall"
	environment_type = "stone_raw"
	turf_type = /turf/open/floor/rock
	baseturfs = /turf/open/floor/rock
	mineralSpawnChanceList = list(/obj/item/stack/ore/smeltable/gold = 20, /obj/item/stack/ore/smeltable/iron = 40, /obj/item/stack/ore/gem/diamond=10,/obj/item/stack/ore/gem/ruby=10,/obj/item/stack/ore/gem/sapphire=10,/obj/item/stack/ore/coal=40)
	mineralChance = 1

/turf/closed/mineral/random/dwarf_lustress/gets_drilled(user, give_exp = FALSE)
	. = ..()

	if(prob(40))
		new /obj/item/stack/ore/stone(src)

	if(prob(0.1))
		to_chat(user, span_userdanger("THIS ROCK APPEARS TO BE ESPECIALLY SOFT!"))
		new /mob/living/simple_animal/hostile/troll(src)

/turf/closed/wall/stone
	name = "stone wall"
	desc = "Just a regular stone wall."
	icon = 'dwarfs/icons/turf/walls_dwarven.dmi'
	icon_state = "rich_wall-0"
	base_icon_state = "rich_wall"
	sheet_type = /obj/item/stack/sheet/stone
	baseturfs = /turf/open/floor/stone
	sheet_amount = 3

/turf/closed/mineral/random/sand
	name = "sand"
	mineralSpawnChanceList = list(/obj/item/stack/ore/smeltable/gold = 20, /obj/item/stack/ore/smeltable/iron = 40, /obj/item/stack/ore/gem/diamond=10,/obj/item/stack/ore/gem/ruby=10,/obj/item/stack/ore/gem/sapphire=10,/obj/item/stack/ore/coal=40)
	mineralChance = 1.5
	baseturfs = /turf/open/floor/sand
	smooth_icon = 'dwarfs/icons/turf/walls_sandstone.dmi'
	base_icon_state = "rockwall"
	icon = 'dwarfs/icons/turf/walls_sandstone.dmi'
	icon_state = "rockwall-0"

/turf/closed/mineral/random/sand/gets_drilled(user, give_exp)
	. = ..()
	if(prob(40))
		new /obj/item/stack/ore/smeltable/sand(src)

/turf/closed/mineral/random/dwarf_lustress/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_CHISEL)
		var/turf/T = src
		var/time = 5 SECONDS * user.mind.get_skill_modifier(/datum/skill/mining, SKILL_SPEED_MODIFIER)
		to_chat(user, span_notice("You start carving stone wall..."))
		if(I.use_tool(src, user, time, volume=50))
			to_chat(user, span_notice("You finish carving stone wall."))
			user.mind.adjust_experience(/datum/skill/mining, 3)
			T.ChangeTurf(/turf/closed/wall/stone, initial(T.baseturfs))
	..()
