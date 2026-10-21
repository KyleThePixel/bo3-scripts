# PAPGUM v1 — Pack-a-Punch GobbleGum for BO3 Zombies (ezz boiii)

Replaces the **Bullet Boost** GobbleGum's effect:

| Gun in your hands when you pop it | What happens |
|---|---|
| Normal gun | It's Pack-a-Punched on the spot — permanently, full ammo, random AAT included, just like the machine |
| Already Pack-a-Punched gun | Its Alternate Ammo Type is re-rolled — guaranteed to be a *different* AAT than the one it had |

The gum keeps Bullet Boost's name, icon, and **2 activations per gum** (script-only
mods can't change name/icon — those live in the game's assets). Every player in
the match gets the new effect, not just the host.

## Install / use

Per the official boiii docs (Ezz-lol/boiii-free, docs/gsc-scripting.md):
**boiii compiles and loads custom scripts itself** — no t7-compiler, no
injector needed.

1. Drop the **source** `papgum.gsc` (in `source/`) into **`custom_scripts`**
   — either `<game folder>\boiii\custom_scripts\` or
   `%LOCALAPPDATA%\boiii\data\custom_scripts\`. Top level of that folder
   is fine. Host the lobby as usual.
   (A pre-compiled copy is in `compiled/` — gsc-tool 1.6.1, verified by
   decompiling it back; the round-trip matches the source
   function-for-function. You don't need it for the custom_scripts route.)
2. Start the match. "PAP GUM loaded" prints when it's in.
3. Buy/equip **Bullet Boost** as usual and pop it with the gun you want
   upgraded in your hands.

## Behavior notes

- **Validation:** the gum refuses to pop (and isn't consumed) if you're downed,
  switching weapons, throwing a grenade, holding fists/equipment/a special
  weapon, holding a gun with no Pack-a-Punch version, or holding a
  Pack-a-Punched wonder weapon that can't take an AAT.
- **Ammo:** the upgraded gun comes back with full ammo, same as the machine.
- **Attachments/camo:** the swap goes through the same `weapon_give` path as
  the real Pack-a-Punch, so it behaves like a machine upgrade (stock upgraded
  variant, default attachment rules for the map).
- **Alt weapons** (underbarrel launchers etc.): the parent gun is upgraded,
  same as stock gums handle it.
- The patch re-applies itself automatically on every new map in the session —
  inject once per lobby session.

## Built from the stock scripts (verified, not guessed)

- `scripts/zm/_zm_bgb.gsc` — gums are invoked via
  `level.bgb[name].activation_func` / `.validation_func`; this mod swaps those
  two pointers on the `zm_bgb_bullet_boost` entry after registration.
- `scripts/zm/_zm_pack_a_punch.gsc` — the machine's own upgrade flow
  (`weapon_give` → `aat::acquire`) is what the upgrade branch mirrors.
- `scripts/shared/aat_shared.gsc` — `aat::acquire()` with no name picks a
  random AAT *excluding the current one*, which is what makes the re-roll a
  guaranteed change.
- `scripts/zm/_zm_weapons.gsc` — `is_weapon_upgraded`, `can_upgrade_weapon`,
  `get_upgrade_weapon`, `weapon_supports_aat` drive the branch decisions.

## Unverified — needs your playtest

Same honesty rules as the gun game: this was written against the real script
sources and is now **compiled and round-trip verified**, but it has not been
run in-game yet.

1. **In-game load** — boiii hasn't loaded this exact file yet; if your usual
   flow is t7-compiler, the included source compiles there too.
2. **Patch timing** — the watcher re-applies the override every 0.25s, so even
   if boiii rebuilds the bgb table per map it should stick; confirm by popping
   Bullet Boost in a second consecutive match without re-injecting.
3. **In-place swap feel** — `TakeWeapon` + `weapon_give` is the standard mod
   pattern; watch for a brief fists moment or wrong-slot weirdness with
   dual-wield guns and Mule Kick's third weapon.
4. **AAT-exempt upgraded guns** (some wonder weapons) — validation should
   block the pop entirely rather than eat the gum. Confirm it blocks instead
   of consuming.

## Playtest checklist

- [ ] Compiled file loads in boiii without a script error
- [ ] Pop with a base gun → comes back Pack-a-Punched, full ammo, AAT icon shows
- [ ] Pop again with the same (now PaP'd) gun → AAT changes to a different one
- [ ] Pop attempt while downed / holding equipment → gum NOT consumed
- [ ] Works for a non-host player in co-op
- [ ] Still works in a second match without re-injecting
