
// The shattered remnants of your broken limbs fill you with determination!
/atom/movable/screen/alert/status_effect/determined
	name = "Determined"
	desc = "The serious wounds you've sustained have put your body into fight-or-flight mode! Now's the time to look for an exit!"
	icon_state = "regenerative_core"

/datum/status_effect/determined
	id = "determined"
	alert_type = /atom/movable/screen/alert/status_effect/determined

/datum/status_effect/determined/on_apply()
	. = ..()
	owner.visible_message(span_danger("[owner]'s body tenses up noticeably, gritting against [owner.p_their()] pain!"), span_notice("<b>Your senses sharpen as your body tenses up from the wounds you've sustained!</b>"), vision_distance=COMBAT_MESSAGE_RANGE)

/datum/status_effect/determined/on_remove()
	owner.visible_message(span_danger("[owner]'s body slackens noticeably!"), span_warning("<b>Your adrenaline rush dies off, and the pain from your wounds come aching back in...</b>"), vision_distance=COMBAT_MESSAGE_RANGE)
	return ..()

/datum/status_effect/limp
	id = "limp"
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 10
	alert_type = /atom/movable/screen/alert/status_effect/limp
	var/msg_stage = 0//so you dont get the most intense messages immediately
	/// The left leg of the limping person
	var/obj/item/bodypart/l_leg/left
	/// The right leg of the limping person
	var/obj/item/bodypart/r_leg/right
	/// Which leg we're limping with next
	var/obj/item/bodypart/next_leg
	/// How many deciseconds we limp for on the left leg
	var/slowdown_left = 0
	/// How many deciseconds we limp for on the right leg
	var/slowdown_right = 0

/datum/status_effect/limp/on_apply()
	if(!iscarbon(owner))
		return FALSE
	var/mob/living/carbon/C = owner
	left = C.get_bodypart(BODY_ZONE_L_LEG)
	right = C.get_bodypart(BODY_ZONE_R_LEG)
	update_limp()
	RegisterSignal(C, COMSIG_MOVABLE_MOVED, PROC_REF(check_step))
	RegisterSignal(C, list(COMSIG_CARBON_GAIN_WOUND, COMSIG_CARBON_LOSE_WOUND, COMSIG_CARBON_ATTACH_LIMB, COMSIG_CARBON_REMOVE_LIMB), PROC_REF(update_limp))
	return TRUE

/datum/status_effect/limp/on_remove()
	UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_CARBON_GAIN_WOUND, COMSIG_CARBON_LOSE_WOUND, COMSIG_CARBON_ATTACH_LIMB, COMSIG_CARBON_REMOVE_LIMB))

/atom/movable/screen/alert/status_effect/limp
	name = "Limping"
	desc = "One or more of your legs has been wounded, slowing down steps with that leg! Get it fixed, or at least in a sling of gauze!"

/datum/status_effect/limp/proc/check_step(mob/whocares, OldLoc, Dir, forced)
	SIGNAL_HANDLER

	if(!owner.client || owner.body_position == LYING_DOWN || (owner.movement_type & FLYING) || forced || owner.buckled)
		return
	// less limping while we have determination still
	var/determined_mod = owner.has_status_effect(STATUS_EFFECT_DETERMINED) ? 0.25 : 1

	if(next_leg == left)
		owner.client.move_delay += slowdown_left * determined_mod
		next_leg = right
	else
		owner.client.move_delay += slowdown_right * determined_mod
		next_leg = left

/datum/status_effect/limp/proc/update_limp()
	SIGNAL_HANDLER

	var/mob/living/carbon/C = owner
	left = C.get_bodypart(BODY_ZONE_L_LEG)
	right = C.get_bodypart(BODY_ZONE_R_LEG)

	if(!left && !right)
		C.remove_status_effect(src)
		return

	slowdown_left = 0
	slowdown_right = 0

	// this handles losing your leg with the limp and the other one being in good shape as well
	if(!slowdown_left && !slowdown_right)
		C.remove_status_effect(src)
		return
