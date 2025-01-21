#define AB_CHECK_HANDS_BLOCKED (1<<0)
#define AB_CHECK_IMMOBILE (1<<1)
#define AB_CHECK_LYING (1<<2)
#define AB_CHECK_CONSCIOUS (1<<3)

/datum/action
	var/name = "Generic Action"
	var/desc = null
	var/obj/target = null
	var/check_flags = NONE
	var/processing = FALSE
	var/atom/movable/screen/movable/action_button/button = null
	var/buttontooltipstyle = ""
	var/transparent_when_unavailable = TRUE

	var/button_icon = 'icons/mob/actions/backgrounds.dmi' //This is the file for the BACKGROUND icon
	var/background_icon_state = ACTION_BUTTON_DEFAULT_BACKGROUND //And this is the state for the background icon

	var/icon_icon = 'icons/hud/actions.dmi' //This is the file for the ACTION icon
	var/button_icon_state = "default" //And this is the state for the action icon
	var/mob/owner

/datum/action/New(Target)
	link_to(Target)
	button = new
	button.linked_action = src
	button.name = name
	button.actiontooltipstyle = buttontooltipstyle
	if(desc)
		button.desc = desc

/datum/action/proc/link_to(Target)
	target = Target
	RegisterSignal(Target, COMSIG_ATOM_UPDATED_ICON, PROC_REF(OnUpdatedIcon))

/datum/action/Destroy()
	if(owner)
		Remove(owner)
	target = null
	QDEL_NULL(button)
	return ..()

/datum/action/proc/Grant(mob/M)
	if(M)
		if(owner)
			if(owner == M)
				return
			Remove(owner)
		owner = M

		//button id generation
		var/counter = 0
		var/bitfield = 0
		for(var/datum/action/A in M.actions)
			if(A.name == name && A.button.id)
				counter += 1
				bitfield |= A.button.id
		bitfield = ~bitfield
		var/bitflag = 1
		for(var/i in 1 to (counter + 1))
			if(bitfield & bitflag)
				button.id = bitflag
				break
			bitflag *= 2

		LAZYADD(M.actions, src)
		if(M.client)
			M.client.screen += button
			button.locked = M.client.prefs.buttons_locked || button.id ? M.client.prefs.action_buttons_screen_locs["[name]_[button.id]"] : FALSE //even if it's not defaultly locked we should remember we locked it before
			button.moved = button.id ? M.client.prefs.action_buttons_screen_locs["[name]_[button.id]"] : FALSE
		M.update_action_buttons()
	else
		Remove(owner)

/datum/action/proc/Remove(mob/M)
	if(M)
		if(M.client)
			M.client.screen -= button
		LAZYREMOVE(M.actions, src)
		M.update_action_buttons()
	owner = null
	button.moved = FALSE //so the button appears in its normal position when given to another owner.
	button.locked = FALSE
	button.id = null

/datum/action/proc/Trigger()
	if(!IsAvailable())
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_ACTION_TRIGGER, src) & COMPONENT_ACTION_BLOCK_TRIGGER)
		return FALSE
	return TRUE


/datum/action/proc/IsAvailable()
	if(!owner)
		return FALSE
	if((check_flags & AB_CHECK_HANDS_BLOCKED) && HAS_TRAIT(owner, TRAIT_HANDS_BLOCKED))
		return FALSE
	if((check_flags & AB_CHECK_IMMOBILE) && HAS_TRAIT(owner, TRAIT_IMMOBILIZED))
		return FALSE
	if((check_flags & AB_CHECK_LYING) && isliving(owner))
		var/mob/living/action_user = owner
		if(action_user.body_position == LYING_DOWN)
			return FALSE
	if((check_flags & AB_CHECK_CONSCIOUS) && owner.stat != CONSCIOUS)
		return FALSE
	return TRUE


/datum/action/proc/UpdateButtonIcon(status_only = FALSE, force = FALSE)
	if(button)
		if(!status_only)
			button.name = name
			button.desc = desc
			if(owner?.hud_used && background_icon_state == ACTION_BUTTON_DEFAULT_BACKGROUND)
				var/list/settings = owner.hud_used.get_action_buttons_icons()
				if(button.icon != settings["bg_icon"])
					button.icon = settings["bg_icon"]
				if(button.icon_state != settings["bg_state"])
					button.icon_state = settings["bg_state"]
			else
				if(button.icon != button_icon)
					button.icon = button_icon
				if(button.icon_state != background_icon_state)
					button.icon_state = background_icon_state

			ApplyIcon(button, force)

		if(!IsAvailable())
			button.color = transparent_when_unavailable ? rgb(128,0,0,128) : rgb(128,0,0)
		else
			button.color = rgb(255,255,255,255)
			return 1

