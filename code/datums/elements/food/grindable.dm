/datum/component/grindable
	//What we get after grinding something in a quern
	var/datum/reagent/grindable_liquid_type
	//How much of this liquid do we get?
	var/liquid_amount
	//If we convert grains to flour
	var/liquid_ratio

/datum/component/grindable/Initialize(grindable_liquid_type, liquid_amount = 10, liquid_ratio)

	src.grindable_liquid_type = grindable_liquid_type
	src.liquid_amount = liquid_amount
	src.liquid_ratio = liquid_ratio

	RegisterSignal(parent, COSMIG_ITEM_GRINDED, PROC_REF(grind_item))
	RegisterSignal(parent, COSMIG_REAGENT_GRINDED, PROC_REF(grind_reagent))

/datum/component/grindable/proc/grind_item(obj/item/growable/source, obj/structure/quern/Q)
	SIGNAL_HANDLER
	Q.reagents.add_reagent(grindable_liquid_type, liquid_amount)
	qdel(parent)

/datum/component/grindable/proc/grind_reagent(datum/reagent/source, obj/structure/quern/Q)
	SIGNAL_HANDLER
	var/vol = liquid_amount
	if(source.volume < liquid_amount)
		vol = source.volume
	Q.reagents.remove_reagent(source.type, vol)
	Q.reagents.add_reagent(grindable_liquid_type, vol*liquid_ratio)
