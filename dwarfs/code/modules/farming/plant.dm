/obj/structure/plant
	name = "plant"
	desc = "Green?"
	icon = 'dwarfs/icons/farming/growing.dmi'
	icon_state = "0"
	anchored = TRUE
	layer = OBJ_LAYER
	var/species = "plant" // used for icons and to whitelist plants in plots
	var/seed_type
	var/health = 40
	var/maxhealth = 40
	var/health_delta = 5 SECONDS // how often plant takes damage when it has to
	var/lastcycle_health // last time it took damage
	var/list/produced = list() // path type list of items and their max quantity that can be produced at the last growth stage
	var/lastcycle_produce // last time it tried to grow something
	var/produce_delta = 10 SECONDS // amount of time between each try to grow new stuff
	var/harvestable = FALSE // whether a plant is ready for harvest
	var/icon_ripe // max growth stage and has harvestables on it
	var/icon_dead // icon when plant dies
	var/growthstages = 5 // how many growth stages it has
	var/growthdelta = 5 SECONDS // how long between two growth stages
	var/list/growth_modifiers = list() // growth modifiers that affect our plant e.g. fertilizer, soil quality, etc. This is a dictianory list for easy overwrites
	var/lastcycle_eat
	var/eat_delta = 5 SECONDS // how often this plant eats nutrients when planted inside a plot
	var/growthstage = 0 // current growth stage of the plant
	var/dead = FALSE // to prevent spam in plantdies()
	var/lastcycle_growth // last time it advanced in growth
	var/lifespan = 4 // plant's max age in cycles
	var/age = 1 // plants age in cycles; cycle's length is growthdelta
	var/turf/open/floor/tilled/plot // if planted via seeds will have a plot assigned to it

/obj/structure/plant/examine(mob/user)
	. = ..()
	var/healthtext = "<br>"
	healthtext += "[src] looks [health >= maxhealth / 2 ? "healthy" : health > 0 ? "unhealthy" : "dead"]!"
	. += healthtext

/obj/structure/plant/Initialize()
	. = ..()
	pixel_x = base_pixel_x + rand(-8, 8)
	pixel_y = base_pixel_y + rand(-8, 8)
	START_PROCESSING(SSplants, src)
	if(!icon_ripe)
		icon_ripe = "[species]-ripe"
	if(!icon_dead)
		icon_dead = "[species]-dead"
	if(health != maxhealth)
		maxhealth = health
	lastcycle_produce = world.time
	lastcycle_health = world.time
	lastcycle_eat = world.time
	update_appearance()

/obj/structure/plant/Destroy()
	. = ..()
	STOP_PROCESSING(SSplants, src)
	if(plot)
		plot.myplant = null
		plot.name = initial(plot.name)

/obj/structure/plant/process(delta_time)
	if(dead)
		return
	var/needs_update = 0 // Checks if the icon needs updating so we don't redraw empty trays every time
	var/temp_growthdelta = growthdelta
	for(var/modifier in growth_modifiers)
		temp_growthdelta *= growth_modifiers[modifier]
	var/time_until_growth = lastcycle_growth+temp_growthdelta // time to advance age
	if(world.time >= time_until_growth)
		lastcycle_growth = world.time
		growthcycle()
		needs_update = 1
		if(age == growthstages)
			lastcycle_produce = world.time
			grown()
	if(world.time >= lastcycle_produce+produce_delta)
		lastcycle_produce = world.time
		producecycle()
		if(harvestable)
			needs_update = 1

	if(health <= 0 && !dead)
		plantdies()
		dead = TRUE
		needs_update = 1

	if(world.time >= lastcycle_health+health_delta)
		lastcycle_health = world.time
		damagecycle()

	if(world.time > lastcycle_eat+eat_delta)
		lastcycle_eat = world.time
		eatcycle()

	if(needs_update)
		update_appearance()


/obj/structure/plant/proc/plantdies()
	SEND_SIGNAL(src, COSMIG_PLANT_DIES)
	if(dead)
		return
	visible_message(span_warning("[src] withers away!"))
	if(plot)
		return
	qdel(src)

/obj/structure/plant/proc/eatcycle()
	SEND_SIGNAL(src, COSMIG_PLANT_EAT_TICK)
	return

/obj/structure/plant/update_icon(updates)
	. = ..()
	if(dead)
		icon_state = icon_dead
	else if(harvestable)
		icon_state = icon_ripe
	else if(growthstage > 0)
		icon_state = "[species]-[growthstage]"

/obj/structure/plant/proc/can_grow_harvestable()
	if(!length(produced))
		return FALSE
	if(growthstage != growthstages)
		return FALSE
	return TRUE

/obj/structure/plant/proc/grown()
	SEND_SIGNAL(src, COSMIG_PLANT_ON_GROWN)

/obj/structure/plant/proc/growthcycle()
	var/res = SEND_SIGNAL(src, COSMIG_PLANT_ON_GROW)
	if(res & COMPONENT_CANCEL_PLANT_GROW)
		return
	age++
	growthstage = clamp(growthstage+1, 1, growthstages)

/obj/structure/plant/proc/producecycle()
	SEND_SIGNAL(src, COSMIG_PLANT_PRODUCE_TICK)
	if(can_grow_harvestable())
		harvestable = TRUE

/obj/structure/plant/proc/damagecycle()
	SEND_SIGNAL(src, COSMIG_PLANT_DAMAGE_TICK)
	if(age > lifespan)
		health -= rand(1,3)

/obj/structure/plant/proc/harvest(mob/user)
	. = TRUE
	var/speed_mod = user?.mind ? user.mind.get_skill_modifier(/datum/skill/farming, SKILL_SPEED_MODIFIER) : 1
	var/min_mod = user.mind.get_skill_modifier(/datum/skill/farming, SKILL_AMOUNT_MIN_MODIFIER)
	var/max_mod = user.mind.get_skill_modifier(/datum/skill/farming, SKILL_AMOUNT_MAX_MODIFIER)
	if(!do_after(user, 5 SECONDS * speed_mod, src))
		return FALSE
	if(QDELETED(src) || !harvestable)
		return
	harvestable = FALSE
	for(var/_P in produced)
		var/obj/item/growable/P = _P
		var/harvested = rand(0+min_mod, produced[P]+max_mod)
		if(growth_modifiers["fertilizer"] < 1 && growth_modifiers["fertilizer"] != 0) // it's fertilized
			harvested += 3
		if(harvested)
			for(var/i in 1 to harvested)
				new P(loc)
			if(seed_type)
				for(var/i in 1 to rand(1,2))
					new seed_type(get_turf(src))
			to_chat(user, span_notice("You harvest [initial(P.name)] from [src]."))
			user.mind.adjust_experience(/datum/skill/farming, harvested*8)
		else
			to_chat(user, span_warning("You fail to harvest [initial(P.name)] from [src]."))
			user.mind.adjust_experience(/datum/skill/farming, 5)
	update_appearance()

/obj/structure/plant/attack_hand(mob/user)
	if(!harvestable)
		to_chat(user, span_warning("There is nothing to harvest!"))
		return
	if(!dead)
		harvest(user)
	else
		if(plot)
			plot.attack_hand(user)
		else
			to_chat(user, span_notice("You remove the dead plant."))
			qdel(src)
