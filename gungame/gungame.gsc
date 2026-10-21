// ============================================================
//  GUNGAME v1 - BO3 Zombies co-op gun game (conditions ladder)
// ------------------------------------------------------------
//  Host-only script for the ezz boiii client: drop this file
//  into boiii\custom_scripts (boiii compiles and loads it at
//  startup). Works on all stock maps. 2-4 players (solo works too).
//
//  How it plays:
//   - Every player climbs their own 20-weapon ladder.
//   - Each tier pairs a weapon with a CONDITION (kills,
//     headshots, melee, clean streaks, frenzies, grenades).
//   - Only kills made with your CURRENT ladder weapon count.
//   - Downed = drop one tier. Reviving a teammate = +1 progress.
//   - Tier 20 is the Bowie Knife: first knife kill wins.
//   - Box / wallbuys / PaP are neutralized: anything that isn't
//     your ladder weapon gets taken away within ~2 seconds.
// ============================================================

#using scripts\zm\_zm;
#using scripts\zm\_zm_spawner;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;

#namespace gungame;

// ---------------- entry ----------------

// NOTE: boiii's custom_scripts loader runs a script's autoexec
// functions when it loads the file - it never calls main().
// This MUST stay an autoexec or the mod silently does nothing.
function autoexec main()
{
    // re-inject safe: don't double-register
    if ( isDefined( level.gg_enabled ) && level.gg_enabled )
        return;

    level.gg_enabled = true;
    level.gg_victory = false;
    level.gg_victory_player = undefined;

    gg_build_ladder();

    level thread gg_register_hooks();
    level thread gg_watch_connections();

    // anyone already connected (late inject)
    if ( isDefined( level.players ) )
    {
        foreach ( player in level.players )
        {
            if ( isDefined( player ) )
                player thread gg_player_setup();
        }
    }

    IPrintLnBold( "^3GUN GAME^7 loaded: 20 tiers, knife finale. Good luck." );
}

// ---------------- the ladder ----------------
// cond: kills | headshot | melee | clean | frenzy | grenade | knife

function gg_build_ladder()
{
    level.gg_ladder = [];
    gg_add_tier( "pistol_standard",  "MR6",         1, "kills"    );
    gg_add_tier( "smg_standard",     "Kuda",        1, "kills"    );
    gg_add_tier( "pistol_burst",     "RK5",         2, "kills"    );
    gg_add_tier( "shotgun_pump",     "KRM-262",     2, "kills"    );
    gg_add_tier( "smg_fastfire",     "Vesper",      2, "headshot" );
    gg_add_tier( "ar_standard",      "KN-44",       3, "kills"    );
    gg_add_tier( "shotgun_fullauto", "Haymaker 12", 3, "melee"    );
    gg_add_tier( "ar_longburst",     "M8A7",        3, "headshot" );
    gg_add_tier( "lmg_cqb",          "Dingo",       4, "kills"    );
    gg_add_tier( "sniper_fastbolt",  "Locus",       4, "headshot" );
    gg_add_tier( "ar_cqb",           "HVK-30",      4, "clean"    );
    gg_add_tier( "shotgun_precision","Argus",       5, "kills"    );
    gg_add_tier( "lmg_light",        "BRM",         5, "frenzy"   );
    gg_add_tier( "sniper_powerbolt", "SVG-100",     5, "headshot" );
    gg_add_tier( "ar_accurate",      "ICR-1",       6, "clean"    );
    gg_add_tier( "lmg_slowfire",     "Gorgon",      6, "kills"    );
    gg_add_tier( "sniper_fastsemi",  "Drakon",      6, "grenade"  );
    gg_add_tier( "ar_fastburst",     "XR-2",        7, "frenzy"   );
    gg_add_tier( "launcher_standard","XM-53",       7, "kills"    );
    gg_add_tier( "bowie_knife",      "Bowie Knife", 1, "knife"    );
}

