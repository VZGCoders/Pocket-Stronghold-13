//nutrition
/datum/mood_event/fat
	description = "<span class='warning'><B>I'm so fat...</B></span>\n" //muh fatshaming
	mood_change = -5

/datum/mood_event/wellfed
	description = "<span class='nicegreen'>I'm stuffed!</span>\n"
	mood_change = 10

/datum/mood_event/fed
	description = "<span class='nicegreen'>I have recently had some food.</span>\n"
	mood_change = 5

/datum/mood_event/hungry
	description = "<span class='warning'>I'm getting a bit hungry.</span>\n"
	mood_change = -5

/datum/mood_event/starving
	description = "<span class='boldwarning'>I'm starving!</span>\n"
	mood_change = -15

/datum/mood_event/ate_raw_food
	description = span_red("I ate raw food.")

/datum/mood_event/ate_raw_food/severe

/datum/mood_event/ate_raw_food/mild

/datum/mood_event/ate_raw_food/meat
	description = span_red("I ate raw meat!")
	mood_change = -5
	timeout = 5 MINUTES

/datum/mood_event/ate_meal
	description = span_green("I ate a meal.")
	mood_change = 10
	timeout = 10 MINUTES

/datum/mood_event/ate_meal/decent
	description = span_green("I ate a decent meal.")
	mood_change = 15
	timeout = 20 MINUTES

/datum/mood_event/ate_meal/luxurious
	description = span_green("I ate a luxurious meal!")
	mood_change = 20
	timeout = 30 MINUTES

/datum/mood_event/ate_badfood
	description = span_red("I ate a failed food!")
	mood_change = -15
	timeout = 4 MINUTES

//charge
/datum/mood_event/supercharged
	description = "<span class='boldwarning'>I can't possibly keep all this power inside, I need to release some quick!</span>\n"
	mood_change = -10

/datum/mood_event/overcharged
	description = "<span class='warning'>I feel dangerously overcharged, perhaps I should release some power.</span>\n"
	mood_change = -4

/datum/mood_event/charged
	description = "<span class='nicegreen'>I feel the power in my veins!</span>\n"
	mood_change = 6

/datum/mood_event/lowpower
	description = "<span class='warning'>My power is running low, I should go charge up somewhere.</span>\n"
	mood_change = -6

/datum/mood_event/decharged
	description = "<span class='boldwarning'>I'm in desperate need of some electricity!</span>\n"
	mood_change = -10

//Disgust
/datum/mood_event/gross
	description = "<span class='warning'>I saw something gross.</span>\n"
	mood_change = -4

/datum/mood_event/verygross
	description = "<span class='warning'>I think I'm going to puke...</span>\n"
	mood_change = -6

/datum/mood_event/disgusted
	description = "<span class='boldwarning'>Oh god, that's disgusting...</span>\n"
	mood_change = -8

/datum/mood_event/disgust/bad_smell
	description = "<span class='warning'>I can smell something horribly decayed inside this room.</span>\n"
	mood_change = -6

/datum/mood_event/disgust/nauseating_stench
	description = "<span class='warning'>The stench of rotting carcasses is unbearable!</span>\n"
	mood_change = -12

//Generic needs events
/datum/mood_event/favorite_food
	description = "<span class='nicegreen'>I really enjoyed eating that.</span>\n"
	mood_change = 5
	timeout = 4 MINUTES

/datum/mood_event/gross_food
	description = "<span class='warning'>I really didn't like that food.</span>\n"
	mood_change = -2
	timeout = 4 MINUTES

/datum/mood_event/disgusting_food
	description = "<span class='warning'>That food was disgusting!</span>\n"
	mood_change = -6
	timeout = 4 MINUTES

/datum/mood_event/breakfast
	description = "<span class='nicegreen'>Nothing like a hearty breakfast to start the shift.</span>\n"
	mood_change = 2
	timeout = 10 MINUTES

/datum/mood_event/nice_shower
	description = "<span class='nicegreen'>I have recently had a nice shower.</span>\n"
	mood_change = 4
	timeout = 5 MINUTES

/datum/mood_event/fresh_laundry
	description = "<span class='nicegreen'>There's nothing like the feeling of a freshly laundered jumpsuit.</span>\n"
	mood_change = 2
	timeout = 10 MINUTES

//thirst
/datum/mood_event/overhydrated
	description = "<span class='warning'><B>TOO MUCH WATER...</B></span>\n"
	mood_change = -1

/datum/mood_event/hydrated
	description = "<span class='nicegreen'>I don't feel thirsty.</span>\n"
	mood_change = 4

/datum/mood_event/thirsty
	description = "<span class='warning'>I feel thirs.</span>\n"
	mood_change = -4

/datum/mood_event/dehydrated
	description = "<span class='boldwarning'>WATER!</span>\n"
	mood_change = -6
