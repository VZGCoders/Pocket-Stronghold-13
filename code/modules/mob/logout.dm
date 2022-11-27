/mob/Logout()

	remove_typing_indicator()

	SEND_SIGNAL(src, COMSIG_MOB_LOGOUT)
	log_message("[key_name(src)] is no longer owning mob [src]([src.type])", LOG_OWNERSHIP)
	webhook_send_logout("[key_name(src)]")
	SStgui.on_logout(src)
	remove_from_player_list()
	clear_client_in_contents()
	..()

	if(loc)
		loc.on_log(FALSE)

	if(client)
		for(var/foo in client.player_details.post_logout_callbacks)
			var/datum/callback/CB = foo
			CB.Invoke()

	return TRUE