function gg_add_tier( weaponName, displayName, quota, cond )
{
    t = spawnStruct();
    t.weapon  = weaponName;
    t.display = displayName;
    t.quota   = quota;
    t.cond    = cond;
    level.gg_ladder[ level.gg_ladder.size ] = t;
}

function gg_cond_label( cond )
{
    if ( cond == "kills" )    return "KILLS";
    if ( cond == "headshot" ) return "HEADSHOTS";
    if ( cond == "melee" )    return "MELEE KILLS";
    if ( cond == "clean" )    return "CLEAN KILLS - DON'T GET HIT";
    if ( cond == "frenzy" )   return "FRENZY - KILLS WITHIN 6 SEC";
    if ( cond == "grenade" )  return "GRENADE KILLS";
    if ( cond == "knife" )    return "KNIFE KILL TO WIN";
    return "KILLS";
}

// ---------------- hook registration ----------------

function gg_register_hooks()
{
    // stock systems may not be up yet when injected in the lobby
    while ( !isDefined( level.zombie_death_event_callbacks ) )
        wait 0.5;
    zm_spawner::register_zombie_death_event_callback( &gungame::gg_on_zombie_death );

    while ( !isDefined( level.player_damage_callbacks ) )
        wait 0.5;
    zm::register_player_damage_callback( &gungame::gg_on_player_damaged );
}

function gg_watch_connections()
{
    for ( ;; )
    {
        level waittill( "connected", player );
        player thread gg_player_setup();
    }
}

function gg_player_setup()
{
    self endon( "disconnect" );
    self.gg_tier         = 0;
    self.gg_progress     = 0;
    self.gg_clean        = true;
    self.gg_frenzy_times = [];
    self.gg_downed       = false;
    self thread gg_spawn_watcher();
    self thread gg_downed_watcher();
    self thread gg_revive_watcher();
    self thread gg_enforce_loop();
}

// ---------------- kill credit ----------------
// self = the dead zombie. attacker = killing player (may be undefined).

function gg_on_zombie_death( attacker )
{
    if ( !isDefined( level.gg_enabled ) || !level.gg_enabled || level.gg_victory )
        return;
    if ( !isDefined( attacker ) || !isPlayer( attacker ) )
        return;
    if ( !isDefined( attacker.gg_tier ) )
        return;

    tier = level.gg_ladder[ attacker.gg_tier ];
    mod = self.damagemod;
    wname = "";
    if ( isDefined( self.damageweapon ) )
        wname = self.damageweapon.name;

    if ( tier.cond == "knife" )
    {
        if ( mod == "MOD_MELEE" )
            gg_win( attacker );
        return;
    }

    if ( tier.cond == "kills" )
    {
        if ( wname == tier.weapon && mod != "MOD_MELEE" )
            gg_add_progress( attacker, 1 );
    }
    else if ( tier.cond == "headshot" )
    {
        if ( wname == tier.weapon && gg_is_headshot( self ) )
            gg_add_progress( attacker, 1 );
    }
    else if ( tier.cond == "melee" )
    {
        if ( mod == "MOD_MELEE" )
            gg_add_progress( attacker, 1 );
    }
    else if ( tier.cond == "clean" )
    {
        if ( wname == tier.weapon && mod != "MOD_MELEE" && attacker.gg_clean )
            gg_add_progress( attacker, 1 );
    }
    else if ( tier.cond == "frenzy" )
    {
        if ( wname == tier.weapon && mod != "MOD_MELEE" )
            gg_frenzy_kill( attacker, tier );
    }
    else if ( tier.cond == "grenade" )
    {
        if ( mod == "MOD_GRENADE" || mod == "MOD_GRENADE_SPLASH" || mod == "MOD_EXPLOSIVE" )
            gg_add_progress( attacker, 1 );
    }
}

// zombie = the dead zombie entity
function gg_is_headshot( zombie )
{
    if ( zombie.damagemod == "MOD_HEAD_SHOT" )
        return true;
    if ( isDefined( zombie.damageweapon ) && isDefined( zombie.damagelocation ) )
        return zm_utility::is_headshot( zombie.damageweapon, zombie.damagelocation, zombie.damagemod );
    return false;
}

