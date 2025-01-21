/datum/hud/new_player

/datum/hud/new_player/New(mob/owner)
	..()
	if (owner?.client?.interviewee)
		return
	var/list/buttons = subtypesof(/atom/movable/screen/lobby)
	for(var/button_type in buttons)
		var/atom/movable/screen/lobby/lobbyscreen = new button_type()
		lobbyscreen.SlowInit()
		lobbyscreen.hud = src
		static_inventory += lobbyscreen
		if(istype(lobbyscreen, /atom/movable/screen/lobby/button))
			var/atom/movable/screen/lobby/button/lobby_button = lobbyscreen
			lobby_button.owner = REF(owner)

/atom/movable/screen/lobby
	plane = SPLASHSCREEN_PLANE
	layer = LOBBY_BUTTON_LAYER
	screen_loc = "TOP,CENTER"

/// Run sleeping actions after initialize
/atom/movable/screen/lobby/proc/SlowInit()
	return

/atom/movable/screen/lobby/button
	///Is the button currently enabled?
	var/enabled = TRUE
	///Is the button currently being hovered over with the mouse?
	var/highlighted = FALSE
	/// The ref of the mob that owns this button. Only the owner can click on it.
	var/owner

/atom/movable/screen/lobby/button/Click(location, control, params)
	if(owner != REF(usr))
		return

	. = ..()

	if(!enabled)
		return
	flick("[base_icon_state]_pressed", src)
	update_appearance(UPDATE_ICON)
	return TRUE

/atom/movable/screen/lobby/button/MouseEntered(location,control,params)
	if(owner != REF(usr))
		return

	. = ..()
	highlighted = TRUE
	update_appearance(UPDATE_ICON)

/atom/movable/screen/lobby/button/MouseExited()
	if(owner != REF(usr))
		return

	. = ..()
	highlighted = FALSE
	update_appearance(UPDATE_ICON)

/atom/movable/screen/lobby/button/update_icon(updates)
	. = ..()
	if(!enabled)
		icon_state = "[base_icon_state]_disabled"
		return
	else if(highlighted)
		icon_state = "[base_icon_state]_highlighted"
		return
	icon_state = base_icon_state

/atom/movable/screen/lobby/button/proc/set_button_status(status)
	if(status == enabled)
		return FALSE
	enabled = status
	update_appearance(UPDATE_ICON)
	return TRUE

///Prefs menu
/atom/movable/screen/lobby/button/character_setup
	screen_loc = "EAST-4:26,TOP:-38"
	icon = 'icons/hud/lobbyv2/character_setup.dmi'
	icon_state = "character_setup"
	base_icon_state = "character_setup"

/atom/movable/screen/lobby/button/character_setup/Click(location, control, params)
	. = ..()
	if(!.)
		return

	hud.mymob.client.prefs.ShowChoices(hud.mymob)

///Button that appears before the game has started
/atom/movable/screen/lobby/button/ready
	screen_loc = "EAST-4:26,TOP:-2"
	icon = 'icons/hud/lobbyv2/ready.dmi'
	icon_state = "not_ready"
	base_icon_state = "not_ready"
	var/ready = FALSE

/atom/movable/screen/lobby/button/ready/Initialize(mapload)
	. = ..()
	switch(SSticker.current_state)
		if(GAME_STATE_PREGAME, GAME_STATE_STARTUP)
			RegisterSignal(SSticker, COMSIG_TICKER_ENTER_SETTING_UP, PROC_REF(hide_ready_button))
		if(GAME_STATE_SETTING_UP)
			set_button_status(FALSE)
			RegisterSignal(SSticker, COMSIG_TICKER_ERROR_SETTING_UP, PROC_REF(show_ready_button))
		else
			set_button_status(FALSE)

/atom/movable/screen/lobby/button/ready/proc/hide_ready_button()
	SIGNAL_HANDLER
	set_button_status(FALSE)
	UnregisterSignal(SSticker, COMSIG_TICKER_ENTER_SETTING_UP)
	RegisterSignal(SSticker, COMSIG_TICKER_ERROR_SETTING_UP, PROC_REF(show_ready_button))

/atom/movable/screen/lobby/button/ready/proc/show_ready_button()
	SIGNAL_HANDLER
	set_button_status(TRUE)
	UnregisterSignal(SSticker, COMSIG_TICKER_ERROR_SETTING_UP)
	RegisterSignal(SSticker, COMSIG_TICKER_ENTER_SETTING_UP, PROC_REF(hide_ready_button))

/atom/movable/screen/lobby/button/ready/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/mob/dead/new_player/new_player = hud.mymob
	// if(!(new_player?.client?.holder))
	// 	to_chat(hud.mymob, span_boldwarning("Disabled for testing."))
	// 	return
	ready = !ready
	if(ready)
		new_player.ready = PLAYER_READY_TO_PLAY
		base_icon_state = "ready"
	else
		new_player.ready = PLAYER_NOT_READY
		base_icon_state = "not_ready"
	update_appearance(UPDATE_ICON)

