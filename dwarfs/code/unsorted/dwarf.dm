// To make dwarven only jumpsuits, add this species' path to the clothing's species_exception list. By default jumpsuits don't fit dwarven since they're big boned
/datum/species/dwarf
	name = "Dwarf"
	id = "dwarf"
	species_traits = list(EYECOLOR, HAIR, FACEHAIR, LIPS, NO_UNDERWEAR, TRAIT_ALCOHOL_TOLERANCE)
	mutant_bodyparts = list("mcolor" = "FFF", "wings" = "None")
	use_skintones = 1
	sexes = FALSE
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_MAGIC | MIRROR_PRIDE | ERT_SPAWN | RACE_SWAP | SLIME_EXTRACT
	mutantlungs = /obj/item/organ/lungs/dwarven
	mutanttongue = /obj/item/organ/tongue/dwarven
	mutantliver = /obj/item/organ/liver/dwarven
	species_language_holder = /datum/language_holder/dwarf

/datum/species/dwarf/check_roundstart_eligible()
	return TRUE

/datum/species/dwarf/on_species_gain(mob/living/carbon/human/C, datum/species/old_species, pref_load)
	GLOB.dwarf_list += C
	. = ..()

/datum/species/dwarf/on_species_loss(mob/living/carbon/human/C, datum/species/new_species, pref_load)
	GLOB.dwarf_list -= C
	. = ..()

/datum/species/dwarf/handle_chemicals(datum/reagent/chem, mob/living/carbon/human/H)
	if(!..())
		if(istype(chem, /datum/reagent/consumable/ethanol))
			H.heal_bodypart_damage(0.5,0.5,0.5)
			return FALSE

/datum/species/dwarf/random_name(gender,unique,lastname)
	return dwarf_name()

// Dwarven tongue, they only know their language.
/obj/item/organ/tongue/dwarven
	name = "nol"
	var/static/list/dwarvenLang = typecacheof(list(/datum/language/dwarven))

/obj/item/organ/tongue/dwarven/Initialize(mapload)
	. = ..()
	languages_possible = dwarvenLang

/obj/item/organ/lungs/dwarven
	name = "dwarven lungs"
	desc = "A pair of quite small lungs. They look different than normal human's ones."

/obj/item/organ/liver/dwarven
	name = "dwarven liver"
	desc = "It looks different than normal human's ones."
	alcohol_tolerance = 0

/datum/language/dwarven
	name = "Dwarfen"
	desc = "An ancient language which is still used by some individuals."
	key = "w"
	syllables = list(
		"etag", "gekur", "tol", "gudos", "geth", "udiz", "zalud", "showeh", "ver", "zilir",
		"eshobak", "samurak", "asdobak", "fosak", "shoveth", "tangak", "dogak", "ashokak", "gethak", "slisak", "mulonak",
		"wadag", "vasag", "udosag", "longudosag", "wanag", "hivag", "wilkag",
		"asdob", "nir", "nob", "mes", "vor", "fim", "gat", "zyn", "att", "nog", "zez", "eshob", "asdob",
		"og", "get", "zal", "yd", "lok", "ad", "nat", "gat", "mit", "des", "shyg", "kul", "gat", "gad", "zis",
		"deb", "koshmot", "legon", "raz", "lanzil", "gim", "gamil", "datlad", "tat", "gelut", "gakit", "tomus", "tizot", "rirnol",
		"med", "kulet", "ngalak", "kuthdeng", "cenath", "ustos", "oshnel", "nural", "nazush"
	)
	space_chance = 35
	icon_state = "dwarf"

/datum/language_holder/dwarf
	understood_languages = list(/datum/language/dwarven = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/dwarven = list(LANGUAGE_ATOM))

/datum/outfit/dwarf
	name = "Dwarf"
	uniform = /obj/item/clothing/under/tunic/random
	belt = /obj/item/flashlight/fueled/lantern
	shoes = /obj/item/clothing/shoes/boots


/*
Below here are selectable loadouts via prefernces.
If you want them to actuely show up, go to code\modules\client\preferences.dm on line 2 and add them to the list
*/
/datum/outfit/dwarf/miner
	name = "Dwarf miner"
	back = /obj/item/pickaxe
	l_hand = /obj/item/shovel
	apply_grade = TRUE

/datum/outfit/dwarf/farmer
	name = "Dwarf farmer"
	r_hand = /obj/item/hoe
	head = /obj/item/reagent_containers/glass/bucket
	apply_grade = TRUE

/datum/outfit/dwarf/logger
	name = "Dwarf logger"
	back = /obj/item/axe
	apply_grade = TRUE

/datum/outfit/dwarf/mason
	name = "Dwarf mason"
	l_pocket = /obj/item/chisel
	r_pocket = /obj/item/trowel
	apply_grade = TRUE

/datum/outfit/dwarf/chef
	name = "Dwarf chef"
	r_hand = /obj/item/kitchen/knife
	l_hand = /obj/item/kitchen/rollingpin
	apply_grade = TRUE

/datum/outfit/dwarf/blacksmith
	name = "Dwarf blacksmith"
	uniform = /obj/item/clothing/under/smith
	r_hand = /obj/item/tongs
	l_hand = /obj/item/smithing_hammer
	apply_grade = TRUE

/datum/outfit/dwarf/builder
	name = "Dwarf builder"
	r_hand = /obj/item/builder_hammer
	l_hand = /obj/item/trowel
	apply_grade = TRUE

/datum/outfit/dwarf/king
	name = "Dwarf King"
	head = /obj/item/clothing/head/helmet/dwarf_crown
	apply_grade = TRUE