function gg_frenzy_kill( player, tier )
{
    now = GetTime();
    window = [];
    foreach ( t in player.gg_frenzy_times )
    {
        if ( now - t <= 6000 )
            window[ window.size ] = t;
    }
    window[ window.size ] = now;
    player.gg_frenzy_times = window;
    player.gg_progress = window.size;
    if ( window.size >= tier.quota )
        gg_tier_up( player );
    else
        gg_hud_update( player );
}

// self = damaged player. MUST return -1 so damage passes through untouched.
function gg_on_player_damaged( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, psOffsetTime )
{
    if ( isDefined( self.gg_tier ) )
        self.gg_clean = false;
    return -1;
}

// ---------------- tier changes ----------------

function gg_add_progress( player, n )
{
    tier = level.gg_ladder[ player.gg_tier ];
    player.gg_progress += n;
    if ( player.gg_progress >= tier.quota )
        gg_tier_up( player );
    else
        gg_hud_update( player );
}

function gg_tier_up( player )
{
    player.gg_tier++;
    player.gg_progress = 0;
    player.gg_clean = true;
    player.gg_frenzy_times = [];
    gg_give_tier_weapon( player );
    tier = level.gg_ladder[ player.gg_tier ];
    IPrintLnBold( player.name + " ^2TIER UP^7: " + tier.display + " (" + ( player.gg_tier + 1 ) + "/20) - " + gg_cond_label( tier.cond ) );
    gg_hud_update( player );
    gg_board_update();
}

function gg_tier_down( player )
{
    if ( player.gg_tier > 0 )
        player.gg_tier--;
    player.gg_progress = 0;
    player.gg_clean = true;
    player.gg_frenzy_times = [];
    tier = level.gg_ladder[ player.gg_tier ];
    IPrintLn( player.name + " ^1DOWNED^7 - dropped to tier " + ( player.gg_tier + 1 ) + "/20: " + tier.display );
    gg_hud_update( player );
    gg_board_update();
}

function gg_win( player )
{
    level.gg_victory = true;
    level.gg_victory_player = player;
    IPrintLnBold( "^3" + player.name + " WINS THE GUN GAME!^7" );
    IPrintLn( "Victory lap: unlimited ammo for everyone until the game ends." );
    gg_board_update();
}

// Strip everything that isn't the ladder weapon, then hand it out fresh.
function gg_give_tier_weapon( player )
{
    tier = level.gg_ladder[ player.gg_tier ];
    w = GetWeapon( tier.weapon );

    primaries = player GetWeaponsListPrimaries();
    foreach ( pw in primaries )
        player zm_weapons::weapon_take( pw );

    if ( tier.weapon == "bowie_knife" )
        player giveWeapon( w );
    else if ( !player HasWeapon( w ) )
        player zm_weapons::weapon_give( w );

    player GiveMaxAmmo( w );
    player SwitchToWeapon( w );
}

// ---------------- watchers (per player) ----------------

function gg_spawn_watcher()
{
    self endon( "disconnect" );
    for ( ;; )
    {
        self waittill( "spawned_player" );
        wait 1; // let the stock loadout settle first
        if ( level.gg_victory )
            continue;
        self.gg_downed = false;
        gg_hud_create( self );
        gg_give_tier_weapon( self );
        gg_board_update();
    }
}

function gg_downed_watcher()
{
    self endon( "disconnect" );
    for ( ;; )
    {
        self waittill( "player_downed" );
        self.gg_downed = true;
        if ( !level.gg_victory && isDefined( self.gg_tier ) )
            gg_tier_down( self );
    }
}

function gg_revive_watcher()
{
    self endon( "disconnect" );
    self thread gg_revive_reward_watcher();
    for ( ;; )
    {
        self waittill( "player_revived" );
        self.gg_downed = false;
        if ( !level.gg_victory && isDefined( self.gg_tier ) )
            gg_give_tier_weapon( self ); // re-equip the (possibly lowered) tier gun
    }
}

