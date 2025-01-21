//Component for reagent to be transformed into another when placed in a demijohn
/datum/component/fermentable
	var/datum/reagent/ferment_from
	var/datum/reagent/ferment_into
	var/ferment_ratio
	var/ferment_amt
	var/ferment_delta
	var/timerid

/datum/component/fermentable/Initialize(ferment_from, ferment_into, ferment_amt=10, ferment_ratio = 1, ferment_delta = 5 SECONDS)
	src.ferment_from = ferment_from
	src.ferment_into = ferment_into
	src.ferment_amt = ferment_amt
	src.ferment_ratio = ferment_ratio
	src.ferment_delta = ferment_delta

	RegisterSignal(parent, COSMIG_REAGENT_START_FERMENTING, PROC_REF(start_fermenting))
	RegisterSignal(parent, COSMIG_REAGENT_STOP_FERMENTING, PROC_REF(stop_fermenting))

/datum/component/fermentable/Destroy(force, silent)
	. = ..()
	remove_timer()
	UnregisterSignal(parent, list(COSMIG_REAGENT_START_FERMENTING, COSMIG_REAGENT_STOP_FERMENTING))

/datum/component/fermentable/proc/start_fermenting(datum/reagent/source_reagent, obj/structure/demijohn/D)
	SIGNAL_HANDLER
	if(ferment_from && D.reagents.has_reagent(ferment_from))
		return
	timerid = addtimer(CALLBACK(src, PROC_REF(ferment), source_reagent, D), ferment_delta, TIMER_STOPPABLE)

/datum/component/fermentable/proc/stop_fermenting(datum/reagent/source_reagent, obj/structure/demijohn/D)
	remove_timer()

/datum/component/fermentable/proc/ferment(datum/reagent/source_reagent, obj/structure/demijohn/D)
	var/vol = ferment_amt
	if(source_reagent.volume < vol)
		vol = source_reagent.volume
	var/to_conv = vol * ferment_ratio
	D.reagents.remove_reagent(source_reagent.type, vol)
	D.reagents.add_reagent(ferment_into, to_conv)
	if(D.reagents.has_reagent(source_reagent.type))
		start_fermenting(source_reagent, D)
	else
		SEND_SIGNAL(D, COSMIG_DEMIJOHN_STOP)

/datum/component/fermentable/proc/remove_timer()
	if(active_timers)
		deltimer(timerid)