/datum/action/proc/ApplyIcon(atom/movable/screen/movable/action_button/current_button, force = FALSE)
	if(icon_icon && button_icon_state && ((current_button.button_icon_state != button_icon_state) || force))
		current_button.cut_overlays(TRUE)
		current_button.add_overlay(mutable_appearance(icon_icon, button_icon_state))
		current_button.button_icon_state = button_icon_state

/datum/action/proc/OnUpdatedIcon()
	SIGNAL_HANDLER

	UpdateButtonIcon()

//Presets for item actions
/datum/action/item_action
	check_flags = AB_CHECK_HANDS_BLOCKED|AB_CHECK_CONSCIOUS
	button_icon_state = null
	// If you want to override the normal icon being the item
	// then change this to an icon state

/datum/action/item_action/New(Target)
	..()
	var/obj/item/I = target
	LAZYINITLIST(I.actions)
	I.actions += src

/datum/action/item_action/Destroy()
	var/obj/item/I = target
	I.actions -= src
	UNSETEMPTY(I.actions)
	return ..()

/datum/action/item_action/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(target)
		var/obj/item/I = target
		I.ui_action_click(owner, src)
	return TRUE

/datum/action/item_action/ApplyIcon(atom/movable/screen/movable/action_button/current_button, force)
	if(button_icon && button_icon_state)
		// If set, use the custom icon that we set instead
		// of the item appearence
		..()
	else if((target && current_button.appearance_cache != target.appearance) || force) //replace with /ref comparison if this is not valid.
		var/obj/item/I = target
		var/old_layer = I.layer
		var/old_plane = I.plane
		I.layer = FLOAT_LAYER //AAAH
		I.plane = FLOAT_PLANE //^ what that guy said
		current_button.cut_overlays()
		current_button.add_overlay(I)
		I.layer = old_layer
		I.plane = old_plane
		current_button.appearance_cache = I.appearance

/datum/action/item_action/toggle_hood
	name = "Toggle Hood"

/datum/action/item_action/toggle_firemode
	name = "Toggle Firemode"

/datum/action/item_action/rcl_col
	name = "Change Cable Color"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "rcl_rainbow"

/datum/action/item_action/rcl_gui
	name = "Toggle Fast Wiring Gui"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "rcl_gui"

/datum/action/item_action/startchainsaw
	name = "Pull The Starting Cord"

/datum/action/item_action/toggle_gunlight
	name = "Toggle Gunlight"

/datum/action/item_action/toggle_mode
	name = "Toggle mode"

/datum/action/item_action/toggle_barrier_spread
	name = "Toggle Barrier Spread"

/datum/action/item_action/equip_unequip_ted_gun
	name = "Equip/Unequip TED Gun"

/datum/action/item_action/toggle_paddles
	name = "Toggle paddles"

/datum/action/item_action/pick_color
	name = "Choose A Color"

/datum/action/item_action/toggle_mister
	name = "Toggle Mister"

/datum/action/item_action/activate_injector
	name = "Activate Injector"

/datum/action/item_action/toggle_helmet_light
	name = "Toggle Helmet Light"

/datum/action/item_action/toggle_helmet_flashlight
	name = "Toggle Helmet Flashlight"

/datum/action/item_action/toggle_helmet_mode
	name = "Toggle Helmet Mode"

/datum/action/item_action/crew_monitor
	name = "Interface With Crew Monitor"

/datum/action/item_action/toggle

/datum/action/item_action/toggle/New(Target)
	..()
	name = "Toggle [target.name]"
	button.name = name

/datum/action/item_action/halt
	name = "HALT!"

/datum/action/item_action/toggle_voice_box
	name = "Toggle Voice Box"

/datum/action/item_action/change
	name = "Change"

/datum/action/item_action/adjust

/datum/action/item_action/adjust/New(Target)
	..()
	name = "Adjust [target.name]"
	button.name = name

/datum/action/item_action/switch_hud
	name = "Switch HUD"

/datum/action/item_action/toggle_wings
	name = "Toggle Wings"

/datum/action/item_action/toggle_human_head
	name = "Toggle Human Head"

/datum/action/item_action/toggle_helmet
	name = "Toggle Helmet"

/datum/action/item_action/hands_free
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/item_action/hands_free/activate
	name = "Activate"

