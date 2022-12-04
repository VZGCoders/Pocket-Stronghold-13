/obj/item/clothing/suit/armor/light_plate
	name = "chest plate"
	desc = "Covers only chest area."
	worn_icon = 'dwarfs/icons/mob/clothing/suit.dmi'
	worn_icon_state = "chestplate_light"
	body_parts_covered = CHEST|GROIN
	icon = 'dwarfs/icons/items/clothing/suit.dmi'
	icon_state = "light_plate"
	inhand_icon_state = "light_plate"

/obj/item/clothing/suit/armor/heavy_plate
	name = "plate armor"
	desc = "Sturdy but heavy."
	worn_icon = 'dwarfs/icons/mob/clothing/suit.dmi'
	worn_icon_state = "chestplate_heavy"
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	w_class = WEIGHT_CLASS_GIGANTIC
	slowdown = 1
	icon = 'dwarfs/icons/items/clothing/suit.dmi'
	icon_state = "heavy_plate"
	inhand_icon_state = "heavy_plate"
	var/footstep = 1
	var/mob/listeningTo
	var/list/random_step_sound = list('sound/effects/heavystep1.ogg'=1,\
									  'sound/effects/heavystep2.ogg'=1,\
									  'sound/effects/heavystep3.ogg'=1,\
									  'sound/effects/heavystep4.ogg'=1,\
									  'sound/effects/heavystep5.ogg'=1,\
									  'sound/effects/heavystep6.ogg'=1,\
									  'sound/effects/heavystep7.ogg'=1)

/obj/item/clothing/suit/armor/heavy_plate/proc/on_mob_move()
	SIGNAL_HANDLER
	var/mob/living/carbon/human/H = loc
	if(!istype(H) || H.wear_suit != src)
		return
	if(footstep > 2)
		playsound(src, pick(random_step_sound), 100, TRUE)
		footstep = 0
	else
		footstep++

/obj/item/clothing/suit/armor/heavy_plate/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_OCLOTHING)
		if(listeningTo)
			UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
		return
	if(listeningTo == user)
		return
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, .proc/on_mob_move)
	listeningTo = user

/obj/item/clothing/suit/armor/heavy_plate/dropped()
	. = ..()
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)

/obj/item/clothing/suit/armor/heavy_plate/Destroy()
	listeningTo = null
	return ..()

/obj/item/clothing/under/chainmail
	name = "chainmail"
	desc = "Great protection from stabs and slashes for its weight."
	worn_icon = 'dwarfs/icons/mob/clothing/under.dmi'
	worn_icon_state = "chainmail"
	icon = 'dwarfs/icons/items/clothing/under.dmi'
	icon_state = "chainmail"
	inhand_icon_state = "chainmail"

/obj/item/clothing/head/helmet/plate_helmet
	name = "plate helmet"
	desc = "Protects your head from all unexpected and expected attacks."
	worn_icon = 'dwarfs/icons/mob/clothing/head.dmi'
	worn_icon_state = "helmet_heavy"
	icon = 'dwarfs/icons/items/clothing/head.dmi'
	icon_state = "helmet_heavy"
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH

/obj/item/clothing/gloves/plate_gloves
	name = "plate gloves"
	desc = "Will save your hands from unexpected losses."
	worn_icon = 'dwarfs/icons/mob/clothing/hands.dmi'
	worn_icon_state = "plate_gloves"
	icon = 'dwarfs/icons/items/clothing/gloves.dmi'
	icon_state = "plate_gloves"

/obj/item/clothing/shoes/jackboots/plate_boots
	name = "plate boots"
	desc = "The boots."
	worn_icon = 'dwarfs/icons/mob/clothing/feet.dmi'
	worn_icon_state = "sabatons"
	icon = 'dwarfs/icons/items/clothing/feet.dmi'
	icon_state = "plate_boots"

/obj/item/clothing/head/helmet/dwarf_crown
	name = "crown"
	desc = "To show the royal status."
	worn_icon = 'dwarfs/icons/mob/clothing/head.dmi'
	worn_icon_state = "king_crown"
	icon = 'dwarfs/icons/items/clothing.dmi'
	icon_state = "king_crown"
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	actions_types = list(/datum/action/item_action/send_message_action)
	var/mob/assigned_count = null