// reviver gets +1 progress on their own tier
function gg_revive_reward_watcher()
{
    self endon( "disconnect" );
    for ( ;; )
    {
        self waittill( "player_did_a_revive", revivee );
        if ( level.gg_victory || !isDefined( self.gg_tier ) )
            continue;
        tier = level.gg_ladder[ self.gg_tier ];
        if ( tier.cond == "knife" )
            continue; // no free wins
        IPrintLn( self.name + " ^2+1^7 revive bonus!" );
        gg_add_progress( self, 1 );
    }
}

// Neutralizes box / wallbuy / PaP: anything that isn't your ladder
// weapon is taken away and replaced within ~2 seconds.
// After a win, this loop becomes the victory-lap ammo fountain.
function gg_enforce_loop()
{
    self endon( "disconnect" );
    for ( ;; )
    {
        wait 2;
        if ( !isDefined( self.gg_tier ) || self.gg_downed )
            continue;

        if ( level.gg_victory )
        {
            w = self GetCurrentWeapon();
            if ( isDefined( w ) )
                self GiveMaxAmmo( w );
            continue;
        }

        tier = level.gg_ladder[ self.gg_tier ];
        if ( tier.weapon == "bowie_knife" )
        {
            primaries = self GetWeaponsListPrimaries();
            foreach ( pw in primaries )
                self zm_weapons::weapon_take( pw );
            if ( !self HasWeapon( GetWeapon( "bowie_knife" ) ) )
                gg_give_tier_weapon( self );
            continue;
        }

        primaries = self GetWeaponsListPrimaries();
        ok = primaries.size > 0;
        foreach ( pw in primaries )
        {
            if ( pw.name != tier.weapon )
            {
                ok = false;
                break;
            }
        }
        if ( !ok )
            gg_give_tier_weapon( self );
    }
}

// ---------------- HUD ----------------

function gg_hud_create( player )
{
    if ( isDefined( player.gg_hud ) )
        player.gg_hud destroy();
    if ( isDefined( player.gg_board ) )
        player.gg_board destroy();

    hud = NewClientHudElem( player );
    hud.alignX = "left";    hud.alignY = "top";
    hud.horzAlign = "left";  hud.vertAlign = "top";
    hud.x = 12;             hud.y = 130;
    hud.foreground = true;
    hud.fontScale = 1.4;
    hud.alpha = 0.9;
    hud.hidewheninmenu = true;
    player.gg_hud = hud;

    board = NewClientHudElem( player );
    board.alignX = "right";   board.alignY = "top";
    board.horzAlign = "right"; board.vertAlign = "top";
    board.x = -12;            board.y = 60;
    board.foreground = true;
    board.fontScale = 1.2;
    board.alpha = 0.85;
    board.hidewheninmenu = true;
    player.gg_board = board;

    gg_hud_update( player );
}

function gg_hud_update( player )
{
    if ( !isDefined( player.gg_hud ) )
        return;
    tier = level.gg_ladder[ player.gg_tier ];
    player.gg_hud setText( "TIER " + ( player.gg_tier + 1 ) + "/20\n" + tier.display + "\n" + gg_cond_label( tier.cond ) + ": " + player.gg_progress + "/" + tier.quota );
}

function gg_board_update()
{
    if ( !isDefined( level.players ) )
        return;
    foreach ( p in level.players )
    {
        if ( !isDefined( p ) || !isDefined( p.gg_board ) )
            continue;
        txt = "^3GUN GAME^7\n";
        foreach ( q in level.players )
        {
            if ( !isDefined( q ) || !isDefined( q.gg_tier ) )
                continue;
            marker = "";
            if ( isDefined( level.gg_victory_player ) && q == level.gg_victory_player )
                marker = " ^3(WINNER)^7";
            txt += q.name + ": " + ( q.gg_tier + 1 ) + "/20" + marker + "\n";
        }
        p.gg_board setText( txt );
    }
}
