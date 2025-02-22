//DO NOT ADD MECHA PARTS TO THE GAME WITH THE DEFAULT "SPRITE ME" SPRITE!
//I'm annoyed I even have to tell you this! SPRITE FIRST, then commit.

/obj/item/mecha_parts/mecha_equipment
	name = "mecha equipment"
	icon = 'icons/obj/mecha/mecha_equipment.dmi'
	icon_state = "mecha_equip"
	force = 5
	origin_tech = "materials=2;engineering=2"
	max_integrity = 300
	var/equip_cooldown = 0
	var/equip_ready = 1
	var/energy_drain = 0
	var/obj/mecha/chassis = null
	var/range = MECHA_MELEE //bitflags
	var/salvageable = 1
	var/selectable = 1	// Set to 0 for passive equipment such as mining scanner or armor plates
	var/harmful = FALSE //Controls if equipment can be used to attack by a pacifist.


/obj/item/mecha_parts/mecha_equipment/proc/update_chassis_page()
	if(chassis)
		send_byjax(chassis.occupant,"exosuit.browser","eq_list",chassis.get_equipment_list())
		send_byjax(chassis.occupant,"exosuit.browser","equipment_menu",chassis.get_equipment_menu(),"dropdowns")
		return 1
	return

/obj/item/mecha_parts/mecha_equipment/proc/update_equip_info()
	if(chassis)
		send_byjax(chassis.occupant,"exosuit.browser","\ref[src]",get_equip_info())
		return 1
	return

/obj/item/mecha_parts/mecha_equipment/Destroy()//missiles detonating, teleporter creating singularity?
	if(chassis)
		chassis.occupant_message("<span class='danger'>[src] уничтожен!</span>")
		chassis.log_append_to_last("[src] уничтожен.",1)
		if(istype(src, /obj/item/mecha_parts/mecha_equipment/weapon))
			chassis.occupant << sound(chassis.weapdestrsound, volume = 50)
		else
			chassis.occupant << sound(chassis.critdestrsound, volume = 50)
		detach(chassis)
	return ..()

/obj/item/mecha_parts/mecha_equipment/proc/critfail()
	if(chassis)
		log_message("Critical failure", 1)
	return

/obj/item/mecha_parts/mecha_equipment/proc/get_equip_info()
	if(!chassis)
		return
	var/txt = "<span style=\"color:[equip_ready?"#0f0":"#f00"];\">*</span>&nbsp;"
	if(chassis.selected == src)
		txt += "<b>[name]</b>"
	else if(selectable)
		txt += "<a href='?src=[chassis.UID()];select_equip=\ref[src]'>[name]</a>"
	else
		txt += "[name]"

	return txt

/obj/item/mecha_parts/mecha_equipment/proc/is_ranged()//add a distance restricted equipment. Why not?
	return range & MECHA_RANGED

/obj/item/mecha_parts/mecha_equipment/proc/is_melee()
	return range & MECHA_MELEE

/obj/item/mecha_parts/mecha_equipment/proc/action_checks(atom/target)
	if(!target)
		return 0
	if(!chassis)
		return 0
	if(!equip_ready)
		return 0
	if(crit_fail)
		return 0
	if(energy_drain && !chassis.has_charge(energy_drain))
		return 0
	return 1

/**
 * Proc that checks if the target of the mecha is in front of it
 *
 * Arguments
 * * target - target we want to check
 */
/obj/item/mecha_parts/mecha_equipment/proc/is_faced_target(atom/target)
	if(!chassis || !target)
		return FALSE
	var/dir_to_target = get_dir(chassis, target)
	return dir_to_target == chassis.dir || dir_to_target == get_clockwise_dir(chassis.dir) || dir_to_target == get_anticlockwise_dir(chassis.dir)

/obj/item/mecha_parts/mecha_equipment/proc/action(atom/target)
	return 0

/obj/item/mecha_parts/mecha_equipment/proc/start_cooldown()
	set_ready_state(0)
	chassis.use_power(energy_drain)

	var/cooldown = equip_cooldown
	var/obj/item/mecha_parts/mecha_equipment/weapon/W = src
	if(istype(W))
		cooldown += (W.projectiles_per_shot - 1) * W.projectile_delay

	addtimer(CALLBACK(src, .proc/set_ready_state, 1), cooldown)

/obj/item/mecha_parts/mecha_equipment/proc/do_after_cooldown(atom/target)
	if(!chassis)
		return
	var/C = chassis.loc
	set_ready_state(0)
	chassis.use_power(energy_drain)
	. = do_after(chassis.occupant, equip_cooldown, needhand = FALSE, target = target)
	set_ready_state(1)
	if(!chassis || 	chassis.loc != C || src != chassis.selected || !(get_dir(chassis, target) & chassis.dir))
		return FALSE

/obj/item/mecha_parts/mecha_equipment/proc/do_after_mecha(atom/target, delay)
	if(!chassis)
		return
	var/C = chassis.loc
	. = do_after(chassis.occupant, delay, target = target)
	if(!chassis || 	chassis.loc != C || src != chassis.selected || !(get_dir(chassis, target) & chassis.dir))
		return FALSE

/obj/item/mecha_parts/mecha_equipment/proc/can_attach(obj/mecha/M)
	if(istype(M))
		if(M.equipment.len<M.max_equip)
			return 1
	return 0

/obj/item/mecha_parts/mecha_equipment/proc/attach(obj/mecha/M)
	M.equipment += src
	chassis = M
	loc = M
	M.log_message("[src] активирован.")
	if(!M.selected)
		M.selected = src
	update_chassis_page()

/obj/item/mecha_parts/mecha_equipment/proc/detach(atom/moveto = null)
	moveto = moveto || get_turf(chassis)
	if(Move(moveto))
		chassis.equipment -= src
		if(chassis.selected == src)
			chassis.selected = null
		update_chassis_page()
		chassis.log_message("[src] убран из снаряжения.")
		chassis = null
		set_ready_state(1)


/obj/item/mecha_parts/mecha_equipment/Topic(href,href_list)
	if(href_list["detach"])
		detach()


/obj/item/mecha_parts/mecha_equipment/proc/set_ready_state(state)
	equip_ready = state
	if(chassis)
		send_byjax(chassis.occupant,"exosuit.browser","\ref[src]",src.get_equip_info())

/obj/item/mecha_parts/mecha_equipment/proc/occupant_message(message)
	if(chassis)
		chassis.occupant_message("[bicon(src)] [message]")

/obj/item/mecha_parts/mecha_equipment/proc/log_message(message)
	if(chassis)
		chassis.log_message("<i>[src]:</i> [message]")