/obj/item/clothing/head/helmet/dwarf_crown/Initialize()
	. = ..()
	GLOB.dwarf_crowns+=src

/obj/item/clothing/head/helmet/dwarf_crown/Destroy()
    . = ..()
    GLOB.dwarf_crowns-=src

/datum/action/item_action/send_message_action
	name = "Send message to subjects"

/obj/item/clothing/head/helmet/dwarf_crown/proc/send_message(mob/user, msg)
	message_admins("DF: [ADMIN_LOOKUPFLW(user)]: [msg]")
	for(var/mob/M in GLOB.dwarf_list)
		to_chat(M, span_revenbignotice("[msg]"))
		var/sound/siren = sound('sound/effects/siren.ogg', volume = 25)
		SEND_SOUND(M, siren)

/obj/item/clothing/head/helmet/dwarf_crown/attack_self(mob/user)
	. = ..()
	var/busy = FALSE
	var/mob/king
	for(var/obj/item/clothing/head/helmet/dwarf_crown/C in GLOB.dwarf_crowns)
		if(C.assigned_count && C.assigned_count?.stat != DEAD)
			busy = TRUE
			king = C.assigned_count
	if(busy && assigned_count != user)
		if(user != king)
			to_chat(user, span_warning("YOU HAVE NO POWER!"))
		else
			to_chat(user, span_warning("YOU ALREADY HAVE POWER!"))
		return

	if(is_species(user, /datum/species/dwarf) && (!assigned_count || assigned_count?.stat == DEAD))
		assigned_count = user
		send_message(user, "<b>[user]</b> has been chosen as our leader!")
	if(assigned_count == user)
		var/msg = stripped_input(user, "What to say?", "Message:")
		if(!msg)
			return
		user.whisper("[msg]")
		send_message(user, "<b>[user]</b>: [msg]")
	else
		to_chat(user, span_warning("YOU HAVE NO POWER!"))

/obj/item/clothing/shoes/boots
	name = "boots"
	desc = "So small a child can wear them."
	icon = 'dwarfs/icons/items/clothing/feet.dmi'
	icon_state = "boots"
	inhand_icon_state = "boots"
	worn_icon = 'dwarfs/icons/mob/clothing/feet.dmi'
	worn_icon_state = "boots"

/obj/item/clothing/under/tunic
	name = "tunic"
	desc = "Typical tunic. Smells of alcohol."
	worn_icon = 'dwarfs/icons/mob/clothing/under.dmi'
	worn_icon_state = "tunic_brown"
	icon = 'dwarfs/icons/items/clothing/under.dmi'
	icon_state = "tunic_brown"

/obj/item/clothing/under/tunic/Initialize(mycolor=null)
	. = ..()
	select_color("white")

/obj/item/clothing/under/tunic/random/Initialize(mycolor=null)
	. = ..()
	select_color(mycolor)

/obj/item/clothing/under/tunic/proc/select_color(mycolor=null)
	if(!mycolor)
		mycolor = pick("brown","red","yellow","green","aqua","blue","purple","white","gray","black")
	worn_icon_state = "tunic_[mycolor]"
	icon_state = "tunic_[mycolor]"
	name = "[mycolor] [initial(name)]"

/obj/item/clothing/under/smith
	name = "smiths tunic"
	desc = "A sleeveless tunic used by dwarven smiths. Smells of sweat."
	worn_icon = 'dwarfs/icons/mob/clothing/under.dmi'
	worn_icon_state = "tunic_smith"
	icon = 'dwarfs/icons/items/clothing/under.dmi'
	icon_state = "tunic_smith"
//Contributed by Skubblers#7276//

/obj/item/clothing/under/loincloth
	name = "loincloth"
	desc = "A few pieces of fabric barely holding together."
	worn_icon = 'dwarfs/icons/mob/clothing/under.dmi'
	worn_icon_state = "loincloth"
	icon = 'dwarfs/icons/items/clothing/under.dmi'
	icon_state = "loincloth"
	body_parts_covered = GROIN|LEGS
