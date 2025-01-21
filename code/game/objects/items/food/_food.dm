///Abstract class to allow us to easily create all the generic "normal" food without too much copy pasta of adding more components
/obj/item/food
	name = "food"
	desc = "you eat this"
	resistance_flags = FLAMMABLE
	w_class = WEIGHT_CLASS_SMALL
	icon = 'dwarfs/icons/items/food.dmi'
	icon_state = null
	lefthand_file = 'icons/mob/inhands/misc/food_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/food_righthand.dmi'
	obj_flags = UNIQUE_RENAME
	material_flags = MATERIAL_NO_EFFECTS
	grind_results = list()
	///List of reagents this food gets on creation
	var/list/food_reagents
	///Extra flags for things such as if the food is in a container or not
	var/food_flags
	///Bitflag of the types of food this food is
	var/foodtypes
	///Amount of volume the food can contain
	var/max_volume
	///How long it will take to eat this food without any other modifiers
	var/eat_time
	///Tastes to describe this food
	var/list/tastes
	///Verbs used when eating this food in the to_chat messages
	var/list/eatverbs
	///How much reagents per bite
	var/bite_consumption
	///Type of atom thats spawned after eating this item
	var/trash_type
	///Price of this food if sold in a venue
	var/venue_value
	///Food that's immune to decomposition.
	var/preserved_food = FALSE
	///Mood when eaten
	var/mood_gain
	var/mood_event_type
	var/mood_duration

/obj/item/food/Initialize(mapload)
	. = ..()
	if(food_reagents)
		food_reagents = string_assoc_list(food_reagents)
	if(tastes)
		tastes = string_assoc_list(tastes)
	if(eatverbs)
		eatverbs = string_list(eatverbs)
	MakeEdible()
	MakeProcessable()
	MakeLeaveTrash()
	MakeDecompose(mapload)

///This proc adds the edible component, overwrite this if you for some reason want to change some specific args like callbacks.
/obj/item/food/proc/MakeEdible()
	AddComponent(/datum/component/edible,\
				initial_reagents = food_reagents,\
				food_flags = food_flags,\
				foodtypes = foodtypes,\
				volume = max_volume,\
				eat_time = eat_time,\
				tastes = tastes,\
				eatverbs = eatverbs,\
				bite_consumption = bite_consumption,\
				on_consume = CALLBACK(src, PROC_REF(on_consume)))


///This proc handles processable elements, overwrite this if you want to add behavior such as slicing, forking, spooning, whatever, to turn the item into something else
/obj/item/food/proc/MakeProcessable()
	return

///This proc handles trash components, overwrite this if you want the object to spawn trash
/obj/item/food/proc/MakeLeaveTrash()
	if(trash_type)
		AddElement(/datum/element/food_trash, trash_type)
	return

///This proc makes things decompose. Set preserved_food to TRUE to make it never decompose.
/obj/item/food/proc/MakeDecompose(mapload)
	return

/obj/item/food/proc/on_consume(mob/living/eater, mob/living/feeder)
	var/datum/component/mood/M = eater.GetComponent(/datum/component/mood)
	if(!M)
		return
	if(mood_event_type)
		M.add_event(null, "food", mood_event_type, mood_gain ? mood_gain : null, mood_duration ? mood_duration : null)

/obj/item/food/badrecipe
	name = "burned recipe"
	desc = "You've failed it. Try again."
	icon_state = "food_ruined"
	mood_event_type = /datum/mood_event/ate_badfood
	food_reagents = list(/datum/reagent/consumable/nutriment = 1)

/obj/item/food/cookie
	name = "cookie"
	desc = "COOKIE!!!"
	icon_state = "cookie"
	bite_consumption = 1
	food_reagents = list(/datum/reagent/consumable/nutriment = 2)
	tastes = list("cookie" = 1)
	foodtypes = GRAIN | SUGAR
	food_flags = FOOD_FINGER_FOOD
	w_class = WEIGHT_CLASS_SMALL