///Shown when the game has started
/atom/movable/screen/lobby/button/join
	screen_loc = "EAST-4:26,TOP:-2"
	icon = 'icons/hud/lobbyv2/join.dmi'
	icon_state = "" //Default to not visible
	base_icon_state = "join_game"
	enabled = FALSE

/atom/movable/screen/lobby/button/join/Initialize(mapload)
	. = ..()
	switch(SSticker.current_state)
		if(GAME_STATE_PREGAME, GAME_STATE_STARTUP)
			RegisterSignal(SSticker, COMSIG_TICKER_ENTER_SETTING_UP, PROC_REF(show_join_button))
		if(GAME_STATE_SETTING_UP)
			set_button_status(TRUE)
			RegisterSignal(SSticker, COMSIG_TICKER_ERROR_SETTING_UP, PROC_REF(hide_join_button))
		else
			set_button_status(TRUE)

/atom/movable/screen/lobby/button/join/Click(location, control, params)
	. = ..()
	if(!.)
		return
	if(!SSticker?.IsRoundInProgress())
		to_chat(hud.mymob, span_boldwarning("The round did not start yet or has already ended..."))
		return

	//Determines Relevent Population Cap
	var/relevant_cap
	var/hpc = CONFIG_GET(number/hard_popcap)
	var/epc = CONFIG_GET(number/extreme_popcap)
	if(hpc && epc)
		relevant_cap = min(hpc, epc)
	else
		relevant_cap = max(hpc, epc)

	var/mob/dead/new_player/new_player = hud.mymob

	if(SSticker.queued_players.len || (relevant_cap && living_player_count() >= relevant_cap && !(ckey(new_player.key) in GLOB.admin_datums)))
		to_chat(new_player, span_danger("[CONFIG_GET(string/hard_popcap_message)]"))

		var/queue_position = SSticker.queued_players.Find(new_player)
		if(queue_position == 1)
			to_chat(new_player, span_notice("You are next in line to join the game. You will be notified when a slot opens up."))
		else if(queue_position)
			to_chat(new_player, span_notice("There are [queue_position-1] players in front of you in the queue to join the game."))
		else
			SSticker.queued_players += new_player
			to_chat(new_player, span_notice("You have been added to the queue to join the game. Your position in queue is [SSticker.queued_players.len]."))
		return
	new_player.Try_Latejion()
	// if(check_whitelist(new_player?.client?.ckey) || new_player?.client?.holder)
	// 	new_player.Try_Latejion()
	// else
	// 	to_chat(hud.mymob, span_boldwarning("Disabled for testing."))
	// 	return

/atom/movable/screen/lobby/button/join/proc/show_join_button()
	SIGNAL_HANDLER
	set_button_status(TRUE)
	UnregisterSignal(SSticker, COMSIG_TICKER_ENTER_SETTING_UP)
	RegisterSignal(SSticker, COMSIG_TICKER_ERROR_SETTING_UP, PROC_REF(hide_join_button))

/atom/movable/screen/lobby/button/join/proc/hide_join_button()
	SIGNAL_HANDLER
	set_button_status(FALSE)
	UnregisterSignal(SSticker, COMSIG_TICKER_ERROR_SETTING_UP)
	RegisterSignal(SSticker, COMSIG_TICKER_ENTER_SETTING_UP, PROC_REF(show_join_button))

/atom/movable/screen/lobby/button/observe
	screen_loc = "EAST-4:26,TOP:-20"
	icon = 'icons/hud/lobbyv2/observe.dmi'
	icon_state = "observe_disabled"
	base_icon_state = "observe"
	enabled = FALSE

/atom/movable/screen/lobby/button/observe/Initialize(mapload)
	. = ..()
	if(SSticker.current_state > GAME_STATE_STARTUP)
		set_button_status(TRUE)
	else
		RegisterSignal(SSticker, COMSIG_TICKER_ENTER_PREGAME, PROC_REF(enable_observing))

/atom/movable/screen/lobby/button/observe/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/mob/dead/new_player/new_player = hud.mymob
	new_player.make_me_an_observer()
	// if(new_player?.client?.holder)
	// 	new_player.make_me_an_observer()
	// else
	// 	to_chat(hud.mymob, span_boldwarning("Disabled for testing."))

/atom/movable/screen/lobby/button/observe/proc/enable_observing()
	SIGNAL_HANDLER
	flick("[base_icon_state]_enabled", src)
	set_button_status(TRUE)
	UnregisterSignal(SSticker, COMSIG_TICKER_ENTER_PREGAME, PROC_REF(enable_observing))
