/datum/component/attack_toggle
	//list of attack types with assigned damage
	var/list/attacks
	var/list/damages
	var/list/attack_cooldowns
	var/list/attack_verbs_simple
	var/list/attack_verbs_continuous
	var/current_atck_index = 1

/datum/component/attack_toggle/Initialize(attacks, damages, cooldowns, attack_verbs_simple, attack_verbs_continuous)
	src.attacks = attacks
	src.damages = damages
	src.attack_cooldowns = cooldowns
	src.attack_verbs_simple = attack_verbs_simple
	src.attack_verbs_continuous = attack_verbs_continuous

	var/obj/item/P = parent
	P.atck_type = attacks[current_atck_index]
	P.force = damages[current_atck_index]
	P.attack_verb_simple = attack_verbs_simple[current_atck_index]
	P.attack_verb_continuous = attack_verbs_continuous[current_atck_index]

	P.attach_action(/datum/action/toggle_attack)

	RegisterSignal(parent, COMSIG_ITEM_AFTERATTACK, PROC_REF(afterattack))

/datum/component/attack_toggle/proc/toggle_attack(mob/user)
	if(current_atck_index == attacks.len)
		current_atck_index = 1
	else
		current_atck_index++
	var/obj/item/P = parent
	P.atck_type = attacks[current_atck_index]
	P.force = damages[current_atck_index]
	P.attack_verb_simple = attack_verbs_simple[current_atck_index]
	P.attack_verb_continuous = attack_verbs_continuous[current_atck_index]
	to_chat(user, span_notice("You will now [attacks[current_atck_index]]."))

/datum/component/attack_toggle/proc/afterattack(atom/source, atom/target, mob/user, proximity)
	SIGNAL_HANDLER
	if(!proximity)
		return
	user.changeNext_move(attack_cooldowns[current_atck_index])
