/obj/item/liftable //placeholder item that you pick up when picking up parent
	var/obj/parent
	item_flags = SLOWS_WHILE_IN_HAND

/obj/item/liftable/Initialize()
	. = ..()
	AddComponent(/datum/component/two_handed, require_twohands=TRUE)

/obj/item/liftable/dropped(mob/user, silent)
	. = ..()
	parent.forceMove(get_turf(user))
	moveToNullspace(null)

/obj/item/liftable/examine(mob/user)
	return parent.examine(user)

/datum/component/liftable
	var/lift_delay
	var/obj/item/liftable/item

/datum/component/liftable/Initialize(lift_delay = 10 SECONDS, slowdown = 5, worn_icon = null, inhand_icon_state = null)
	src.lift_delay = lift_delay

	//Create placeholder item that will be picked up
	item = new()
	item.parent = parent
	item.slowdown = slowdown
	var/obj/P = parent
	item.name = P.name
	item.desc = P.desc
	if(!worn_icon)
		worn_icon = P.icon
	item.lefthand_file = worn_icon
	item.righthand_file = worn_icon
	if(inhand_icon_state)
		item.inhand_icon_state = inhand_icon_state
	update_item()

	RegisterSignal(parent, COMSIG_MOUSEDROP_ONTO, PROC_REF(dragged))
	RegisterSignal(parent, COMSIG_ATOM_UPDATE_APPEARANCE, PROC_REF(update_item))

/datum/component/liftable/proc/dragged(atom/over, src_location, over_location, src_control, over_control, params, forced = FALSE)
	if(src_location != over_location)
		return
	if(!ishuman(src_location))
		return
	if(!(src_location in range(1, over)) && !forced)
		return
	var/mob/living/carbon/human/H = src_location
	to_chat(H, span_notice("You start lifting \the [over]."))
	if(!do_after(H, lift_delay, over))
		return
	if(!H.put_in_active_hand(item))
		return
	to_chat(H, span_notice("You lift \the [over]."))
	var/obj/P = over
	P.moveToNullspace(null)


/datum/component/liftable/proc/update_item()
	spawn(1) //We have to wait a bit for parent to update otherwise we will copy their previous appearance
		var/obj/P = parent
		item.icon = P.icon
		item.icon_state = P.icon_state
		item.copy_overlays(P, TRUE)
		item.update_appearance()
