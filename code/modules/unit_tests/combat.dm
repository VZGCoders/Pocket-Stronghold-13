/datum/unit_test/harm_punch/Run()
	var/mob/living/carbon/human/puncher = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)

	// Avoid all randomness in tests
	ADD_TRAIT(puncher, TRAIT_PERFECT_ATTACKER, INNATE_TRAIT)

	puncher.a_intent_change(INTENT_HARM)
	victim.attack_hand(puncher)

	TEST_ASSERT(victim.getBruteLoss() > 0, "Victim took no brute damage after being punched")

/datum/unit_test/harm_melee/Run()
	var/mob/living/carbon/human/tider = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife)

	tider.put_in_active_hand(knife, forced = TRUE)
	tider.a_intent_change(INTENT_HARM)
	victim.attackby(knife, tider)

	TEST_ASSERT(victim.getBruteLoss() > 0, "Victim took no brute damage after being hit by a knife")
/datum/unit_test/attack_chain
	var/attack_hit
	var/post_attack_hit
	var/pre_attack_hit

/datum/unit_test/attack_chain/proc/attack_hit()
	attack_hit = TRUE

/datum/unit_test/attack_chain/proc/post_attack_hit()
	post_attack_hit = TRUE

/datum/unit_test/attack_chain/proc/pre_attack_hit()
	pre_attack_hit = TRUE

/datum/unit_test/attack_chain/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife)

	RegisterSignal(knife, COMSIG_ITEM_PRE_ATTACK, PROC_REF(pre_attack_hit))
	RegisterSignal(knife, COMSIG_ITEM_ATTACK, PROC_REF(attack_hit))
	RegisterSignal(knife, COMSIG_ITEM_AFTERATTACK, PROC_REF(post_attack_hit))

	attacker.put_in_active_hand(knife, forced = TRUE)
	attacker.a_intent_change(INTENT_HARM)
	knife.melee_attack_chain(attacker, victim)

	TEST_ASSERT(pre_attack_hit, "Pre-attack signal was not fired")
	TEST_ASSERT(attack_hit, "Attack signal was not fired")
	TEST_ASSERT(post_attack_hit, "Post-attack signal was not fired")

/datum/unit_test/disarm/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife)

	victim.put_in_active_hand(knife, forced = TRUE)
	attacker.a_intent_change(INTENT_DISARM)

	// First disarm, world should now look like:
	// Attacker --> Empty space --> Victim --> Wall
	victim.attack_hand(attacker)

	TEST_ASSERT_EQUAL(victim.loc.x, run_loc_floor_bottom_left.x + 2, "Victim wasn't moved back after being pushed")
	TEST_ASSERT(!victim.has_status_effect(STATUS_EFFECT_KNOCKDOWN), "Victim was knocked down despite not being against a wall")
	TEST_ASSERT_EQUAL(victim.get_active_held_item(), knife, "Victim dropped knife despite not being against a wall")

	attacker.forceMove(get_step(attacker, EAST))

	// Second disarm, victim was against wall and should be down
	victim.attack_hand(attacker)

	TEST_ASSERT_EQUAL(victim.loc.x, run_loc_floor_bottom_left.x + 2, "Victim was moved after being pushed against a wall")
	TEST_ASSERT(victim.has_status_effect(STATUS_EFFECT_KNOCKDOWN), "Victim was not knocked down after being pushed against a wall")
	TEST_ASSERT_EQUAL(victim.get_active_held_item(), null, "Victim didn't drop knife after being pushed against a wall")
