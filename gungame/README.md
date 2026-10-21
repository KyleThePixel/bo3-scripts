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

## Install (t7-compiler — recommended)

1. Get t7-compiler (shiversoftdev's T7/BO3 GSC compiler + injector) from its
   GitHub releases page: https://github.com/shiversoftdev/t7-compiler
   (grab the installer under Releases).
2. Launch Black Ops 3 (BOIII launcher is fine) and sit in a **zombies
   pre-game lobby** — don't start the match yet.
3. In t7-compiler, compile `gungame.gsc` (if your compiler variant wants the
   entry file named `main.gsc`, just rename it — the `main()` function inside
   is what matters).
4. Inject the compiled script, then start the match. You should see
   "GUN GAME loaded" in the killfeed area.

Co-op: host a private lobby, have friends join, then start. They don't need
the script — everything runs host-side. Test in a private match first.

## Install (BOIII launcher scripts folder — experimental)

Some community clients auto-load loose `.gsc` files from a scripts folder
(Plutonium uses `%localappdata%\Plutonium\storage\t6\scripts\zm\`). If the
BOIII launcher has an equivalent folder, try dropping `gungame.gsc` in its
`scripts\zm\` equivalent and launching a match. **Unverified** — if it
doesn't pick it up, use the t7-compiler method above and tell me what the
launcher's folder layout looks like.

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
- I couldn't compile-check this in my environment — t7-compiler's compile
  step is the syntax check. If it throws an error, send me the exact message
  and line number.

## Files

- `gungame.gsc` — the whole mod, one file
- `PLAN.md` — the design doc
- `README.md` — this file
