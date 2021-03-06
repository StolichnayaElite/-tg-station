//gangtool device
//Allows gang leaders to recall the shuttle
/obj/item/device/gangtool
	name = "suspicious device"
	desc = "A strange device of sorts. Hard to really make out what it actually does just by looking."
	icon_state = "recaller"
	item_state = "walkietalkie"
	throwforce = 0
	w_class = 1.0
	throw_speed = 3
	throw_range = 7
	flags = CONDUCT
	var/gang //Which gang uses this?
	var/boss = 1 //If it has the power to promote gang members
	var/recalling = 0

/obj/item/device/gangtool/New() //Initialize supply point income if it hasn't already been started
	if(!ticker.mode.gang_points)
		ticker.mode.gang_points = new /datum/gang_points(ticker.mode)
		ticker.mode.gang_points.start()
	if(boss)
		desc += " Looks important."

/obj/item/device/gangtool/attack_self(mob/user)
	if (!can_use(user))
		return

	var/dat
	if(!gang)
		dat += "This device is not registered.<br>"
		dat += "<a href='?src=\ref[src];choice=register'>Register Device</a><br>"
	else
		var/gang_size = ((gang == "A")? (ticker.mode.A_gang.len + ticker.mode.A_bosses.len) : (ticker.mode.B_gang.len + ticker.mode.B_bosses.len))
		var/gang_territory = ((gang == "A")? ticker.mode.A_territory.len : ticker.mode.B_territory.len)
		var/points = ((gang == "A") ? ticker.mode.gang_points.A : ticker.mode.gang_points.B)

		dat += "<i>Registered as [boss ? "Administrator." : "User."]</i><br>"
		dat += "Organization: <B>[(gang == "A")?("[gang_name("A")] Gang"):("[gang_name("B")] Gang")]</B><br>"
		dat += "Organization Size: <B>[gang_size]</B><br>"
		dat += "Areas Controlled: <B>[gang_territory] ([round((gang_territory/start_state.num_territories)*100, 0.1)]% of station)</B><br>"
		dat += "<a href='?src=\ref[src];choice=recall'>Recall Emergency Shuttle</a><br>"
		dat += "<br>"
		dat += "Influence: <B>[points]</B><br>"
		dat += "Time until Influence grows: <B>[(points >= 100) ? ("--:--") : (time2text(ticker.mode.gang_points.next_point_time - world.time, "mm:ss"))]</B><br>"
		dat += "<B>Purchase Items:</B><br>"

		if(points >= 25)
			dat += "(25 Influence) <a href='?src=\ref[src];purchase=pistol'>10mm Pistol</a><br>"
		else
			dat += "(25 Influence) 10mm Pistol<br>"

		if(points >= 10)
			dat += "(10 Influence) <a href='?src=\ref[src];purchase=ammo'>10mm Ammo</a><br>"
		else
			dat += "(10 Influence) 10mm Ammo<br>"

		if(points >= 10)
			dat += "(10 Influence) <a href='?src=\ref[src];purchase=spraycan'>Territory Spraycan</a><br>"
		else
			dat += "(10 Influence) Territory Spraycan<br>"

		if(points >= 50)
			dat += "(50 Influence) <a href='?src=\ref[src];purchase=pen'>Recruitment Pen</a><br>"
		else
			dat += "(50 Influence) Recruitment Pen<br>"

		if(boss)
			if(points >= 40)
				dat += "(40 Influence) <a href='?src=\ref[src];purchase=gangtool'>Unregistered Gangtool</a><br>"
			else
				dat += "(40 Influence) Unregistered Gangtool<br>"

	dat += "<br>"
	dat += "<a href='?src=\ref[src];choice=refresh'>Refresh</a><br>"

	var/datum/browser/popup = new(user, "gangtool", "Welcome to GangTool v0.4")
	popup.set_content(dat)
	popup.open()

/obj/item/device/gangtool/Topic(href, href_list)
	if(!can_use(usr))
		return

	add_fingerprint(usr)

	if(href_list["purchase"])
		var/points = ((gang == "A") ? ticker.mode.gang_points.A : ticker.mode.gang_points.B)
		var/item_type
		switch(href_list["purchase"])
			if("pistol")
				if(points >= 25)
					item_type = /obj/item/weapon/gun/projectile/automatic/pistol
					points = 25
			if("ammo")
				if(points >= 10)
					item_type = /obj/item/ammo_box/magazine/m10mm
					points = 10
			if("spraycan")
				if(points >= 10)
					item_type = /obj/item/toy/crayon/spraycan/gang
					points = 10
			if("pen")
				if(points >= 50)
					item_type = /obj/item/weapon/pen/gang
					points = 50
			if("gangtool")
				if(points >= 40)
					item_type = /obj/item/device/gangtool/lt
					points = 40

		if(item_type)
			if(gang == "A")
				ticker.mode.gang_points.A -= points
			else if(gang == "B")
				ticker.mode.gang_points.B -= points
			var/obj/purchased = new item_type(get_turf(usr))
			var/mob/living/carbon/human/H = usr
			H.put_in_any_hand_if_possible(purchased)
			ticker.mode.message_gangtools(((gang=="A")? ticker.mode.A_tools : ticker.mode.B_tools), "A [href_list["purchase"]] was purchased by [usr] for [points] Influence.")

	else if(href_list["choice"])
		switch(href_list["choice"])
			if("recall")
				recall(usr)
			if("register")
				register_device(usr)

	attack_self(usr)