/datum/action/item_action/hands_free/shift_nerves
	name = "Shift Nerves"

/datum/action/item_action/explosive_implant
	check_flags = NONE
	name = "Activate Explosive Implant"

/datum/action/item_action/toggle_research_scanner
	name = "Toggle Research Scanner"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "scan_mode"
	var/active = FALSE

/datum/action/item_action/toggle_research_scanner/Trigger()
	if(IsAvailable())
		active = !active
		if(active)
			owner.research_scanner++
		else
			owner.research_scanner--
		to_chat(owner, span_notice("[target] research scanner has been [active ? "activated" : "deactivated"]."))
		return 1

/datum/action/item_action/toggle_research_scanner/Remove(mob/M)
	if(owner && active)
		owner.research_scanner--
		active = FALSE
	..()

/datum/action/item_action/instrument
	name = "Use Instrument"
	desc = "Use the instrument specified"

/datum/action/item_action/instrument/Trigger()
	if(istype(target, /obj/item/instrument))
		var/obj/item/instrument/I = target
		I.interact(usr)
		return
	return ..()

/datum/action/item_action/activate_remote_view
	name = "Activate Remote View"
	desc = "Activates the Remote View of your spy sunglasses."

/datum/action/item_action/organ_action
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/item_action/organ_action/IsAvailable()
	var/obj/item/organ/I = target
	if(!I.owner)
		return FALSE
	return ..()

/datum/action/item_action/organ_action/toggle/New(Target)
	..()
	name = "toggle [target.name]"
	button.name = name

/datum/action/item_action/organ_action/use/New(Target)
	..()
	name = "Use [target.name]"
	button.name = name


//Preset for general and toggled actions
/datum/action/innate
	check_flags = NONE
	var/active = 0

/datum/action/innate/Trigger()
	if(!..())
		return FALSE
	if(!active)
		Activate()
	else
		Deactivate()
	return TRUE

/datum/action/innate/proc/Activate()
	return

/datum/action/innate/proc/Deactivate()
	return

//Preset for an action with a cooldown

/datum/action/cooldown
	check_flags = NONE
	transparent_when_unavailable = FALSE
	var/cooldown_time = 0
	var/next_use_time = 0

/datum/action/cooldown/New()
	..()
	button.maptext = ""
	button.maptext_x = 8
	button.maptext_y = 0
	button.maptext_width = 24
	button.maptext_height = 12

/datum/action/cooldown/IsAvailable()
	return next_use_time <= world.time

/datum/action/cooldown/proc/StartCooldown()
	next_use_time = world.time + cooldown_time
	button.maptext = MAPTEXT("<b>[round(cooldown_time/10, 0.1)]</b>")
	UpdateButtonIcon()
	START_PROCESSING(SSfastprocess, src)

/datum/action/cooldown/process()
	if(!owner)
		button.maptext = ""
		STOP_PROCESSING(SSfastprocess, src)
	var/timeleft = max(next_use_time - world.time, 0)
	if(timeleft == 0)
		button.maptext = ""
		UpdateButtonIcon()
		STOP_PROCESSING(SSfastprocess, src)
	else
		button.maptext = MAPTEXT("<b>[round(timeleft/10, 0.1)]</b>")

/datum/action/cooldown/Grant(mob/M)
	..()
	if(owner)
		UpdateButtonIcon()
		if(next_use_time > world.time)
			START_PROCESSING(SSfastprocess, src)

/datum/action/item_action/storage_gather_mode
	name = "Switch gathering mode"
	desc = "Switches the gathering mode of a storage object."
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "storage_gather_switch"

/datum/action/item_action/storage_gather_mode/ApplyIcon(atom/movable/screen/movable/action_button/current_button)
	. = ..()
	var/old_layer = target.layer
	var/old_plane = target.plane
	target.layer = FLOAT_LAYER //AAAH
	target.plane = FLOAT_PLANE //^ what that guy said
	current_button.cut_overlays()
	current_button.add_overlay(target)
	target.layer = old_layer
	target.plane = old_plane
	current_button.appearance_cache = target.appearance

/datum/action/toggle_attack
	name = "Toggle Attack"
	desc = "Switches attack mode on this weapon."
	icon_icon = 'dwarfs/icons/mob/actions.dmi'
	button_icon_state = "toggle_attack"

/datum/action/toggle_attack/Trigger()
	var/datum/component/attack_toggle/C = target.GetComponent(/datum/component/attack_toggle)
	C.toggle_attack(owner)
