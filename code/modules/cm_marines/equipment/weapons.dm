

/obj/item/storage/box/m56_system
	name = "\improper M56 smartgun system"
	desc = "A large case containing the full M56 Smartgun System. Drag this sprite into you to open it up!\nNOTE: You cannot put items back inside this case."
	icon = 'icons/Marine/marine-weapons.dmi'
	icon_state = "smartgun_case"
	w_class = 5
	storage_slots = 4
	slowdown = 1
	can_hold = list() //Nada. Once you take the stuff out it doesn't fit back in.
	foldable = null

	open(var/mob/user as mob)
		if(!opened)
			new /obj/item/clothing/glasses/night/m56_goggles(src)
			new /obj/item/weapon/gun/smartgun(src)
			new /obj/item/smartgun_powerpack(src)
			new /obj/item/clothing/suit/storage/marine/smartgunner(src)
		..()

/obj/item/smartgun_powerpack
	name = "\improper M56 powerpack"
	desc = "A heavy reinforced backpack with support equipment, power cells, and spare rounds for the M56 Smartgun System.\nClick the icon in the top left to reload your M56."
	icon = 'icons/obj/items/storage/storage.dmi'
	icon_state = "powerpack"
	flags_atom = FPRINT|CONDUCT
	flags_equip_slot = SLOT_BACK
	w_class = 5.0
	var/obj/item/cell/pcell = null
	var/rounds_remaining = 500
	actions_types = list(/datum/action/item_action/toggle)
	var/reloading = 0

/obj/item/smartgun_powerpack/New()
	select_gamemode_skin(/obj/item/smartgun_powerpack)
	..()
	pcell = new /obj/item/cell(src)

/obj/item/smartgun_powerpack/dropped(mob/living/user) // called on unequip
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.glasses && istype(H.glasses, /obj/item/clothing/glasses/night/m56_goggles))
			if(H.back == src)
				H << "<span class='notice'>You remove \the [H.glasses].</span>"
				H.drop_inv_item_on_ground(H.glasses)
	..()

/obj/item/smartgun_powerpack/attack_self(mob/user)
	if(!ishuman(user) || user.stat) return 0

	var/obj/item/weapon/gun/smartgun/mygun = user.get_active_hand()

	if(isnull(mygun) || !mygun || !istype(mygun))
		user << "You must be holding an M56 Smartgun to begin the reload process."
		return
	if(rounds_remaining < 1)
		user << "Your powerpack is completely devoid of spare ammo belts! Looks like you're up shit creek, maggot!"
		return
	if(!pcell)
		user << "Your powerpack doesn't have a battery! Slap one in there!"
		return

	mygun.shells_fired_now = 0 //If you attempt a reload, the shells reset. Also prevents double reload if you fire off another 20 bullets while it's loading.

	if(reloading)
		return
	if(pcell.charge <= 50)
		user << "Your powerpack's battery is too drained! Get a new battery and install it!"
		return

	reloading = 1
	user.visible_message("[user.name] begin feeding an ammo belt into the M56 Smartgun.","You begin feeding a fresh ammo belt into the M56 Smartgun. Don't move or you'll be interrupted.")
	var/reload_duration = 50
	if(user.mind && user.mind.cm_skills && user.mind.cm_skills.smartgun>0)
		reload_duration = max(reload_duration - 10*user.mind.cm_skills.smartgun,30)
	if(do_after(user,reload_duration, TRUE, 5, BUSY_ICON_FRIENDLY))
		pcell.charge -= 50
		if(!mygun.current_mag) //This shouldn't happen, since the mag can't be ejected. Good safety, I guess.
			var/obj/item/ammo_magazine/internal/smartgun/A = new(mygun)
			mygun.current_mag = A

		var/rounds_to_reload = min(rounds_remaining, (mygun.current_mag.max_rounds - mygun.current_mag.current_rounds)) //Get the smaller value.

		mygun.current_mag.current_rounds += rounds_to_reload
		rounds_remaining -= rounds_to_reload

		user << "You finish loading [rounds_to_reload] shells into the M56 Smartgun. Ready to rumble!"
		playsound(user, 'sound/weapons/unload.ogg', 25, 1)

		reloading = 0
		return 1
	else
		user << "Your reloading was interrupted!"
		reloading = 0
		return
	return 1

/obj/item/smartgun_powerpack/attackby(var/obj/item/A as obj, mob/user as mob)
	if(istype(A,/obj/item/cell))
		var/obj/item/cell/C = A
		visible_message("[user.name] swaps out the power cell in the [src.name].","You swap out the power cell in the [src] and drop the old one.")
		user << "The new cell contains: [C.charge] power."
		pcell.loc = get_turf(user)
		pcell = C
		C.loc = src
		playsound(src,'sound/machines/click.ogg', 25, 1)
	else
		..()

/obj/item/smartgun_powerpack/examine(mob/user)
	..()
	if (get_dist(user, src) <= 1)
		if(pcell)
			user << "A small gauge in the corner reads: Ammo: [rounds_remaining] / 500."

/obj/item/smartgun_powerpack/snow
	icon_state = "s_powerpack"

/obj/item/smartgun_powerpack/fancy
	icon_state = "powerpackw"

/obj/item/smartgun_powerpack/merc
	icon_state = "powerpackp"
