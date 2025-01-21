/datum/component/pressable
	//What we get after pressing something under a press
	var/datum/reagent/pressable_liquid_type
	//How much of this liquid do we get?
	var/liquid_amount

/datum/component/pressable/Initialize(pressable_liquid_type, liquid_amount = 10)

	src.pressable_liquid_type = pressable_liquid_type
	src.liquid_amount = liquid_amount

	RegisterSignal(parent, COSMIG_ITEM_SQUEEZED, PROC_REF(squeeze))

/datum/component/pressable/proc/squeeze(obj/item/growable/G, obj/structure/press/P, amt_types = 1)
	SIGNAL_HANDLER
	if(amt_types <= 1)
		P.reagents.add_reagent(pressable_liquid_type, liquid_amount)
	else
		P.reagents.add_reagent(/datum/reagent/blood, liquid_amount)
	qdel(parent)