/obj/item/device/gangtool/proc/register_device(var/mob/user)
	var/promoted
	if((user.mind in ticker.mode.A_gang) || (user.mind in ticker.mode.A_bosses))
		ticker.mode.A_tools += src
		gang = "A"
		if(!(user.mind in ticker.mode.A_bosses))
			ticker.mode.remove_gangster(user.mind, 0, 2)
			ticker.mode.A_bosses += user.mind
			user.mind.special_role = "[gang_name("A")] Gang (A) Lieutenant"
			ticker.mode.update_gang_icons_added(user.mind, "A")
			log_game("[key_name(user)] has been promoted to Lieutenant in the [gang_name("A")] Gang (A)")
			promoted = 1
	else if((user.mind in ticker.mode.B_gang) || (user.mind in ticker.mode.B_bosses))
		ticker.mode.B_tools += src
		gang = "B"
		if(!(user.mind in ticker.mode.B_bosses))
			ticker.mode.remove_gangster(user.mind, 0, 2)
			ticker.mode.B_bosses += user.mind
			user.mind.special_role = "[gang_name("B")] Gang (B) Lieutenant"
			ticker.mode.update_gang_icons_added(user.mind, "B")
			log_game("[key_name(user)] has been promoted to Lieutenant in the [gang_name("B")] Gang (B)")
			promoted = 1
	if(promoted)
		ticker.mode.message_gangtools(((gang=="A")? ticker.mode.A_tools : ticker.mode.B_tools), "[user] has been promoted to Lieutenant.")
		user << "<FONT size=3 color=red><B>You have been promoted to Lieutenant!</B></FONT>"
		user << "<font color='red'>The <b>Gangtool</b> you registered will allow you to use your gang's influence to purchase items and prevent the station from evacuating before your gang can take over. Use it to recall the emergency shuttle from anywhere on the station.</font>"
		user << "<font color='red'>You may also now use recruitment pens to grow your gang membership. Use them on unsuspecting crew members to recruit them.</font>"
	if(!gang)
		usr << "<span class='warning'>ACCESS DENIED: Unauthorized user.</span>"

/obj/item/device/gangtool/proc/recall(mob/user)
	if(recalling || !can_use(user))
		return

	var/turf/userturf = get_turf(user)
	if(userturf.z != 1)
		user << "<span class='info'>\icon[src]Error: Device out of range of station communication arrays.</span>"
		return

	if(SSshuttle.emergency.mode == SHUTTLE_CALL)
		recalling = 1
		loc << "<span class='info'>\icon[src]Generating shuttle recall order with codes retrieved from last call signal...</span>"
		sleep(rand(10,30))
		loc << "<span class='info'>\icon[src]Shuttle recall order generated. Accessing station long-range communication arrays...</span>"
		sleep(rand(10,30))
		loc << "<span class='info'>\icon[src]Comm arrays accessed. Broadcasting recall signal...</span>"
		sleep(rand(10,30))
		recalling = 0
		log_game("[key_name(user)] has recalled the shuttle with a gangtool.")
		message_admins("[key_name_admin(user)] has recalled the shuttle with a gangtool.", 1)
		if(!SSshuttle.cancelEvac(user))
			loc << "<span class='info'>\icon[src]No response recieved. Emergency shuttle cannot be recalled at this time.</span>"
		return
	user << "<span class='info'>\icon[src]Emergency shuttle cannot be recalled at this time.</span>"

/obj/item/device/gangtool/proc/can_use(mob/living/carbon/human/user)
	if(!istype(user))
		return
	if(user.restrained() || user.lying || user.stat || user.stunned || user.weakened)
		return
	if(!(src in user.contents))
		return

	var/success
	if(user.mind)
		if(gang)
			if((gang == "A") && (user.mind in ticker.mode.A_bosses))
				success = 1
			else if((gang == "B") && (user.mind in ticker.mode.B_bosses))
				success = 1
		else
			success = 1
	if(success)
		return 1
	user << "<span class='warning'>\icon[src] ACCESS DENIED: Unauthorized user.</span>"
	return 0

/obj/item/device/gangtool/lt
	boss = 0