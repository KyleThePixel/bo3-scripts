// ============================================================
//  PAPGUM v1 - BO3 Zombies custom GobbleGum effect
// ------------------------------------------------------------
//  Replaces the BULLET BOOST GobbleGum's effect with:
//
//    Pop it while holding a normal gun
//        -> that gun is Pack-a-Punched, permanently,
//           in place, with full ammo and a random AAT.
//
//    Pop it while holding a Pack-a-Punched gun
//        -> its Alternate Ammo Type is re-rolled
//           (guaranteed different from the current one).
//
//  The gum still LOOKS like Bullet Boost (name/icon come from
//  the game's assets and can't change in a script-only mod),
//  keeps Bullet Boost's 2 activations per gum, and works for
//  every player in the match, not just the host.
//
//  Host-only script for the ezz boiii client: drop this file
//  into boiii\custom_scripts (boiii compiles and loads it at
//  startup). Works on all stock maps.
//
//  Built against the stock BO3 script sources:
//   - bgb activation/validation are invoked through
//     level.bgb[ name ].activation_func / .validation_func
//     (scripts/zm/_zm_bgb.gsc), so this mod just swaps those
//     two function pointers on the Bullet Boost entry.
//   - The upgrade path mirrors the Pack-a-Punch machine
//     (scripts/zm/_zm_pack_a_punch.gsc): weapon_give() the
//     upgrade, then aat::acquire() for its first AAT.
//   - aat::acquire() with no name picks a random AAT and
//     excludes the currently assigned one (scripts/shared/
//     aat_shared.gsc), which is what makes the re-roll a
//     guaranteed change.
// ============================================================

#using scripts\shared\aat_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\util_shared;
#using scripts\zm\_zm_weapons;

#namespace papgum;

// ---------------- entry ----------------

// NOTE: boiii's custom_scripts loader runs a script's autoexec
// functions when it loads the file - it never calls main().
// This MUST stay an autoexec or the mod silently does nothing.
function autoexec main()
{
    // re-inject safe: don't double-register
    if ( isDefined( level.papgum_enabled ) && level.papgum_enabled )
        return;

    level.papgum_enabled = true;

    level thread papgum_patch_watcher();

    IPrintLnBold( "^3PAP GUM^7 loaded: Bullet Boost now Pack-a-Punches your current gun." );
}

// Bullet Boost registers itself during map init, which happens
// after a lobby injection - and re-registers on every new map.
// So instead of patching once, a watcher re-applies the patch
// whenever the stock registration is (back) in place. The patch
// lands within 0.25s of registration, long before anyone can
// reach a GobbleGum machine.
function papgum_patch_watcher()
{
    for ( ;; )
    {
        if ( isDefined( level.bgb ) && isDefined( level.bgb[ "zm_bgb_bullet_boost" ] ) )
        {
            level.bgb[ "zm_bgb_bullet_boost" ].activation_func = &papgum_activation;
            level.bgb[ "zm_bgb_bullet_boost" ].validation_func = &papgum_validation;
        }

        wait 0.25;
    }
}

// ---------------- the gum ----------------

// Runs (on the player) when they try to pop the gum. Returning
// false means the gum won't activate or be consumed.
function papgum_validation()
{
    if ( self laststand::player_is_in_laststand() )
        return false;

    if ( isDefined( self.intermission ) && self.intermission )
        return false;

    if ( self isSwitchingWeapons() || self isThrowingGrenade() )
        return false;

    weapon = self GetCurrentWeapon();

    if ( weapon == level.weaponNone || weapon == level.weaponZMFists )
        return false;

    // Already Pack-a-Punched: only useful if an AAT re-roll is
    // possible on this weapon (AAT-exempt wonder weapons block).
    if ( zm_weapons::is_weapon_upgraded( weapon ) )
        return zm_weapons::weapon_supports_aat( weapon );

    // Not Pack-a-Punched: needs an upgrade path.
    return zm_weapons::can_upgrade_weapon( weapon );
}

// Runs (on the player) when the gum is popped. One of Bullet
// Boost's 2 activations is consumed by the bgb system itself.
function papgum_activation()
{
    self endon( "death" );
    self endon( "disconnect" );

    self PlaySoundToPlayer( "zmb_bgb_bullet_boost", self );
    self util::waittill_any_timeout( 1, "weapon_change_complete", "death", "disconnect" );

    weapon = self GetCurrentWeapon();
    weapon = self zm_weapons::switch_from_alt_weapon( weapon );

    if ( weapon == level.weaponNone )
        return;

    // ---- already Pack-a-Punched: re-roll the AAT ----
    if ( zm_weapons::is_weapon_upgraded( weapon ) )
    {
        if ( zm_weapons::weapon_supports_aat( weapon ) )
            self aat::acquire( weapon );

        return;
    }

    // ---- not Pack-a-Punched: upgrade it in place ----
    if ( !zm_weapons::can_upgrade_weapon( weapon ) )
        return;

    upgrade_weapon = zm_weapons::get_upgrade_weapon( weapon );

    self TakeWeapon( weapon );
    upgrade_weapon = self zm_weapons::weapon_give( upgrade_weapon, 1 );
    self GiveMaxAmmo( upgrade_weapon );
    self notify( "weapon_give", upgrade_weapon );

    // Same as the real machine: a fresh Pack-a-Punch gets a
    // random AAT (or has any stale AAT state cleared if the
    // weapon can't hold one).
    if ( zm_weapons::weapon_supports_aat( upgrade_weapon ) )
        self thread aat::acquire( upgrade_weapon );
    else
        self thread aat::remove( upgrade_weapon );
}
