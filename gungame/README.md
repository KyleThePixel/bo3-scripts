# GUNGAME v1 — BO3 Zombies co-op gun game

Host-only script. Only the host needs it — friends just join your lobby.

## What it is

Every player climbs their own 20-weapon ladder. Each tier pairs a weapon with a
condition, so every tier plays differently:

| Tier | Weapon | Needed | Condition |
|------|--------|--------|-----------|
| 1 | MR6 | 1 | kills |
| 2 | Kuda | 1 | kills |
| 3 | RK5 | 2 | kills |
| 4 | KRM-262 | 2 | kills |
| 5 | Vesper | 2 | headshots |
| 6 | KN-44 | 3 | kills |
| 7 | Haymaker 12 | 3 | melee kills |
| 8 | M8A7 | 3 | headshots |
| 9 | Dingo | 4 | kills |
| 10 | Locus | 4 | headshots |
| 11 | HVK-30 | 4 | kills without taking damage |
| 12 | Argus | 5 | kills |
| 13 | BRM | 5 | 5 kills within 6 seconds |
| 14 | SVG-100 | 5 | headshots |
| 15 | ICR-1 | 6 | kills without taking damage |
| 16 | Gorgon | 6 | kills |
| 17 | Drakon | 6 | grenade kills |
| 18 | XR-2 | 7 | 7 kills within 6 seconds |
| 19 | XM-53 | 7 | kills |
| 20 | Bowie Knife | 1 | knife kill = WIN |

Rules:

- Only kills with your **current** ladder weapon count. Steal at will.
- **Downed = drop one tier.** Your current-tier progress is kept.
- **Reviving a teammate = +1 progress** on your own tier (except knife tier).
- Tier-up refills your ammo. Points, doors, and perks work normally.
- The mystery box, wallbuys, and Pack-a-Punch are neutralized: anything that
  isn't your ladder weapon gets taken away within ~2 seconds. Don't waste
  points on them. (PaP'ing your ladder gun gets reverted too.)
- First knife kill wins: banner, then unlimited-ammo victory lap for everyone.

## Install (ezz boiii — custom_scripts)

Boiii compiles and loads custom scripts itself — no injector needed.

1. Drop the **source** `gungame.gsc` into `custom_scripts`, in either
   location: `<game folder>\boiii\custom_scripts\` or
   `%LOCALAPPDATA%\boiii\data\custom_scripts\`. Top level is fine.
2. Start (or restart) boiii and start a match. "GUN GAME loaded" prints
   when it's in.

Important: the script's entry is an **autoexec** function — that's what
boiii's loader runs for custom scripts (it never calls `main()`).

Co-op: host a private lobby, have friends join, then start. They don't need
the script — everything runs host-side. Test in a private match first.

## Tweaking

It's one file. Open `gungame.gsc` and edit `gg_build_ladder()`:

- `gg_add_tier( "smg_standard", "Kuda", 1, "kills" );`
  = internal weapon name, HUD name, kills needed, condition.
- Conditions: `kills`, `headshot`, `melee`, `clean`, `frenzy`, `grenade`, `knife`.
- Weapon names are BO3's internal class names (`smg_standard` = Kuda,
  `ar_accurate` = ICR-1, etc.), verified against stock scripts and two
  community weapon-name lists. If a tier hands you the wrong gun, the name in
  your build differs — tell me which tier and I'll fix the mapping.

## Known limitations (v1)

- Only zombie kills count (dogs / special enemies use a different spawner).
- Trap / nuke kills with no attacker don't credit anyone.
- The Bowie Knife tier uses a raw `giveWeapon`. If the knife doesn't equip
  properly on your build, tell me and I'll switch the finale to stock-knife.
- Compile-checked with gsc-tool (T7) and round-trip decompiled — syntax is
  verified; in-game behavior still needs your playtest. If boiii's console
  shows a script error, send me the exact message and line number.
- Kill credit (v4+): kills are matched by **base weapon name**, so if
  your ladder gun gets Pack-a-Punched mid-tier (e.g. by the papgum mod)
  its kills still count while the enforce loop reverts the gun itself.
  Every player kill also prints one `GG death:` line to the host console
  (weapon seen, mod, tier weapon, condition) — if a tier ever sticks at
  0 again, that line shows exactly which value didn't match. (v3 briefly
  captured damage info via an actor-damage callback instead of reading
  the corpse fields; removed in v5 — a wrong `#using` path for it
  crashed boiii's script linker at map load, and the solo playtest
  proved the corpse fields work fine.)

## Files

- `gungame.gsc` — the whole mod, one file
- `PLAN.md` — the design doc
- `README.md` — this file
